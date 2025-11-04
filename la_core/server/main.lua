local Config = require("config")

local Core = {}

local function emitLog(level, message)
    local msg = string.format("[la_core][%s] %s", level, message)
    print(msg)
    return msg
end

function Core.init(opts)
    if type(opts) == "table" then
        for key, value in pairs(opts) do
            Config[key] = value
        end
    end

    RegisterCommand("la_status", function(source)
        local src = source
        local msg = emitLog("info", "Active=true")
        if src ~= 0 then
            TriggerClientEvent("chat:addMessage", src, { args = { msg } })
        end
    end, false)

    CreateThread(function()
        emitLog("info", "v1.0.2 loaded on server.")
    end)

    return { ok = true }
end

return Core
