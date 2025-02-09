# ESX Bank Loans System

## 📌 Overview
The **Bank Loans System** is a fully integrated **loan and credit system** designed for **ESX Legacy**. It allows players to take loans, repay them through paychecks, and manage their credit.

## 🔥 Features:
- **Fully Integrated Loan System**
  - Tracks **credit** and **debit** in the database.
  - Interest rates applied dynamically.
- **Automatic Paycheck Deduction**
  - Repayment system built into the economy.
- **Admin Credit Management**
  - Add or remove credit via commands.
- **NPC-Based Loan Interactions**
  - Players can visit NPCs to apply for loans.
- **Dynamic Loan Configurations**
  - Adjustable interest rates, credit requirements, and repayment amounts.
- **Multi-Language Support**
  - Locales available for translations.
- **Debug Mode**
  - Logs events, errors, and system interactions.

---

## 🛠 How the Credit System Works
The **Credit System** in this script is a numerical score assigned to each player, representing their financial reliability. This credit score influences the player's ability to take out loans, the amount they can borrow, and the interest rate applied.

### 🔎 How Credit Impacts Loans
1. **Loan Eligibility** – Higher credit scores allow access to larger loans.
2. **Interest Rates** – Lower credit means **higher** interest rates.
3. **Loan Repayments** – Players with better credit scores have **more favorable loan terms**.
4. **Full Loan Repayment Bonus** – Paying off all debts rewards **bonus credit**.
5. **Default & Missed Payments** – Late payments or missed repayments **decrease credit**.

### 📅 Credit Adjustments
| Action | Credit Change |
|--------|--------------|
| Paying a Loan | +50 Credit |
| Paying Full Loan | +150 Credit |
| Missing Payment | -25 Credit |
| Admin Adjustment | Variable |

A player's credit is stored in the **`users`** table, and all loans are tracked in the **`player_loans`** table.

---

## 💰 How the Loan System Works
Loans are granted based on **credit score, interest rate, and loan amount**. Each loan has:

- **Total Debt** = `Loan Amount + Interest`
- **Required Credit** = Minimum credit required for approval.
- **Interest Rate** = Determines how much extra must be repaid.

### 👩‍💼 Example Loan Calculation
If a player borrows **$10,000** at **3% interest** (`0.03`):
- Total Debt = **$10,000 + (10,000 * 0.03) = $10,300**
- The player repays in installments until their debt is **$0**.

### 🔍 Loan Repayment Methods
- **Manual Repayment** – Players use `/pay_loan [amount]` to pay back loans.
- **Automatic Deductions** – If enabled, a percentage of each paycheck automatically goes towards repayment.
- **Loan Balance Updates** – The script dynamically updates the `player_loans` table.

---

## 🔗 Integration Guide – Using This in Other Scripts
You can integrate **loans and credit** into **any script** that interacts with player money. Below are examples:

### 🔹 1. Granting Credit from a Job or Event
```lua
RegisterNetEvent('job:bonus')
AddEventHandler('job:bonus', function()
    local playerId = source
    local creditBonus = 10 -- Increase by 10 points
    TriggerServerEvent('bankloan:addCredit', playerId, creditBonus, "Job Performance Bonus")
end)
```

### 🔹 2. Checking a Player’s Debt
```lua
ESX.RegisterServerCallback('bankloan:getPlayerDebt', function(source, cb)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.getIdentifier()
    MySQL.Async.fetchScalar("SELECT SUM(total_debt - amount_paid) FROM player_loans WHERE identifier = ?", { identifier }, function(debt)
        cb(debt or 0)
    end)
end)
```

### 🔹 3. Auto-Deduct Loan Payments from Paychecks
```lua
RegisterNetEvent('player:receivePaycheck')
AddEventHandler('player:receivePaycheck', function(amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local deduction = math.floor(amount * 0.10) -- Deduct 10% of paycheck
    TriggerServerEvent('bankloan:payLoan', deduction)
end)
```

### 🔹 4. Prevent Players from Taking More Loans
```lua
ESX.RegisterServerCallback('bankloan:canTakeLoan', function(source, cb, amountRequested)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return cb(false) end

    local identifier = xPlayer.getIdentifier()
    MySQL.Async.fetchScalar("SELECT SUM(total_debt - amount_paid) FROM player_loans WHERE identifier = ?", { identifier }, function(debt)
        if debt and debt > (Config.MaxLoanAmount / 2) then
            cb(false) -- Too much debt, deny loan
        else
            cb(true) -- Allow loan
        end
    end)
end)
```

---

## 📃 Commands List
### 🟢 Player Commands
| Command | Description |
|---------------|------------|
| `/check_credit` | Displays the player's current credit. |
| `/check_debit` | Shows the remaining debt balance. |
| `/pay_loan [amount]` | Pays off a specific amount towards the loan. |

### 🔴 Admin Commands
| Command | Description |
|---------------|------------|
| `/grant_loan [id] [amount] [interest]` | Grants a loan to a specific player. |
| `/addcredit [id] [amount]` | Adds credit to a player. |
| `/removecredit [id] [amount]` | Removes credit from a player. |

---

## 🛠 Need Help?
Join our **Discord community** for support or open an issue on GitHub! 🚀
