local Config = require("config")

local CoreClient = {}

function CoreClient.init(opts)
    if type(opts) == "table" then
        for key, value in pairs(opts) do
            Config[key] = value
        end
    end

    RegisterCommand("la_status", function()
        print("[la_core] Active=true")
    end, false)

    return { ok = true }
end

return CoreClient
