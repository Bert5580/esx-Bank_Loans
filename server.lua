-- ESX Bank Loans - Server (mysql-async)
-- Ev1.1.1 — fixes: Lua 1-based indexing, FK-safe DDL, safe index creation, nil-safety

local ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local function DebugPrint(msg, level)
    if not Config or not Config.Debug then return end
    local lv = ({ info="[INFO]", warning="[WARNING]", error="[ERROR]" })[level or "info"] or "[INFO]"
    print(("%s %s"):format(lv, tostring(msg)))
end

local function _U(key, ...)
    if Locales and Locales['en'] and Locales['en'][key] then
        return string.format(Locales['en'][key], ...)
    end
    return key
end

-- Utilities
local function getXPlayer(src)
    if not src then return nil end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        DebugPrint(("getXPlayer: nil for source %s"):format(tostring(src)), "warning")
    end
    return xPlayer
end

local function getIdentifier(xPlayer)
    if not xPlayer then return nil end
    return xPlayer.identifier or (xPlayer.getIdentifier and xPlayer.getIdentifier()) or nil
end

-- Schema guards
local function ensureUsersTable()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `users` (
            `identifier` varchar(60) NOT NULL,
            `accounts` longtext DEFAULT NULL,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function() end)

    -- Only alter if NOT varchar(60), and do it FK-safe
    MySQL.Async.fetchAll("SHOW COLUMNS FROM `users` LIKE 'identifier'", {}, function(cols)
        local t = cols and cols[1] and cols[1].Type and cols[1].Type:lower() or ""
        if t:find("varchar(60)") then
            DebugPrint("users.identifier OK (varchar(60))", "info")
            return
        end

        DebugPrint("users.identifier alter -> varchar(60) with FK safety", "warning")
        MySQL.Async.fetchAll([[
            SELECT CONSTRAINT_NAME, TABLE_NAME
            FROM information_schema.KEY_COLUMN_USAGE
            WHERE TABLE_SCHEMA = DATABASE()
              AND REFERENCED_TABLE_NAME = 'users'
              AND REFERENCED_COLUMN_NAME = 'identifier'
        ]], {}, function(refs)
            local function recreateKnownFKs()
                MySQL.Async.execute([[
                    ALTER TABLE `loan_history`
                    ADD CONSTRAINT `fk_loan_history_users`
                    FOREIGN KEY (`identifier`) REFERENCES `users`(`identifier`)
                    ON UPDATE CASCADE ON DELETE CASCADE;
                ]])
                MySQL.Async.execute([[
                    ALTER TABLE `player_loans`
                    ADD CONSTRAINT `fk_player_loans_users`
                    FOREIGN KEY (`identifier`) REFERENCES `users`(`identifier`)
                    ON UPDATE CASCADE ON DELETE CASCADE;
                ]])
            end

            local function alterUsers()
                MySQL.Async.execute([[
                    ALTER TABLE `users`
                    MODIFY `identifier` VARCHAR(60)
                    CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;
                ]], {}, function()
                    recreateKnownFKs()
                end)
            end

            if refs and #refs > 0 then
                local dropped = 0
                for _, r in ipairs(refs) do
                    if r.CONSTRAINT_NAME and r.TABLE_NAME then
                        MySQL.Async.execute(("ALTER TABLE `%s` DROP FOREIGN KEY `%s`;"):format(r.TABLE_NAME, r.CONSTRAINT_NAME), {}, function()
                            dropped = dropped + 1
                            if dropped == #refs then alterUsers() end
                        end)
                    else
                        dropped = dropped + 1
                        if dropped == #refs then alterUsers() end
                    end
                end
            else
                alterUsers()
            end
        end)
    end)

    -- Index on users.identifier (safe)
    MySQL.Async.fetchAll("SHOW INDEX FROM `users` WHERE Key_name = 'idx_identifier'", {}, function(idx)
        if #idx == 0 then
            DebugPrint("Adding users.idx_identifier", "info")
            MySQL.Async.execute("ALTER TABLE `users` ADD INDEX `idx_identifier` (`identifier`);")
        end
    end)
end

local function ensureLoanTable()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `player_loans` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(60) NOT NULL,
            `loan_amount` DECIMAL(12,2) NOT NULL,
            `interest_rate` DECIMAL(5,4) NOT NULL DEFAULT 0.0500,
            `total_debt` DECIMAL(12,2) NOT NULL,
            `amount_paid` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
            `date_taken` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `last_payment` DATETIME DEFAULT NULL,
            `status` ENUM('ACTIVE','PAID','DEFAULTED') NOT NULL DEFAULT 'ACTIVE'
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function()
        DebugPrint("Table `player_loans` verified/created.", "info")

        -- Correct types (Lua uses 1-based indices)
        MySQL.Async.fetchAll("SHOW COLUMNS FROM `player_loans` LIKE 'identifier'", {}, function(cols)
            if #cols > 0 and cols[1].Type and not cols[1].Type:lower():find("varchar(60)") then
                DebugPrint("Altering player_loans.identifier -> VARCHAR(60)", "warning")
                MySQL.Async.execute("ALTER TABLE `player_loans` MODIFY `identifier` VARCHAR(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL;")
            end
        end)

        local function ensureDec12(col)
            MySQL.Async.fetchAll("SHOW COLUMNS FROM `player_loans` LIKE @c", {["@c"]=col}, function(c)
                if #c > 0 and c[1].Type and not c[1].Type:lower():find("decimal(12,2)") then
                    DebugPrint(("Altering player_loans.%s -> DECIMAL(12,2)"):format(col), "warning")
                    MySQL.Async.execute(("ALTER TABLE `player_loans` MODIFY `%s` DECIMAL(12,2) NOT NULL;"):format(col))
                end
            end)
        end
        ensureDec12("loan_amount")
        ensureDec12("total_debt")
        ensureDec12("amount_paid")

        -- Ensure status index
        MySQL.Async.fetchAll("SHOW INDEX FROM `player_loans` WHERE Key_name = 'idx_loans_status'", {}, function(idx)
            if #idx == 0 then
                MySQL.Async.execute("CREATE INDEX `idx_loans_status` ON `player_loans` (`status`);")
            end
        end)
    end)
end

CreateThread(function()
    ensureUsersTable()
    ensureLoanTable()
end)

-- Bank JSON helpers (users.accounts)
local function getBankBalance(identifier, cb)
    if not identifier then cb(0) return end
    MySQL.Async.fetchAll("SELECT `accounts` FROM `users` WHERE `identifier`=@id LIMIT 1", {["@id"]=identifier}, function(rows)
        if rows and rows[1] and rows[1].accounts then
            local ok, decoded = pcall(json.decode, rows[1].accounts)
            if ok and decoded and decoded.bank then
                cb(tonumber(decoded.bank) or 0); return
            end
        end
        cb(0)
    end)
end

local function setBankBalance(identifier, newBal, cb)
    if not identifier then if cb then cb(false) end return end
    MySQL.Async.fetchAll("SELECT `accounts` FROM `users` WHERE `identifier`=@id LIMIT 1", {["@id"]=identifier}, function(rows)
        local accounts = {}
        if rows and rows[1] and rows[1].accounts then
            local ok, decoded = pcall(json.decode, rows[1].accounts)
            if ok and type(decoded) == "table" then accounts = decoded end
        end
        accounts.bank = tonumber(newBal) or 0
        MySQL.Async.execute("UPDATE `users` SET `accounts`=@a WHERE `identifier`=@id", {
            ["@a"] = json.encode(accounts),
            ["@id"] = identifier
        }, function(affected)
            if cb then cb(affected and affected > 0) end
        end)
    end)
end

-- Loan logic
local function getActiveLoan(identifier, cb)
    MySQL.Async.fetchAll("SELECT * FROM `player_loans` WHERE `identifier`=@id AND `status`='ACTIVE' LIMIT 1",
    {["@id"]=identifier}, function(rows)
        cb(rows and rows[1] or nil)
    end)
end

local function createLoan(identifier, amount, interest, cb)
    local principal = math.floor((tonumber(amount) or 0) * 100 + 0.5)/100
    if principal <= 0 then if cb then cb(false) end return end
    local rate = tonumber(interest) or Config.DefaultInterest
    local debt = math.floor((principal * (1.0 + rate)) * 100 + 0.5)/100

    MySQL.Async.execute([[
        INSERT INTO `player_loans`
        (`identifier`, `loan_amount`, `interest_rate`, `total_debt`, `amount_paid`, `date_taken`, `last_payment`, `status`)
        VALUES (@id, @amt, @rate, @debt, 0.00, NOW(), NULL, 'ACTIVE')
    ]], {["@id"]=identifier, ["@amt"]=principal, ["@rate"]=rate, ["@debt"]=debt},
    function(changed)
        if cb then cb(changed and changed > 0) end
    end)
end

local function payLoan(identifier, amount, cb)
    local pay = math.max(0, tonumber(amount) or 0)
    if pay <= 0 then if cb then cb(false, "invalid_amount") end return end

    getActiveLoan(identifier, function(loan)
        if not loan then if cb then cb(false, "no_active_loan") end return end
        local newPaid = (tonumber(loan.amount_paid) or 0) + pay
        local remaining = math.max(0, (tonumber(loan.total_debt) or 0) - newPaid)
        local newStatus = remaining <= 0.001 and "PAID" or "ACTIVE"

        MySQL.Async.execute([[
            UPDATE `player_loans`
            SET `amount_paid`=@paid, `last_payment`=NOW(), `status`=@status
            WHERE `id`=@id
        ]], {["@paid"]=newPaid, ["@status"]=newStatus, ["@id"]=loan.id},
        function(changed)
            if cb then cb(changed and changed > 0, newStatus, remaining) end
        end)
    end)
end

-- Events
RegisterNetEvent("esx_bankloans:requestLoan", function(amount)
    local src = source
    local xPlayer = getXPlayer(src); if not xPlayer then return end
    local identifier = getIdentifier(xPlayer); if not identifier then return end

    local amt = tonumber(amount) or 0
    if amt <= 0 then TriggerClientEvent('esx:showNotification', src, _U('invalid_loan_amount')); return end

    getActiveLoan(identifier, function(loan)
        if loan then
            TriggerClientEvent('esx:showNotification', src, _U('already_has_loan')); return
        end
        createLoan(identifier, amt, Config.DefaultInterest, function(ok)
            if not ok then
                TriggerClientEvent('esx:showNotification', src, _U('loan_create_failed')); return
            end
            getBankBalance(identifier, function(bal)
                setBankBalance(identifier, (bal or 0) + amt, function(updated)
                    if updated then
                        TriggerClientEvent('esx:showNotification', src, _U('loan_granted', Config.CurrencySymbol, ESX.Math.GroupDigits(amt)))
                    else
                        TriggerClientEvent('esx:showNotification', src, _U('loan_granted_but_bank_update_failed'))
                    end
                end)
            end)
        end)
    end)
end)

RegisterNetEvent("esx_bankloans:repayLoan", function(amount)
    local src = source
    local xPlayer = getXPlayer(src); if not xPlayer then return end
    local identifier = getIdentifier(xPlayer); if not identifier then return end

    local amt = tonumber(amount) or 0
    if amt <= 0 then TriggerClientEvent('esx:showNotification', src, _U('invalid_repayment_amount')); return end

    getActiveLoan(identifier, function(loan)
        if not loan then
            TriggerClientEvent('esx:showNotification', src, _U('no_active_loan')); return
        end
        getBankBalance(identifier, function(bal)
            if (bal or 0) < amt then
                TriggerClientEvent('esx:showNotification', src, _U('insufficient_funds')); return
            end
            payLoan(identifier, amt, function(ok, status, remaining)
                if not ok then
                    TriggerClientEvent('esx:showNotification', src, _U('repayment_failed')); return
                end
                setBankBalance(identifier, (bal or 0) - amt, function(_)
                    if status == "PAID" then
                        TriggerClientEvent('esx:showNotification', src, _U('loan_fully_paid'))
                    else
                        TriggerClientEvent('esx:showNotification', src, _U('payment_success_remaining', Config.CurrencySymbol, ESX.Math.GroupDigits(remaining or 0)))
                    end
                end)
            end)
        end)
    end)
end)

-- Callback for client status menu
ESX.RegisterServerCallback("esx_bankloans:getStatus", function(src, cb)
    local xPlayer = getXPlayer(src); if not xPlayer then cb(nil) return end
    local identifier = getIdentifier(xPlayer); if not identifier then cb(nil) return end
    getActiveLoan(identifier, function(loan) cb(loan) end)
end)
