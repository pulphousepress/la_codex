-- la_engine/server/main.lua
-- Server side boot and link to la_core.

local RES = GetCurrentResourceName()
local Config = Config or { Debug = true }

local function log(level, msg)
    if Config.Debug then
        print(('[la_engine][%s] %s'):format(level, msg))
    end
end

AddEventHandler('la_core:ready', function()
    local ok, version = pcall(function() return exports.la_core:GetVersion() end)
    if ok then
        log('info', ('la_core ready (version %s)'):format(version))
    else
        log('warn', 'la_core not linked')
    end
end)

RegisterCommand('la_engine_status', function(src)
    if src == 0 then
        log('info', 'la_engine server status OK')
    else
        TriggerClientEvent('chat:addMessage', src, { args = { '^2LA Engine', 'Server status OK' } })
    end
end, false)
