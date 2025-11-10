-- la_weather/server/era_vehicles.lua
-- Vehicle gating subsystem using la_core codex data.

local CORE = 'la_core'

return function(ctx)
    local allowedHashes, allowedNames, prefixes = {}, {}, {}

    local function addModel(model)
        if type(model) == 'string' then
            local lower = model:lower()
            allowedNames[lower] = true
            allowedHashes[GetHashKey(model)] = true
        elseif type(model) == 'number' then
            allowedHashes[model] = true
        end
    end

    local function loadCodex()
        allowedHashes, allowedNames, prefixes = {}, {}, {}
        local data = exports[CORE]:GetData('era_vehicles')
        if type(data) ~= 'table' then data = {} end

        local categories = data.categories or {}
        for _, list in pairs(categories) do
            if type(list) == 'table' then
                for _, model in ipairs(list) do
                    addModel(model)
                end
            end
        end

        if type(data.allow) == 'table' then
            for _, model in ipairs(data.allow) do
                addModel(model)
            end
        end

        if type(data.prefixes) == 'table' then
            for _, prefix in ipairs(data.prefixes) do
                if type(prefix) == 'string' then
                    prefixes[prefix:lower()] = true
                end
            end
        end

        if next(allowedHashes) == nil then
            for _, fallback in ipairs({ 'btype', 'glendale', 'tornado' }) do
                addModel(fallback)
            end
        end

        local modelCount, prefixCount = 0, 0
        for _ in pairs(allowedNames) do modelCount = modelCount + 1 end
        for _ in pairs(prefixes) do prefixCount = prefixCount + 1 end
        ctx.log(('vehicle whitelist loaded (%d models, %d prefixes)'):format(modelCount, prefixCount))
    end

    local function hasPrefix(modelName)
        if type(modelName) ~= 'string' then return false end
        local lower = modelName:lower()
        for prefix in pairs(prefixes) do
            if lower:sub(1, #prefix) == prefix then
                return true
            end
        end
        return false
    end

    local function isVehicleAllowed(model)
        if model == nil then return false end
        if type(model) == 'string' then
            local lower = model:lower()
            if allowedNames[lower] or hasPrefix(lower) then
                return true
            end
            model = GetHashKey(model)
        end
        if type(model) == 'number' then
            return allowedHashes[model] == true
        end
        return false
    end

    local function describeModel(model)
        if type(model) == 'string' then return model end
        if type(model) ~= 'number' then return tostring(model) end
        local label = GetDisplayNameFromVehicleModel(model)
        if label and label ~= '' then return label end
        return ('hash:%s'):format(model)
    end

    local function audit(src)
        local total = 0
        for _ in pairs(allowedNames) do total = total + 1 end
        local prefixCount = 0
        for _ in pairs(prefixes) do prefixCount = prefixCount + 1 end
        local message = ('Era vehicles allowed: %d models (%d prefixes)'):format(total, prefixCount)
        if src and src > 0 then
            TriggerClientEvent('chat:addMessage', src, { args = { 'LA', message } })
        else
            print('[la_weather] ' .. message)
        end
        return message
    end

    loadCodex()

    ctx.registerEvent('la_core:dataRefreshed', function(name)
        if name == 'era_vehicles' then
            loadCodex()
        end
    end)

    AddEventHandler('entityCreating', function(entity)
        if GetEntityType(entity) ~= 2 then return end
        local model = GetEntityModel(entity)
        if not model or isVehicleAllowed(model) then return end

        local owner = NetworkGetEntityOwner(entity)
        local label = describeModel(model)
        local message = ('🚫 Era vehicle blocked: %s'):format(label)
        print('[la_weather][vehicles] ' .. message)
        if owner and owner > 0 then
            TriggerClientEvent('chat:addMessage', owner, { args = { 'LA', message } })
        end
        CancelEvent()
    end)

    ctx.registerAction('isAllowed', function(_, model)
        return isVehicleAllowed(model)
    end)

    ctx.registerAction('audit', function(src)
        return audit(src)
    end)

    ctx.registerAction('refresh', function()
        loadCodex()
        return true
    end)

    ctx.registerExport('IsVehicleAllowed', function(model)
        return isVehicleAllowed(model)
    end)

    ctx.registerNetEvent('la_weather:vehicles:audit', function()
        audit(source)
    end)

    ctx.registerCommand('la_audit_vehicles', function(src)
        audit(src)
    end, true)

    return {
        isAllowed = isVehicleAllowed,
        audit = audit
    }
end
