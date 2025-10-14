Config = {}

-- Debug and print helpers
Config.Debug = false

-- Storage: 'oxmysql' (preferred) or 'mysql-async' (fallback)
-- If set to 'auto', server.lua will detect automatically at runtime.
Config.Storage = 'auto'

-- Loan rules
Config.MaxLoanAmount          = 250000     -- Absolute cap for a single loan
Config.MaxActiveLoansPerUser  = 2          -- Prevent too many concurrent loans
Config.MinCreditToBorrow      = 550        -- Floor credit score to allow any loan
Config.BaseInterestRate       = 0.03       -- 3% baseline interest
Config.CreditRateDiscountStep = 0.002      -- reduce interest 0.2% per 50 credit over 650
Config.CreditRateDiscountPer  = 50         -- step amount of credit
Config.CreditPivot            = 650

-- Repayments
Config.EnableAutoDeduction = true
Config.AutoDeductionPercent = 0.10  -- 10% of paycheck
Config.MinManualPayment     = 100   -- Smallest allowed manual payment

-- NPC/Target
Config.UseQBTarget = true  -- if false you can make your own command/UI
Config.PedModel    = `cs_bankman`
Config.PedScenario = 'WORLD_HUMAN_CLIPBOARD'
Config.PedLocations = {
    vec4(149.52, -1042.08, 29.37, 340.0), -- Maze Bank
    vec4(-2962.65, 482.97, 15.70, 88.0),  -- Pacific
}

-- ACE/Permissions
Config.AdminAce = 'qbcore.admin'

-- Credit changes
Config.Credit = {
    OnPartialPay = 25,
    OnFullPay    = 150,
    OnMissedPay  = -25
}

-- SQL table names
Config.TableLoans   = 'player_loans'
Config.TablePlayers = 'players'   -- Default QB table, contains citizenid and money JSON
-- Log table (optional)
Config.TableLogs    = 'loan_history'

-- Locale
Config.Locale = 'en'
