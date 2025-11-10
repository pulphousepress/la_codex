-- la_weather/server/weather_controller.lua
-- Weather subsystem backed by la_core codex data.

local CORE = 'la_core'

return function(ctx)
    local currentWeather = 'RAIN'
    local patterns, totalWeight = {}, 0

    local function buildPatterns()
        local codex = exports[CORE]:GetData('weather')
        if type(codex) ~= 'table' then codex = {} end

        local fallback = {}
        if #codex == 0 then
            for _, name in ipairs(Config.NoirWeathers or {}) do
                table.insert(fallback, { name = name, probability = 1 })
            end
            codex = fallback
        end

        patterns = {}
        totalWeight = 0

        for _, entry in ipairs(codex) do
            if type(entry) == 'table' and entry.name then
                local weight = tonumber(entry.probability or entry.weight or 1) or 1
                if weight <= 0 then weight = 1 end
                table.insert(patterns, { name = entry.name, weight = weight })
                totalWeight = totalWeight + weight
            elseif type(entry) == 'string' then
                table.insert(patterns, { name = entry, weight = 1 })
                totalWeight = totalWeight + 1
            end
        end

        if #patterns == 0 then
            patterns = { { name = currentWeather, weight = 1 } }
            totalWeight = 1
        end

        if patterns[1] and not currentWeather then
            currentWeather = patterns[1].name
        end

        ctx.log(('weather patterns loaded (%d entries)'):format(#patterns))
    end

    local function weightedPick()
        if totalWeight <= 0 then return currentWeather end
        local roll = math.random() * totalWeight
        for _, entry in ipairs(patterns) do
            roll = roll - entry.weight
            if roll <= 0 then
                return entry.name
            end
        end
        return patterns[#patterns].name
    end

    local function syncWeather(target)
        local destination = target or -1
        TriggerClientEvent('la_weather:update', destination, currentWeather)
        if Config and Config.Debug then
            print(('[la_weather][weather] Sync -> %s (target=%s)'):format(currentWeather, tostring(destination)))
        end
    end

    local function audit(src)
        local message = ('Weather active: %s (%d patterns)'):format(currentWeather or 'unknown', #patterns)
        if src and src > 0 then
            TriggerClientEvent('chat:addMessage', src, { args = { 'LA', message } })
        else
            print('[la_weather] ' .. message)
        end
        return message
    end

    buildPatterns()
    if patterns[1] then
        currentWeather = patterns[1].name
    end

    ctx.registerAction('resync', function(target)
        if type(target) == 'number' then
            syncWeather(target)
        else
            syncWeather()
        end
        return currentWeather
    end)

    ctx.registerAction('audit', function(src)
        return audit(src)
    end)

    ctx.registerAction('refresh', function()
        buildPatterns()
        return #patterns
    end)

    ctx.registerExport('GetCurrentWeather', function()
        return currentWeather
    end)

    ctx.registerNetEvent('la_weather:requestSync', function()
        local src = source
        syncWeather(src)
    end)

    ctx.registerEvent('playerJoining', function()
        local src = source
        syncWeather(src)
    end)

    ctx.registerEvent('la_core:dataRefreshed', function(name)
        if name == 'weather' then
            buildPatterns()
        end
    end)

    CreateThread(function()
        if not Config or not Config.Enable then return end
        Wait(2000)
        print('[la_weather] Server active (noir cycle)')
        syncWeather()
        while true do
            Wait((Config.TickSeconds or 600) * 1000)
            if totalWeight <= 0 then
                buildPatterns()
            end
            local pick = weightedPick()
            if pick and pick ~= currentWeather then
                currentWeather = pick
                syncWeather()
            else
                ctx.log(('weather unchanged -> %s'):format(currentWeather))
            end
        end
    end)

    return {
        getCurrent = function()
            return currentWeather
        end
    }
end
