-- Client weather receiver for Los Animales RP.
-- Applies weather changes sent from the server.

local function applyWeather(name, blend)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypeOverTime(name, blend or 10.0)
    Wait((blend or 10) * 1000)
    SetWeatherTypeNowPersist(name)
end

RegisterNetEvent('la_engine:weather:update', function(name, hour, blend)
    if type(name) ~= 'string' then return end
    local h = tonumber(hour) or 9
    applyWeather(name, blend)
    NetworkOverrideClockTime(h, 0, 0)
end)