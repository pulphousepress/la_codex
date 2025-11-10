-- Manifest describing the available datasets within la_codex.
-- Data sets are static Lua tables under `sets/`.  SQL seeds live under `sql/`.
return {
    version = require((...):gsub('manifest$', 'version')),
    sets = {
        weather         = 'sets/weather.lua',
        npcs            = 'sets/npcs.lua',
        weather_rules   = 'sets/weather_rules.lua'
    },
    sql = {
        seed = 'sql/seed.sql'
    }
}