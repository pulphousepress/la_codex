# la_codex

`la_codex` holds all static data for the Los Animales RP project.  It contains Lua tables for weather patterns, NPC spawn points, weather controller rules, and optional SQL seed data.  No code runs in this resource; everything is consumed via `la_core` exports.

## Structure

```
la_codex/
├── fxmanifest.lua       # resource manifest (no scripts)
├── version.lua          # version string for the codex
├── manifest.lua         # lists available datasets and SQL seeds
├── sets/                # Lua tables describing each dataset
│   ├── weather.lua
│   ├── npcs.lua
│   └── weather_rules.lua
└── sql/
    └── seed.sql         # optional seed data for the database
```

## Usage

1. Ensure `la_codex` is started before `la_core` in your `server.cfg`:

   ```cfg
   ensure la_codex
   ensure la_core
   ```

2. Do not reference data files directly from gameplay code.  Always call `exports.la_core:GetData('weather')` or similar to obtain a deep copy.

3. To add your own dataset, create a new file under `sets/`, update `manifest.lua`, and bump the version in `version.lua`.

4. SQL seeds in `sql/` can be executed via an optional seed command in `la_core` if you implement it.