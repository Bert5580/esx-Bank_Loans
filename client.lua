-- ESX Bank Loans - Client
local ESX = nil
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end
end)

local _U = function(key, ...)
    if Locales and Locales['en'] and Locales['en'][key] then
        return string.format(Locales['en'][key], ...)
    end
    return key
end

local function DebugPrint(msg)
    if Config.Debug then
        print(("[Loans/Client] %s"):format(tostring(msg)))
    end
end

-- Blips
local function AddLoanBlips()
    if not Config.EnableBlips then return end
    for _, coords in ipairs(Config.LoanLocations) do
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, Config.BlipSprite)
        SetBlipColour(blip, Config.BlipColor)
        SetBlipScale(blip, Config.BlipScale + 0.0)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.BlipName)
        EndTextCommandSetBlipName(blip)
    end
end

-- NPCs
local function SpawnLoanNPCs()
    if not Config.EnableNPCs then return end
    local model = Config.NPCModel
    RequestModel(model)
    while not HasModelLoaded(model) do Citizen.Wait(0) end

    for _, loc in ipairs(Config.NPCSpawnLocations) do
        local ped = CreatePed(4, model, loc.x, loc.y, loc.z - 1.0, loc.w, false, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)
        if Config.NPCScenario and Config.NPCScenario ~= "" then
            TaskStartScenarioInPlace(ped, Config.NPCScenario, 0, true)
        end
    end

    SetModelAsNoLongerNeeded(model)
end

-- 3D Help text
local function HelpText(msg)
    SetTextComponentFormat('STRING')
    AddTextComponentString(msg)
    DisplayHelpTextFromStringLabel(0, false, true, -1)
end

-- ESX menu
local function OpenLoanMenu()
    local elements = {
        {label = _U('take_loan'), value = 'take'},
        {label = _U('repay_loan'), value = 'repay'},
        {label = _U('check_status'), value = 'status'},
        {label = _U('close'), value = 'close'}
    }

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'loan_menu', {
        title = _U('loan_menu'),
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        if data.current.value == 'take' then
            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'loan_amount', {
                title = _U('enter_amount')
            }, function(d, m)
                local amount = tonumber(d.value or 0)
                m.close()
                if not amount or amount <= 0 then
                    ESX.ShowNotification(_U('invalid_loan_amount'))
                    return
                end
                TriggerServerEvent('esx_bankloans:requestLoan', amount)
            end, function(d, m) m.close() end)

        elseif data.current.value == 'repay' then
            ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'repay_amount', {
                title = _U('enter_amount')
            }, function(d, m)
                local amount = tonumber(d.value or 0)
                m.close()
                if not amount or amount <= 0 then
                    ESX.ShowNotification(_U('invalid_repayment_amount'))
                    return
                end
                TriggerServerEvent('esx_bankloans:repayLoan', amount)
            end, function(d, m) m.close() end)

        elseif data.current.value == 'status' then
            ESX.TriggerServerCallback('esx_bankloans:getStatus', function(loan)
                if not loan then
                    ESX.ShowNotification(_U('status_none'))
                    return
                end
                local p  = tonumber(loan.loan_amount) or 0
                local ir = (tonumber(loan.interest_rate) or 0) * 100.0
                local td = tonumber(loan.total_debt) or 0
                local pd = tonumber(loan.amount_paid) or 0
                local rm = math.max(0, td - pd)

                ESX.ShowNotification(_U('status_active',
                    Config.CurrencySymbol, ESX.Math.GroupDigits(p),
                    string.format("%.2f", ir),
                    Config.CurrencySymbol, ESX.Math.GroupDigits(td),
                    Config.CurrencySymbol, ESX.Math.GroupDigits(pd),
                    Config.CurrencySymbol, ESX.Math.GroupDigits(rm)
                ))
            end)

        else
            menu.close()
        end
    end, function(_, menu) menu.close() end)
end

-- Proximity loop
CreateThread(function()
    AddLoanBlips()
    SpawnLoanNPCs()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)
        for _, coords in ipairs(Config.LoanLocations) do
            if #(pcoords - coords) < Config.MarkerDrawDistance then
                sleep = 0
                if #(pcoords - coords) <= Config.InteractDistance then
                    HelpText(_U('open_menu'))
                    if IsControlJustReleased(0, 38) then -- E
                        OpenLoanMenu()
                    end
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)

-- Optional quick commands
RegisterCommand('loan', function(_, args)
    local amount = tonumber(args[1] or 0)
    if not amount or amount <= 0 then
        ESX.ShowNotification(_U('cmd_loan_hint'))
        return
    end
    TriggerServerEvent('esx_bankloans:requestLoan', amount)
end, false)

RegisterCommand('payloan', function(_, args)
    local amount = tonumber(args[1] or 0)
    if not amount or amount <= 0 then
        ESX.ShowNotification(_U('cmd_pay_hint'))
        return
    end
    TriggerServerEvent('esx_bankloans:repayLoan', amount)
end, false)

DebugPrint("Client initialized.")
