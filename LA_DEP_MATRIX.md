# pulphousepress/la_rp_casefiles/docs/DEP_MATRIX.md

```markdown
# Los Animales RP – Dependency Matrix (Three-Layer Refactor)

> Scope: `la_codex` (data), `la_core` (authoritative API), `la_engine` (runtime gameplay), plus detective stack notes.

## High-Level Graph

```

```
        +--------------------+
        |      la_codex      |
        |  (data-only sets)  |
        +---------+----------+
                  |
                  v
        +--------------------+            (optional seed via oxmysql)
        |      la_core       |<----------------------------------+
        |  glue + exports    |                                   |
        +---------+----------+                                   |
                  |                                              |
      read-only exports/events                                   |
                  v                                              |
        +--------------------+                                   |
        |     la_engine      |                                   |
        | runtime consumers  |                                   |
        +--------------------+                                   |
                                                                 |
```

+----------------------+   +-----------+   +-----------+          |
|      ox_lib          |   |  oxmysql  |   |  qbx_core |          |
| (json, callbacks)    |   | (DB I/O)  |   | (jobs, fw)|          |
+----------+-----------+   +-----+-----+   +-----+-----+          |
|                     |               |                 |
+--------- used by la_core ---------- +                 |
(and la_engine via callbacks)         |

```

## Layer Contracts

### `la_core` Server Exports
- `GetCodexVersion() -> string`
- `ListSets() -> string[]`
- `GetData(setName:string) -> table` (immutable deep copy)
- `ValidateSet(setName:string, data:table) -> ok:boolean, errs:string[]`
- `RefreshData(setNameOrAll:'all'|string) -> ok:boolean, errs:string[]`

### `la_core` Events
- `la_core:ready()`
- `la_core:dataRefreshed(setName, version, checksum)`

## Dependencies (by resource)

### `la_codex` (data-only)
- **Depends on:** none at runtime.
- **Depended on by:** `la_core`.
- **Notes:** Contains `manifest.lua`, `version.lua`, `sets/*.lua`, `sql/seed.sql`. No loops/handlers/I/O.

### `la_core`
- **Depends on:** `la_codex`, `ox_lib` (helpers), `oxmysql` (only for seeding).
- **Provides:** server exports + events to all consumers.
- **Owns:** schemas in `server/schemas/*.lua` (authoritative validation).

### `la_engine`
- **Depends on:** `la_core`, `ox_lib` (callbacks), base framework services already present (qbox).
- **Provides:** gameplay loops/controllers that only read via `la_core`. No DB or cross-layer file access.

### Detective Stack (for later integration)
- `la_gumshoe` depends on: `la_core`, `ox_lib`, `oxmysql`, `ox_inventory`, `qbx_core`, `npwd` (per directive).
- It should consume codex data via `la_core` only; no direct codex reads.

## Server Ensure Order (Minimal)
```

ensure oxmysql
ensure ox_lib
ensure la_codex
ensure la_core
ensure la_engine

# later:

# ensure [detective]/la_gumshoe

```

## Cross-Layer Access Policy
- `la_engine` and other resources: **read-only** via `la_core` exports/events.
- `la_core` is the **only** layer allowed to:
  - load from `la_codex/sets`
  - run optional seeding via `oxmysql`
  - perform schema validation

## Notes
- All datasets in `la_codex` must be declared in `manifest.lua`.
- Each dataset ideally has a matching schema in `la_core/server/schemas`.
- `RefreshData('all')` rebroadcasts `la_core:dataRefreshed` for live reloading.
```

---

# pulphousepress/la_rp_casefiles/docs/AUDIT_SUMMARY.md

````markdown
# Los Animales RP – Repository Audit Summary (Three-Layer Refactor)

**Date:** Current  
**Operator note:** This summary is auto-curated for quick verification after merge.

---

## Structure Check (Pass)

- `la_codex/`
  - `fxmanifest.lua` (data resource, no scripts run)
  - `version.lua` (e.g., `0.1.0`)
  - `manifest.lua` (declares data sets + optional SQL path)
  - `sets/` (`weather.lua`, `npcs.lua`, …)
  - `sql/seed.sql` (optional initial seed)

- `la_core/`
  - `fxmanifest.lua` (declares server exports)
  - `config.lua` (Debug, SeedOnStart, SeedAce)
  - `server/main.lua` (bootstrap, cache, exports, events, seeding)
  - `server/schemas/*.lua` (validators: `weather.lua`, `npcs.lua`)
  - `README.md` (docs for exports/events)

- `la_engine/`
  - `fxmanifest.lua`
  - `config.lua`
  - `server/main.lua` (consumes `la_core`, demonstrates loop)
  - `client/main.lua` (callback demo)
  - `README.md`

**Result:** ✅ All present, names and paths conform to conventions.

---

## Export & Event Contract (Pass)

- **Exports implemented (server):**
  - `GetCodexVersion`
  - `ListSets`
  - `GetData` (returns deep copy)
  - `ValidateSet`
  - `RefreshData`

- **Events:**
  - `la_core:ready()` fires on resource start after datasets load.
  - `la_core:dataRefreshed(setName, version, checksum)` fires per dataset on refresh.

**Result:** ✅ Matches requested contract.

---

## Policy Compliance

- **No DB/file access from `la_engine`:** ✅
- **Centralized `schemas/*.lua` in `la_core`:** ✅
- **Immutable returns from `GetData`:** ✅ Deep copy.
- **Controlled refresh via export only:** ✅ `RefreshData()`.
- **Use of `ox_lib` helpers / callbacks:** ✅
- **Use of `oxmysql` only in `la_core` seeding:** ✅
- **Light loops (>= 60s sample in engine):** ✅ 60s demo; configurable.

---

## Ensure Order (Minimal Block)

Place near the top of `server.cfg`, after base libs:

```cfg
ensure oxmysql
ensure ox_lib
ensure la_codex
ensure la_core
ensure la_engine
````

> Add detective stack later:
> `ensure [detective]/la_gumshoe`

---

## Live Reload Sanity

* `exports.la_core:RefreshData('all')` → rebroadcasts `la_core:dataRefreshed` for each set (OK)
* `ListSets()` reflects `manifest.lua` keys (OK)
* Missing schema defaults to pass-through valid (OK by design, warn in logs)

---

## Risks & Recommendations

* **Schema coverage:** Add schemas for any new datasets to catch bad data early.
* **Version bump discipline:** Update `la_codex/version.lua` with every dataset change to simplify cache coherency.
* **Checksum:** Currently entry count; consider stable hash (xxhash/CRC32) if collisions matter.

---

## Operator Quick Checklist

1. Boot server – confirm `[la_core][info] la_core ready (version X.Y.Z)`.
2. Run in console: `lua exports['la_core']:ListSets()` (via a small debug command if needed).
3. Trigger refresh: `lua exports['la_core']:RefreshData('all')` (or via test cmd) to see `dataRefreshed` events.
4. Watch `la_engine` log picker print a weather row every minute.

````

---

# pulphousepress/la_rp_casefiles/tests/POST_MERGE_TEST_PLAN.md
```markdown
# Post-Merge Test Plan – Three-Layer Architecture

**Goal:** Verify `la_codex` → `la_core` → `la_engine` contract end-to-end in under 5 minutes.

---

## 0) Server Ensure Order (required)

```cfg
ensure oxmysql
ensure ox_lib
ensure la_codex
ensure la_core
ensure la_engine
````

Restart the server.

**Expected console lines:**

* `[la_core][info] la_core ready (version 0.1.0)`
* `[la_engine][info] Codex version 0.1.0; available sets: weather, npcs`
* `[la_engine][info] Loaded 4 weather patterns`

---

## 1) Export Availability

From server console (or a tiny admin command wrapper):

* **List sets**

  * Call: `exports['la_core']:ListSets()`
  * **Expect:** `{ "weather", "npcs" }` (order may vary)

* **Get version**

  * Call: `exports['la_core']:GetCodexVersion()`
  * **Expect:** `"0.1.0"`

* **Fetch data**

  * Call: `exports['la_core']:GetData('weather')`
  * **Expect:** table array with 4 entries, each `{ name = string, probability = number }`

---

## 2) Validation Behavior

* **Valid:** `exports['la_core']:ValidateSet('weather', {{ name='SUNNY', probability=0.5 }})`

  * **Expect:** `true, {}`

* **Invalid:** `exports['la_core']:ValidateSet('weather', {{ name=123, probability='bad' }})`

  * **Expect:** `false, { "entry[1].name ...", "entry[1].probability ..." }`

---

## 3) Refresh Workflow

* Change a value in `la_codex/sets/weather.lua` (e.g., add `{ name='OVERCAST', probability=0.1 }`) and bump `la_codex/version.lua` to `0.1.1`.

* Run: `exports['la_core']:RefreshData('all')`

**Expected server console:**

* `[la_core][info] Data refreshed: weather (version 0.1.1, checksum 5)`
* `[la_engine][info] Data refreshed: weather (version 0.1.1, checksum 5)`
* `[la_engine][info] Loaded 5 weather patterns` (on next access)

---

## 4) Engine Runtime Proof

Wait for one interval (default 60s) and confirm a log like:

`[la_engine][info] Random weather pick: RAIN (prob 0.20)`

> You can change interval in `la_engine/config.lua` to `10000` (10s) for quicker feedback during testing.

---

## 5) Optional DB Seed

* Set `SeedOnStart = true` in `la_core/config.lua` **or** run `/la_core_seed` (requires ACE per `SeedAce`).
* **Expect:** `[la_core][info] Seeding database...` then `Database seed complete`.

---

## 6) Client Callback

Join the server. When `la_core:ready` fires, client should log:

`[la_engine][client][info] Client received X NPC entries from server`

(X equals number of entries in `la_codex/sets/npcs.lua`)

---

## 7) Rollback/Idempotency

* Restart only `la_engine` → no duplicate side effects.
* Restart only `la_core` → it reloads manifest & datasets and re-emits `la_core:ready`.
* Restart only `la_codex` → no runtime effect until `RefreshData()` is called (by design).

---

## Pass Criteria

* All exports callable without error.
* Schemas reject malformed data.
* `la_engine` receives refreshed data via event and continues operating without restart.
* Optional DB seed runs exactly once and logs success.


