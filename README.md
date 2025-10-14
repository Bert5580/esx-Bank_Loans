# Bank Loans — Qv1.1.1 (QB-Core)

Patch over 1.1.0 with **stability fixes** and **menu/input fallbacks**.

### Changes in 1.1.1
- Fixed client callback usage to **QBCore callbacks** (removed stray `ox_lib` references).
- Implemented safe **/apply_loan** and **/pay_loan** commands; menu now instructs without requiring qb-input/ox_lib.
- Corrected server row indexing when selecting oldest active loan.
- Minor credit defaulting improvements if JSON field is absent.
- Kept **oxmysql → mysql-async** auto-detection; included `@mysql-async/lib/MySQL.lua` for compatibility.

### Install
1. Ensure **qb-core** and either **oxmysql** or **mysql-async** are running.
2. Drop folder in `resources/[qb]/Bank_Loans`.
3. `server.cfg`:
   ```cfg
   ensure Bank_Loans
   add_ace group.admin qbcore.admin allow
   ```
4. If first-time DB, run `BankLoans.sql` (or rely on auto-create at startup).

### Player Commands
- `/apply_loan [amount]`
- `/pay_loan [amount]`

### Admin
- `/grant_loan [id] [amount] [rate]` (ACE `qbcore.admin`)

### Events
- `bankloan:RequestLoan(amount)`
- `bankloan:PayLoan(amount)`
- `bankloan:server:GetLoans` (callback)
- `bankloan:Server:AutoDeductFromPaycheck(payAmount)`

SQL schema: see `BankLoans.sql`.
