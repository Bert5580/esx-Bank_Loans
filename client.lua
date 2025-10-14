local QBCore = exports['qb-core']:GetCoreObject()
local pedList, textZones = {}, {}

local function debugPrint(...)
    if Config.Debug then
        print('[BankLoans] ', ...)
    end
end

local function draw3DText(x, y, z, text)
    local onScreen,_x,_y = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
end

local function createPedAt(coords)
    local model = Config.PedModel
    if not IsModelInCdimage(model) then return end
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, Config.PedScenario, 0, true)
    table.insert(pedList, ped)
    return ped
end

CreateThread(function()
    for _, v in ipairs(Config.PedLocations) do
        local ped = createPedAt(v)
        if Config.UseQBTarget and ped then
            exports['qb-target']:AddTargetEntity(ped, {
                options = {{ label = Lang:t('ui.loan_menu'), icon = 'fas fa-hand-holding-dollar', action = function() TriggerEvent('bankloan:openMenu') end }},
                distance = 2.0
            })
        else
            table.insert(textZones, vec3(v.x, v.y, v.z))
        end
    end
end)

-- 3D text prompt fallback
CreateThread(function()
    while true do
        if #textZones > 0 then
            local p = PlayerPedId()
            local px,py,pz = table.unpack(GetEntityCoords(p))
            for _, pos in ipairs(textZones) do
                if #(vector3(px,py,pz) - pos) < 2.0 then
                    draw3DText(pos.x, pos.y, pos.z+1.0, "~w~[E] "..Lang:t('ui.loan_menu'))
                    if IsControlJustPressed(0, 38) then -- E
                        TriggerEvent('bankloan:openMenu')
                    end
                end
            end
        end
        Wait(0)
    end
end)

RegisterNetEvent('bankloan:openMenu', function()
    QBCore.Functions.TriggerCallback('bankloan:server:GetLoans', function(loans)
        local elements = {
            { header = Lang:t('ui.loan_menu'), isMenuHeader = true },
            { header = Lang:t('ui.apply_loan'), params = { event = 'bankloan:applyPrompt' } },
            { header = Lang:t('ui.pay_loan'),   params = { event = 'bankloan:payPrompt' } },
            { header = Lang:t('ui.view_loans'), params = { event = 'bankloan:listLoans' } },
        }
        exports['qb-menu']:openMenu(elements)
    end)
end)

RegisterNetEvent('bankloan:listLoans', function()
    QBCore.Functions.TriggerCallback('bankloan:server:GetLoans', function(loans)
        local rows = {}
        for _, L in ipairs(loans or {}) do
            rows[#rows+1] = ('ID %s | APR %s%% | Debt: $%s | Paid: $%s'):format(L.id, math.floor((L.interest_rate or 0)*100), L.total_debt, L.amount_paid)
        end
        if #rows == 0 then rows[1] = Lang:t('notify.no_debt') end
        QBCore.Functions.Notify(table.concat(rows, '
'), 'primary', 9000)
    end)
end)

RegisterNetEvent('bankloan:applyPrompt', function()
    QBCore.Functions.Notify(Lang:t('notify.use_command_apply'), 'primary')
end)
RegisterNetEvent('bankloan:payPrompt', function()
    QBCore.Functions.Notify('Type /pay_loan [amount] to make a payment.', 'primary')
end)

-- Commands
RegisterCommand('apply_loan', function(_, args)
    local amt = tonumber(args[1] or '0') or 0
    if amt <= 0 then
        QBCore.Functions.Notify(Lang:t('notify.amount_invalid'), 'error')
        return
    end
    TriggerServerEvent('bankloan:RequestLoan', amt)
end, false)

RegisterCommand('pay_loan', function(_, args)
    local amt = tonumber(args[1] or '0') or 0
    if amt <= 0 then
        QBCore.Functions.Notify(Lang:t('notify.amount_invalid'), 'error')
        return
    end
    TriggerServerEvent('bankloan:PayLoan', amt)
end, false)

RegisterCommand('loans', function()
    TriggerEvent('bankloan:listLoans')
end, false)

-- Suggestions
TriggerEvent('chat:addSuggestion', '/apply_loan', Lang:t('cmd.apply'), {{ name = "amount", help = "Loan amount" }})
TriggerEvent('chat:addSuggestion', '/pay_loan', Lang:t('cmd.pay'), {{ name = "amount", help = "Amount to pay" }})
TriggerEvent('chat:addSuggestion', '/loans',     Lang:t('cmd.loans'))
