-- la_weather/server/ped_gate.lua
-- Ped whitelist enforcement powered by la_core codex data.

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
        local data = exports[CORE]:GetData('era_peds')
        if type(data) ~= 'table' then data = {} end

        local groups = data.groups or {}
        for _, list in pairs(groups) do
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
            for _, fallback in ipairs({ 's_m_y_cop_01', 's_m_m_postal_01', 'a_f_y_vinewood_04' }) do
                addModel(fallback)
            end
        end

        local modelCount, prefixCount = 0, 0
        for _ in pairs(allowedNames) do modelCount = modelCount + 1 end
        for _ in pairs(prefixes) do prefixCount = prefixCount + 1 end
        ctx.log(('ped whitelist loaded (%d models, %d prefixes)'):format(modelCount, prefixCount))
    end

    local function hasPrefix(name)
        if type(name) ~= 'string' then return false end
        local lower = name:lower()
        for prefix in pairs(prefixes) do
            if lower:sub(1, #prefix) == prefix then
                return true
            end
        end
        return false
    end

    local function isPedAllowed(model)
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

    local function describe(model)
        if type(model) == 'string' then return model end
        if type(model) == 'number' then
            return ('hash:%s'):format(model)
        end
        return tostring(model)
    end

    local function audit(src)
        local total = 0
        for _ in pairs(allowedNames) do total = total + 1 end
        local prefixCount = 0
        for _ in pairs(prefixes) do prefixCount = prefixCount + 1 end
        local message = ('Era peds allowed: %d models (%d prefixes)'):format(total, prefixCount)
        if src and src > 0 then
            TriggerClientEvent('chat:addMessage', src, { args = { 'LA', message } })
        else
            print('[la_weather] ' .. message)
        end
        return message
    end

    loadCodex()

    ctx.registerEvent('la_core:dataRefreshed', function(name)
        if name == 'era_peds' then
            loadCodex()
        end
    end)

    AddEventHandler('entityCreating', function(entity)
        if GetEntityType(entity) ~= 1 then return end
        local model = GetEntityModel(entity)
        if not model or isPedAllowed(model) then return end

        local owner = NetworkGetEntityOwner(entity)
        local label = describe(model)
        local message = ('🚫 Era ped blocked: %s'):format(label)
        print('[la_weather][peds] ' .. message)
        if owner and owner > 0 then
            TriggerClientEvent('chat:addMessage', owner, { args = { 'LA', message } })
        end
        CancelEvent()
    end)

    ctx.registerAction('isAllowed', function(_, model)
        return isPedAllowed(model)
    end)

    ctx.registerAction('audit', function(src)
        return audit(src)
    end)

    ctx.registerAction('refresh', function()
        loadCodex()
        return true
    end)

    ctx.registerExport('IsPedAllowed', function(model)
        return isPedAllowed(model)
    end)

    ctx.registerNetEvent('la_weather:peds:audit', function()
        audit(source)
    end)

    ctx.registerCommand('la_audit_peds', function(src)
        audit(src)
    end, true)

    return {
        isAllowed = isPedAllowed,
        audit = audit
    }
end
