-- ESX Bank Loans - Client Side Script
local ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Debug Print Helper
local function DebugPrint(message)
    if Config.Debug then
        print(string.format("[Debug]: %s", message))
    end
end

-- Fetch Credit & Loans
RegisterNetEvent('bankloan:getCreditAndLoans')
AddEventHandler('bankloan:getCreditAndLoans', function()
    TriggerServerEvent('bankloan:fetchCreditAndLoans')
end)

-- Open Loan Menu
RegisterNetEvent('bankloan:openLoanMenu')
AddEventHandler('bankloan:openLoanMenu', function(credit, loans)
    local elements = {}
    
    for _, loan in ipairs(Config.LoanOptions) do
        if credit >= (loan.requiredCredit or 0) then
            table.insert(elements, {label = string.format("%s%s (Interest: %s%%)", Config.CurrencySymbol, loan.amount, loan.interestRate * 100), value = loan})
        else
            table.insert(elements, {label = string.format("%s%s (Interest: %s%%) - Insufficient Credit", Config.CurrencySymbol, loan.amount, loan.interestRate * 100), disabled = true})
        end
    end
    
    table.insert(elements, {label = "Close Menu", value = nil})
    
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'loan_menu', {
        title = "Loan Options",
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        local loan = data.current.value
        if loan then
            TriggerServerEvent('bankloan:giveLoan', loan.amount, loan.interestRate)
            ESX.ShowNotification("Your loan request has been sent.")
        end
    end, function(data, menu)
        menu.close()
    end)
end)

-- Pay Loan Command
RegisterCommand('pay_loan', function(source, args)
    local amount = tonumber(args[1])
    if amount and amount > 0 then
        TriggerServerEvent('bankloan:payLoan', amount)
    else
        ESX.ShowNotification("Invalid payment amount.")
    end
end, false)

-- Check Debt Command
RegisterCommand('check_debit', function()
    TriggerServerEvent('bankloan:checkDebt')
end, false)

-- Display remaining debt
RegisterNetEvent('bankloan:showDebit')
AddEventHandler('bankloan:showDebit', function(debt)
    if debt > 0 then
        ESX.ShowNotification(string.format("Your remaining debt is %s%s.", Config.CurrencySymbol, debt))
    else
        ESX.ShowNotification("You have no remaining debt.")
    end
end)

-- Notify Loan Balance
RegisterNetEvent('bankloan:notifyLoanBalance')
AddEventHandler('bankloan:notifyLoanBalance', function()
    TriggerServerEvent('bankloan:fetchLoanBalance')
end)

-- Display Debt Notification
RegisterNetEvent('bankloan:displayDebitNotification')
AddEventHandler('bankloan:displayDebitNotification', function(totalDebt, paidDebt)
    local remainingDebt = totalDebt - paidDebt
    if remainingDebt > 0 then
        ESX.ShowNotification(string.format("You have %s%s of %s%s left to pay on your loan.", Config.CurrencySymbol, remainingDebt, Config.CurrencySymbol, totalDebt))
    else
        ESX.ShowNotification("Congratulations! You have fully repaid your loan.")
    end
end)

DebugPrint("Client-side loan script loaded successfully.")
