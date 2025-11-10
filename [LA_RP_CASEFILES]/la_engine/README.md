# la_engine

`la_engine` is the runtime gameplay layer for Los Animales RP.  It listens for events from `la_core` and manages controllers such as the weather system.  It contains both server and client components.

## Features

- Logs when `la_core` is ready on the server and client.
- Contains a weather controller under `server/modules/weather.lua` that picks random weather patterns based on rules from the codex and broadcasts updates to clients.
- Exposes a simple `/la_engine_status` command on both server and client for debugging.

## Load Order

Ensure `la_core` starts before `la_engine`:

```
ensure la_core
ensure la_engine
```

## Weather Controller

Weather rules live in the codex under `sets/weather_rules.lua`.  The server module retrieves these rules via `exports.la_core:GetData('weather_rules')` and uses them to pick random weather every interval.  It broadcasts updates to clients via the `la_engine:weather:update` event.  Clients apply weather changes and update the world clock accordingly.

You can adjust the interval and debug logging in `la_engine/config.lua`.