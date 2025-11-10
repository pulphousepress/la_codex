# la_core

`la_core` provides shared utilities and exports for the Los Animales RP server.  It prints the server version when starting and exposes a simple status export.  Use this module as the base for other resources.

## Exports

| Export       | Description                                 |
|-------------|---------------------------------------------|
| `GetVersion()` | Returns the version string from `config.lua`. |
| `PrintStatus()`| Logs the current version to the server console. |

## Commands

`/la_status` — prints the current core version to the invoking player's chat or console.

## Server Configuration

Add this resource early in your `server.cfg` to ensure it starts before consumers:

```
ensure ox_lib
ensure la_core
```

## Extending

Create additional schema validators under `server/schemas/` to validate datasets loaded from `la_codex`.  Each file must return a function of the form `function(data) → boolean, table` and return `true, {}` when valid.