# Bank Loans – Ev1.1.4 (QB-Core)

Advanced in-game banking and loan management system for **QB-Core**. Handles player credit, repayments, and admin control, fully database-driven with automatic tracking.

---

## 🔧 Core Functionalities

### 💰 Player Features
- Apply for loans directly from banker NPCs or via commands.
- Automatically calculates APR based on credit score.
- Pay off loans in partial or full payments.
- Overpayment carry-over to multiple active loans.
- View current loans, debt remaining, and APR.
- Automatic paycheck deduction for repayments.
- Credit system that increases/decreases based on repayment behavior.
- Multiple active loans supported (limited by configuration).
- 3D Text or qb-target based interaction with banker NPCs.
- All actions fully validated and logged to SQL.

### 🏦 Admin Features
- Instantly grant loans to players with `/grant_loan`.
- Forgive or cancel any loan with `/forgive_loan`.
- Adjust APR on active loans with `/setloan_apr`.
- Full ACE permission control for admin-only access.
- Complete SQL logging for all loan events.
- Auto-create and verify all necessary SQL tables on start.

---

## 💻 Player Commands

| Command | Description | Example |
|----------|--------------|----------|
| `/apply_loan [amount]` | Apply for a loan (validated by credit and limits). | `/apply_loan 50000` |
| `/pay_loan [amount]` | Make a loan payment. | `/pay_loan 25000` |
| `/loans` | View all active loans and progress. | `/loans` |

---

## 🛠️ Admin Commands (ACE Protected)

| Command | Description | Example |
|----------|--------------|----------|
| `/grant_loan [id] [amount] [apr]` | Grant a loan to a player. | `/grant_loan 3 20000 0.04` |
| `/forgive_loan [loan_id]` | Write off a loan by ID. | `/forgive_loan 12` |
| `/setloan_apr [loan_id] [apr]` | Adjust APR on an existing loan. | `/setloan_apr 12 0.05` |

> Requires ACE permission: `qbcore.admin`

---

## 🧠 Events

| Event | Description | Parameters |
|--------|--------------|-------------|
| `bankloan:RequestLoan` | Requests a new loan. | `(amount)` |
| `bankloan:PayLoan` | Pays existing loan(s). | `(amount)` |
| `bankloan:server:GetLoans` | Returns player loan data. | Callback |
| `bankloan:Server:AutoDeductFromPaycheck` | Deducts repayment from paycheck. | `(payAmount)` |

---

## 🔁 Exports

| Export | Description | Parameters | Returns |
|--------|--------------|-------------|----------|
| `exports['Bank_Loans']:GetTotalDebt(citizenid, cb)` | Returns total player debt. | `(citizenid, cb)` | Total outstanding debt |

---

## 🧩 Database Tables

### `player_loans`
| Column | Description |
|---------|-------------|
| id | Unique loan ID |
| citizenid | Player citizen ID |
| principal | Original borrowed amount |
| interest_rate | Loan APR |
| total_debt | Debt with interest |
| amount_paid | Paid amount |
| created_at | Creation timestamp |

### `loan_history`
| Column | Description |
|---------|-------------|
| id | Log ID |
| citizenid | Player citizen ID |
| action | Event type (grant, pay, adjust, etc.) |
| amount | Affected amount |
| meta | Extra metadata |
| created_at | Log timestamp |

---

## ⚙️ Config Highlights
- Select backend: `auto`, `oxmysql`, or `mysql-async`
- Toggle qb-target or 3D text interaction
- Configure credit limits, APR clamps, and max loans
- Enable auto paycheck deductions
- Auto SQL creation for all tables
- Locales support (default `en.lua`)

---

## ✅ Summary
Players can request, pay, and manage loans entirely in-game.  
Admins have full oversight and control over loan management.  
All systems are secure, configurable, and fully database-persistent.

---
