local QBCore = exports['qb-core']:GetCoreObject()

-- DB Adapter
local DB = {}
local USING_OX = GetResourceState('oxmysql') == 'started'

local function logDebug(...)
    if Config.Debug then
        print('[BankLoans]', ...)
    end
end

-- Detect storage
local storage = string.lower(Config.Storage or 'auto')
if storage == 'auto' then
    storage = USING_OX and 'oxmysql' or 'mysql-async'
end
logDebug('Storage backend:', storage)

-- Helpers to execute queries safely
if storage == 'oxmysql' then
    DB.fetchAll = function(query, params, cb) exports.oxmysql:execute(query, params or {}, cb) end
    DB.fetchScalar = function(query, params, cb) exports.oxmysql:scalar(query, params or {}, cb) end
    DB.execute   = function(query, params, cb) exports.oxmysql:execute(query, params or {}, function(affected) if cb then cb(affected) end end) end
else
    DB.fetchAll = function(query, params, cb) MySQL.Async.fetchAll(query, params or {}, cb) end
    DB.fetchScalar = function(query, params, cb) MySQL.Async.fetchScalar(query, params or {}, cb) end
    DB.execute   = function(query, params, cb) MySQL.Async.execute(query, params or {}, cb) end
end

-- SQL TABLES
local T_LOANS   = Config.TableLoans
local T_LOGS    = Config.TableLogs
local T_PLAYERS = Config.TablePlayers

-- Ensure tables exist (idempotent)
CreateThread(function()
    DB.execute(([[
        CREATE TABLE IF NOT EXISTS `%s` (
          `id` INT NOT NULL AUTO_INCREMENT,
          `citizenid` VARCHAR(50) NOT NULL,
          `principal` INT NOT NULL DEFAULT 0,
          `interest_rate` DECIMAL(5,4) NOT NULL DEFAULT 0.0300,
          `total_debt` INT NOT NULL DEFAULT 0,
          `amount_paid` INT NOT NULL DEFAULT 0,
          `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `idx_citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(T_LOANS))

    DB.execute(([[
        CREATE TABLE IF NOT EXISTS `%s` (
          `id` INT NOT NULL AUTO_INCREMENT,
          `citizenid` VARCHAR(50) NOT NULL,
          `action` VARCHAR(32) NOT NULL,
          `amount` INT DEFAULT 0,
          `meta` TEXT,
          `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
          PRIMARY KEY (`id`),
          KEY `idx_citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(T_LOGS))
end)

local function getCitizenId(src)
    local P = QBCore.Functions.GetPlayer(src)
    return P and P.PlayerData and P.PlayerData.citizenid or nil
end

local function getCredit(citizenid, cb)
    DB.fetchScalar("SELECT JSON_EXTRACT(money, '$.credit') FROM "..T_PLAYERS.." WHERE citizenid = ?", { citizenid }, function(val)
        local credit = tonumber(val) or 600
        if not credit or credit <= 0 then credit = 600 end
        cb(credit)
    end)
end

local function setCredit(citizenid, credit, reason)
    DB.execute("UPDATE "..T_PLAYERS.." SET money = JSON_SET(COALESCE(money, JSON_OBJECT()), '$.credit', ?) WHERE citizenid = ?", { credit, citizenid })
    DB.execute("INSERT INTO "..T_LOGS.." (citizenid, action, amount, meta) VALUES (?, 'credit_set', ?, ?)", { citizenid, credit, reason or '' })
end

local function getLoans(citizenid, cb)
    DB.fetchAll("SELECT * FROM "..T_LOANS.." WHERE citizenid = ? ORDER BY id DESC", { citizenid }, function(rows)
        cb(rows or {})
    end)
end

local function calcInterestRate(credit)
    local rate = Config.BaseInterestRate
    if credit > Config.CreditPivot then
        local steps = math.floor((credit - Config.CreditPivot) / Config.CreditRateDiscountPer)
        rate = math.max(0.0, rate - (steps * Config.CreditRateDiscountStep))
    elseif credit < Config.CreditPivot then
        local steps = math.ceil((Config.CreditPivot - credit) / Config.CreditRateDiscountPer)
        rate = rate + (steps * (Config.CreditRateDiscountStep * 0.5))
    end
    return tonumber(string.format('%.4f', rate))
end

-- Get Loans for client menu
QBCore.Functions.CreateCallback('bankloan:server:GetLoans', function(source, cb)
    local citizenid = getCitizenId(source)
    if not citizenid then cb({}); return end
    getLoans(citizenid, function(rows) cb(rows) end)
end)

-- Admin grant command
QBCore.Commands.Add('grant_loan', Lang:t('cmd.grant'), {{name='id', help='Server ID'}, {name='amount', help='Amount'}, {name='rate', help='Interest rate (e.g., 0.03)'}}, false, function(source, args)
    if not IsPlayerAceAllowed(source, Config.AdminAce) then
        TriggerClientEvent('QBCore:Notify', source, Lang:t('notify.admin_only'), 'error')
        return
    end
    local target = tonumber(args[1] or '0') or 0
    local amount = math.floor(tonumber(args[2] or '0') or 0)
    local rate   = tonumber(args[3] or '') or Config.BaseInterestRate
    if amount <= 0 or amount > Config.MaxLoanAmount then
        TriggerClientEvent('QBCore:Notify', source, Lang:t('notify.amount_invalid'), 'error'); return
    end
    if rate <= 0 or rate > 0.5 then
        TriggerClientEvent('QBCore:Notify', source, Lang:t('notify.interest_invalid'), 'error'); return
    end
    local citizenid = getCitizenId(target)
    if not citizenid then
        TriggerClientEvent('QBCore:Notify', source, 'Invalid target.', 'error'); return
    end

    DB.fetchScalar("SELECT COUNT(*) FROM "..T_LOANS.." WHERE citizenid = ? AND (total_debt - amount_paid) > 0", { citizenid }, function(count)
        if (count or 0) >= Config.MaxActiveLoansPerUser then
            TriggerClientEvent('QBCore:Notify', source, Lang:t('notify.too_many_loans'), 'error')
            return
        end
        local total = amount + math.floor(amount * rate)
        DB.execute("INSERT INTO "..T_LOANS.." (citizenid, principal, interest_rate, total_debt, amount_paid) VALUES (?, ?, ?, ?, 0)",
            { citizenid, amount, rate, total }, function()
                DB.execute("INSERT INTO "..T_LOGS.." (citizenid, action, amount, meta) VALUES (?, 'grant', ?, ?)", { citizenid, amount, ('rate=%s'):format(rate) })
                local P = QBCore.Functions.GetPlayer(target)
                if P then
                    P.Functions.AddMoney('bank', amount, 'loan-granted')
                    TriggerClientEvent('QBCore:Notify', target, Lang:t('notify.loan_created', { amount = amount, apr = math.floor(rate*100) }), 'success')
                end
        end)
    end)
end)

-- Public request (validates credit/limits)
RegisterNetEvent('bankloan:RequestLoan', function(amount)
    local src = source
    local citizenid = getCitizenId(src)
    local amt = math.floor(tonumber(amount or 0))
    if not citizenid or amt <= 0 or amt > Config.MaxLoanAmount then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.amount_invalid'), 'error'); return
    end
    DB.fetchScalar("SELECT COUNT(*) FROM "..T_LOANS.." WHERE citizenid = ? AND (total_debt - amount_paid) > 0", { citizenid }, function(count)
        if (count or 0) >= Config.MaxActiveLoansPerUser then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.too_many_loans'), 'error'); return
        end
        getCredit(citizenid, function(credit)
            if credit < Config.MinCreditToBorrow then
                TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.not_enough_credit', {min = Config.MinCreditToBorrow}), 'error'); return
            end
            local rate = calcInterestRate(credit)
            local total = amt + math.floor(amt * rate)
            DB.execute("INSERT INTO "..T_LOANS.." (citizenid, principal, interest_rate, total_debt, amount_paid) VALUES (?, ?, ?, ?, 0)",
                { citizenid, amt, rate, total }, function()
                    DB.execute("INSERT INTO "..T_LOGS.." (citizenid, action, amount, meta) VALUES (?, 'grant', ?, ?)", { citizenid, amt, ('rate=%s'):format(rate) })
                    local P = QBCore.Functions.GetPlayer(src)
                    if P then P.Functions.AddMoney('bank', amt, 'loan-granted') end
                    TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.loan_created', { amount = amt, apr = math.floor(rate*100) }), 'success')
            end)
        end)
    end)
end)

-- Pay loan
RegisterNetEvent('bankloan:PayLoan', function(amount)
    local src = source
    local citizenid = getCitizenId(src)
    local amt = math.floor(tonumber(amount or 0))
    if not citizenid or amt <= 0 or amt < Config.MinManualPayment then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.amount_invalid'), 'error'); return
    end
    local P = QBCore.Functions.GetPlayer(src)
    if not P or (P.Functions.GetMoney('bank') < amt) then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.not_enough_cash'), 'error'); return
    end

    DB.fetchAll("SELECT * FROM "..T_LOANS.." WHERE citizenid = ? AND (total_debt - amount_paid) > 0 ORDER BY id ASC LIMIT 1", { citizenid }, function(rows)
        local row = rows and rows[1]
        if not row then
            TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.no_debt'), 'primary'); return
        end
        local remain = row.total_debt - row.amount_paid
        local pay = math.min(amt, remain)

        P.Functions.RemoveMoney('bank', pay, 'loan-payment')

        DB.execute("UPDATE "..T_LOANS.." SET amount_paid = amount_paid + ? WHERE id = ?", { pay, row.id }, function()
            DB.execute("INSERT INTO "..T_LOGS.." (citizenid, action, amount, meta) VALUES (?, 'payment', ?, ?)", { citizenid, pay, ('loan_id=%s'):format(row.id) })

            local newRemain = remain - pay
            if newRemain <= 0 then
                getCredit(citizenid, function(cur)
                    setCredit(citizenid, math.min(1000, cur + Config.Credit.OnFullPay), 'full_pay')
                end)
            else
                getCredit(citizenid, function(cur)
                    setCredit(citizenid, math.min(1000, cur + Config.Credit.OnPartialPay), 'partial_pay')
                end)
            end

            TriggerClientEvent('QBCore:Notify', src, Lang:t('notify.payment_ok', { amount = pay, remain = newRemain }), 'success')
        end)
    end)
end)

-- Auto deduction example hook
RegisterNetEvent('bankloan:Server:AutoDeductFromPaycheck', function(payAmount)
    if not Config.EnableAutoDeduction then return end
    local src = source
    local citizenid = getCitizenId(src)
    if not citizenid then return end
    local deduction = math.floor((tonumber(payAmount or 0)) * Config.AutoDeductionPercent)
    if deduction <= 0 then return end
    TriggerEvent('bankloan:PayLoan', deduction)
end)
