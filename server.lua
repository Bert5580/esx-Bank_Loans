-- ESX Bank Loans - Server Side Script
local ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local playerLoans = {}

-- Debug Print Helper
local function DebugPrint(message, level)
    if Config.Debug then
        local timestamp = "[" .. math.floor(GetGameTimer() / 1000) .. "s]"
        local levels = { info = "[INFO]", warning = "[WARNING]", error = "[ERROR]" }
        local logLevel = levels[level] or "[INFO]"
        print(string.format("%s %s %s", timestamp, logLevel, message))
    end
end

-- Validate database tables before running
local function ValidateDatabase()
    MySQL.ready(function()
        MySQL.Async.fetchAll("SHOW TABLES LIKE 'player_loans'", {}, function(result)
            if #result == 0 then
                print("[ERROR] Table 'player_loans' does not exist. Creating table...")
                MySQL.Async.execute([[CREATE TABLE IF NOT EXISTS player_loans (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    identifier VARCHAR(50) NOT NULL,
                    loan_amount DOUBLE NOT NULL,
                    interest_rate DOUBLE NOT NULL DEFAULT 0.05,
                    total_debt DOUBLE NOT NULL,
                    amount_paid DOUBLE DEFAULT 0,
                    date_taken DATETIME DEFAULT CURRENT_TIMESTAMP,
                    last_payment DATETIME DEFAULT NULL,
                    FOREIGN KEY (identifier) REFERENCES users(identifier) ON DELETE CASCADE
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;]])
            else
                print("[INFO] Table 'player_loans' verified.")
            end
        end)

        MySQL.Async.fetchAll("SHOW COLUMNS FROM users LIKE 'credit_score'", {}, function(result)
            if #result == 0 then
                print("[ERROR] Column 'credit_score' missing. Adding column...")
                MySQL.Async.execute("ALTER TABLE users ADD COLUMN credit_score INT DEFAULT 100;")
            end
        end)
    end)
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        ValidateDatabase()
    end
end)

-- Fetch Credit & Loans
RegisterNetEvent('bankloan:getCreditAndLoans')
AddEventHandler('bankloan:getCreditAndLoans', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    MySQL.Async.fetchScalar('SELECT IFNULL(credit, 0) FROM users WHERE identifier = ?', { identifier }, function(credit)
        MySQL.Async.fetchAll('SELECT * FROM player_loans WHERE identifier = ?', { identifier }, function(loans)
            TriggerClientEvent('bankloan:openLoanMenu', src, credit, loans)
            DebugPrint(string.format("Sending loan menu data to Player ID %s with Credit: %d", src, credit))
        end)
    end)
end)

-- New Feature: Loan Balance Notification
RegisterNetEvent('bankloan:notifyLoanBalance')
AddEventHandler('bankloan:notifyLoanBalance', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    MySQL.Async.fetchScalar("SELECT SUM(total_debt - amount_paid) FROM player_loans WHERE identifier = ?", { identifier }, function(debt)
        if debt and debt > 0 then
            TriggerClientEvent('esx:showNotification', src, string.format("Your remaining loan balance is: $%.2f", debt))
        else
            TriggerClientEvent('esx:showNotification', src, "You have no outstanding loans.")
        end
    end)
end)

-- New Feature: Auto Loan Repayment on Paycheck
RegisterNetEvent('bankloan:autoRepayLoan')
AddEventHandler('bankloan:autoRepayLoan', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    local paycheckAmount = xPlayer.getSalary() or 0
    local repaymentAmount = paycheckAmount * Config.PaybackPercentage

    MySQL.Async.fetchScalar("SELECT SUM(total_debt - amount_paid) FROM player_loans WHERE identifier = ?", { identifier }, function(debt)
        if debt and debt > 0 then
            local amountToRepay = math.min(repaymentAmount, debt)
            MySQL.Async.execute("UPDATE player_loans SET amount_paid = amount_paid + ? WHERE identifier = ?", { amountToRepay, identifier })
            TriggerClientEvent('esx:showNotification', src, string.format("$%.2f has been deducted from your paycheck for loan repayment.", amountToRepay))
        end
    end)
end)

local CurrentVersion = "Ev1.0.6" -- Current ESX version
local RepoURL = "https://api.github.com/repos/Bert5580/Esx-Bank_Loans/releases/latest"

-- Function: Check for updates from GitHub
local function CheckForUpdates()
    PerformHttpRequest(RepoURL, function(statusCode, response)
        if statusCode == 200 and response then
            local LatestVersion = response:match('"tag_name":"(.-)"')
            if LatestVersion and LatestVersion ~= CurrentVersion then
                print(string.format(
                    "[Bank Loans]: \27[33mA new version is available! (Current: %s, Latest: %s)\27[0m",
                    CurrentVersion, LatestVersion
                ))
                print(string.format(
                    "[Bank Loans]: Download it at: \27[31mhttps://github.com/Bert5580/Esx-Bank_Loans/releases/tag/%s\27[0m",
                    LatestVersion
                ))
            else
                print("[Bank Loans]: You are using the latest version.")
            end
        else
            print("[Bank Loans]: Failed to check for updates. HTTP Error:", statusCode)
        end
    end, "GET", "", { ["User-Agent"] = "Mozilla/5.0" })
end

-- Run update check on server start
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        CheckForUpdates()
    end
end)

-- New Feature: Grant Loan
RegisterNetEvent('bankloan:giveLoan')
AddEventHandler('bankloan:giveLoan', function(amount, interestRate)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    local identifier = xPlayer.getIdentifier()
    local totalDebt = amount * (1 + interestRate)
    MySQL.Async.insert('INSERT INTO player_loans (identifier, loan_amount, interest_rate, total_debt, amount_paid) VALUES (?, ?, ?, ?, ?)',
        { identifier, amount, interestRate, totalDebt, 0 }, function(insertId)
            if insertId then
                xPlayer.addAccountMoney('bank', amount)
                TriggerClientEvent('esx:showNotification', src, "Loan granted successfully!")
            else
                TriggerClientEvent('esx:showNotification', src, "Loan request failed.")
            end
        end)
end)

-- New Feature: Pay Loan
RegisterNetEvent('bankloan:payLoan')
AddEventHandler('bankloan:payLoan', function(paymentAmount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    local identifier = xPlayer.getIdentifier()
    local bankBalance = xPlayer.getAccount('bank').money
    if bankBalance < paymentAmount then
        TriggerClientEvent('esx:showNotification', src, "Insufficient funds.")
        return
    end
    
    xPlayer.removeAccountMoney('bank', paymentAmount)
    MySQL.Async.execute("UPDATE player_loans SET amount_paid = amount_paid + ? WHERE identifier = ?", { paymentAmount, identifier })
    TriggerClientEvent('esx:showNotification', src, "Loan payment successful.")
end)
