-- ESX Bank Loans - Config

Config = {}

-- Debug/Logging
Config.Debug = true

-- Currency display
Config.CurrencySymbol = "$"

-- Default interest rate (applied once at origination: total_debt = principal * (1 + rate))
Config.DefaultInterest = 0.05 -- 5%

-- Interaction distances
Config.MarkerDrawDistance = 25.0
Config.InteractDistance   = 2.0

-- Blip Settings
Config.EnableBlips   = true
Config.BlipSprite    = 108  -- bank
Config.BlipColor     = 2
Config.BlipScale     = 0.8
Config.BlipName      = "Banking and Loan Office"

-- NPC settings
Config.EnableNPCs    = true
Config.NPCModel      = `cs_bankman`
Config.NPCScenario   = "WORLD_HUMAN_CLIPBOARD" -- idle anim

-- Loan office map locations (Legion, Paleto, Del Perro)
Config.LoanLocations = {
    vector3(243.19, 224.53, 106.29),
    vector3(246.63, 223.58, 106.29),
    vector3(241.26, 225.41, 106.29)
}

-- NPC spawn locations (x, y, z, heading)
Config.NPCSpawnLocations = {
    vector4(244.24, 226.03, 106.29, 161.67),
    vector4(-111.16, 6470.01, 31.63, 135.92),
    vector4(241.35, 227.10, 106.29, 176.64)
}
