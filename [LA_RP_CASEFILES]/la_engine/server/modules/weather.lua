-- la_engine/server/modules/weather.lua
-- Weather controller for Los Animales RP.

local CORE = 'la_core'
local rules
local current = { weather = nil, hour = nil }

local function log(msg)
    if Config and Config.Debug then
        print('[la_weather] ' .. msg)
    end
end

local function weightedPick(patterns)
    local total = 0
    for _,p in ipairs(patterns) do total = total + (p.weight or 1) end
    if total <= 0 then return nil end
    local r = math.random() * total
    for _,p in ipairs(patterns) do
        r = r - (p.weight or 1)
        if r <= 0 then return p.name end
    end
    return patterns[#patterns].name
end

local function maybeTransition(cur, transitions)
    for _,t in ipairs(transitions or {}) do
        if t.from == cur and math.random() < (t.chance or 0) then
            return t.to
        end
    end
    return cur
end

local function broadcast(weather, hour, blend)
    TriggerClientEvent('la_engine:weather:update', -1, weather, hour, blend or 10)
end

local function pullRules()
    rules = exports[CORE]:GetData('weather_rules')
    if not rules then
        log('Failed to pull weather_rules; using default')
        rules = {
            sync = { intervalMs = 30000, default = 'EXTRASUNNY', initialHour = 9, timeScale = 1.0 },
            patterns = { { name='EXTRASUNNY', weight=1 } },
            transitions = {}
        }
    end
end

local function tickOnce()
    if not rules or not rules.patterns then return end
    local pick = weightedPick(rules.patterns) or rules.sync.default
    pick = maybeTransition(pick, rules.transitions)
    current.weather = pick
    current.hour = current.hour or rules.sync.initialHour
    broadcast(current.weather, current.hour, 10)
    log(('Weather pick: %s (hour %02d)'):format(current.weather, current.hour))
end

local function advanceHour()
    if not rules or not rules.sync then return end
    local step = (rules.sync.timeScale or 1.0)
    local add = math.floor(step)
    if add > 0 then
        current.hour = ((current.hour or rules.sync.initialHour) + add) % 24
    end
end

AddEventHandler('la_core:ready', function()
    pullRules()
    current.hour = rules.sync.initialHour
    broadcast(rules.sync.default, current.hour, 0)
end)

AddEventHandler('la_core:dataRefreshed', function(name)
    if name == 'weather_rules' then
        pullRules()
        log('Weather rules refreshed')
    end
end)

CreateThread(function()
    while true do
        if not rules then pullRules() end
        local interval = (rules.sync and rules.sync.intervalMs) or 30000
        tickOnce()
        advanceHour()
        Wait(interval)
    end
end)
