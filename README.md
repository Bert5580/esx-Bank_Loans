# esx-Bank_Loans (Ev1.1.5) — ESX Legacy + mysql-async

Bank loans system for ESX Legacy backed by MySQL‑async. Players can apply for loans, repay with interest on a schedule, and view history; admins can approve, deny, forgive, or adjust balances.

## Features

- Borrow in‑game cash with configurable principal limits, interest, and repayment cadence.
- Automatic interest accrual and scheduled repayment deductions.
- Early repayment (partial or full) with recalculated interest.
- Missed‑payment handling: late fees and configurable penalties (optional).
- Loan states: *pending*, *approved*, *active*, *delinquent*, *closed*.
- Admin review tools to approve/deny/forgive loans, and to adjust balances.
- On‑screen notifications and chat feedback for all key actions.
- MySQL‑async backed persistence with history/audit tables.
- Locale support (if `locales/` present).
- Zero gameplay changes vs Ev1.1.5; documentation only in Ev1.1.5.
## Requirements

- FiveM (FXServer)
- ESX Legacy
- `mysql-async`
- MariaDB/MySQL 10.3+

**Identifier column width:** ensure `users.identifier` is `VARCHAR(60)` to avoid FK width issues in history tables.
## Installation

1) Drop this resource folder into `resources/` and add to `server.cfg` **after** your DB/ESX resources:
   ```cfg
   ensure esx-Bank_Loans
   ```
2) Configure DB connection for `mysql-async` in your server’s config.
3) Review `config.lua` and **tune** loan caps, interest, repayment interval, and permissions.
4) (Optional) Import any SQL included in `sql/` if you prefer manual migration. Otherwise the resource will create tables on first run.
5) Restart the server. Watch console for `[esx-Bank_Loans]` messages.
## Commands

- `/loan`
- `/payloan`
## Configuration

Detected options in `config.lua`:
- `Config.BlipColor`
- `Config.BlipName`
- `Config.BlipScale`
- `Config.BlipSprite`
- `Config.CurrencySymbol`
- `Config.Debug`
- `Config.DefaultInterest`
- `Config.EnableBlips`
- `Config.EnableNPCs`
- `Config.InteractDistance`
- `Config.LoanLocations`
- `Config.MarkerDrawDistance`
- `Config.NPCModel`
- `Config.NPCScenario`
- `Config.NPCSpawnLocations`
## Events & Exports

_Relevant events (sample, discovered from codebase):_
- `esx:getSharedObject`
- `esx_bankloans:requestLoan`
- `esx_bankloans:repayLoan`
## Troubleshooting

- **ER_NO_SUCH_TABLE / migration errors** → Ensure DB is reachable; confirm `mysql-async` loads **before** this resource.
- **Foreign key width errors** → Set `users.identifier` to `VARCHAR(60)` (utf8mb4). Avoid altering referenced width smaller than FK targets.
- **ETIMEDOUT connecting DB** → Check `mysql_connection_string`, host/port, firewall and DB uptime.
- **No markers showing** → Verify `Config.Blips/Markers` toggles; ensure you're on foot within the configured range and not inside interiors.
- Enable `Config.Debug = true` (if available) and tail your server console for verbose logs.
## Versioning

This project uses **Ev** semantic tags (example: `Ev1.1.5`).
