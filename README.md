# esx-Bank_Loans — Ev1.1.4

A lightweight, production‑ready bank loans system for **ESX Legacy** using **mysql-async**.
This README focuses on **functionalities** and **commands** only, per request.

---

## Core Functionalities

- **Request Loans** in‑game via NPC/marker or command.
- **Repay Loans** partially or in full; interest is applied based on configuration.
- **Live Status Check** (client ↔ server callback) for current loan balance, interest, and due amount.
- **World Integration**
  - Optional **map blips** for loan locations.
  - Optional **NPC banker** ped with scenario idling.
  - 3D markers with configurable draw distances and interact range.
- **Config‑Driven** operation; tune interest, UI strings, and locations without touching code.
- **MySQL Persistence** using `mysql-async` (see `BankLoans.sql`).

> Note: This resource is namespaced as `esx_bankloans` for events/callbacks.

---

## Player Commands

- `/loan` — Open/request a new loan at the nearest loan location (or on demand if allowed).
- `/payloan` — Repay an existing loan (prompts amount selection in UI/entry, depending on your setup).

> Both commands require the resource to be started and the player to be loaded into ESX.

---

## Admin / Staff Commands

This version does **not** expose special admin‑only slash commands out of the box.
Administrative actions (reset, adjust, forgive) are typically performed through database ops or custom tooling.
If you require admin commands, we can extend with e.g. `/loanadmin reset <identifier>`, `/loanadmin set <identifier> <amount>`, etc.

---

## Developer Hooks

### Client/Server Events
- `esx_bankloans:requestLoan` — Client → Server request to create a loan.
- `esx_bankloans:repayLoan` — Client → Server request to repay an amount.

### ESX Callbacks
- `esx_bankloans:getStatus` — Client → Server → Client round‑trip to fetch live loan info.

_No exported functions are defined in this release._

---

## Configuration Keys (Quick Reference)

Defined in `config.lua`:

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

Typical highlights:
- `Config.DefaultInterest` — Default interest rate (per period) for new loans.
- `Config.CurrencySymbol` — Currency prefix used in notifications/UI (e.g., `$`).
- `Config.EnableBlips`, `Config.BlipSprite`, `Config.BlipColor`, `Config.BlipScale`, `Config.BlipName` — Map blip controls.
- `Config.EnableNPCs`, `Config.NPCModel`, `Config.NPCScenario`, `Config.NPCSpawnLocations` — Banker NPC spawning.
- `Config.LoanLocations`, `Config.MarkerDrawDistance`, `Config.InteractDistance` — In‑world interaction tuning.
- `Config.Debug` — Verbose prints for debugging during development.

---

## SQL

Run the SQL shipped with the resource before first use:

- `BankLoans.sql`

This creates/updates the tables needed for storing loan accounts and history. Ensure your database/connection settings for `mysql-async` are correctly configured in your server artifacts and ESX environment.

---

## Compatibility

- **Framework:** ESX Legacy
- **Database:** mysql-async
- **FXServer:** cerulean (fxmanifest.lua provided)

---

## Versioning

This package follows the user's preferred **Ev** scheme. Current: **Ev1.1.4**.

---

_Last updated: 2025-10-15_
