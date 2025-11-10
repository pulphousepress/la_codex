-- la_weather/server/main.lua
-- Module bootstrapper and action registry for Los Animales RP.

local RESOURCE = GetCurrentResourceName()

local orderedModules = {
    { key = 'weather', script = 'weather_controller' },
    { key = 'vehicles', script = 'era_vehicles' },
    { key = 'peds',     script = 'ped_gate' }
}

local registry, actions = {}, {}

local function log(level, message)
    print(('[%s][%s] %s'):format(RESOURCE, level, message))
end

local function dbg(message)
    if Config and Config.Debug then
        log('dbg', message)
    end
end

local function registerAction(moduleName, actionName, handler)
    if type(moduleName) ~= 'string' or type(actionName) ~= 'string' then return end
    if type(handler) ~= 'function' then return end
    actions[moduleName] = actions[moduleName] or {}
    actions[moduleName][actionName] = handler
    dbg(('action registered %s:%s'):format(moduleName, actionName))
end

local function safeInvoke(handler, ...)
    local ok, result = pcall(handler, ...)
    if not ok then
        log('error', result)
        return false, result
    end
    return true, result
end

local function callAction(moduleName, actionName, ...)
    local moduleActions = actions[moduleName]
    if not moduleActions then
        return nil, ('module %s is not registered'):format(tostring(moduleName))
    end
    local handler = moduleActions[actionName]
    if type(handler) ~= 'function' then
        return nil, ('action %s missing for module %s'):format(tostring(actionName), tostring(moduleName))
    end
    local ok, result = safeInvoke(handler, ...)
    if not ok then
        return nil, result
    end
    return result
end

local function createContext(moduleName)
    return {
        name = moduleName,
        log = function(message)
            dbg(('%s %s'):format(moduleName, message))
        end,
        registerAction = function(actionName, handler)
            registerAction(moduleName, actionName, handler)
        end,
        registerExport = function(exportName, handler)
            if type(exportName) ~= 'string' or type(handler) ~= 'function' then return end
            exports(exportName, handler)
            dbg(('export registered %s'):format(exportName))
        end,
        registerNetEvent = function(eventName, handler)
            if type(eventName) ~= 'string' or type(handler) ~= 'function' then return end
            RegisterNetEvent(eventName)
            AddEventHandler(eventName, function(...)
                local ok, err = safeInvoke(handler, ...)
                if not ok then
                    log('error', ('event %s handler failed: %s'):format(eventName, err))
                end
            end)
        end,
        registerEvent = function(eventName, handler)
            if type(eventName) ~= 'string' or type(handler) ~= 'function' then return end
            AddEventHandler(eventName, function(...)
                local ok, err = safeInvoke(handler, ...)
                if not ok then
                    log('error', ('event %s handler failed: %s'):format(eventName, err))
                end
            end)
        end,
        registerCommand = function(commandName, handler, restricted)
            if type(commandName) ~= 'string' or type(handler) ~= 'function' then return end
            RegisterCommand(commandName, function(src, args, raw)
                local ok, err = safeInvoke(handler, src, args, raw)
                if not ok then
                    log('error', ('command %s failed: %s'):format(commandName, err))
                end
            end, restricted or false)
        end,
        invoke = function(targetModule, actionName, ...)
            return callAction(targetModule, actionName, ...)
        end
    }
end

local function loadModule(moduleName, scriptName)
    local path = ('server/%s.lua'):format(scriptName)
    local chunk = LoadResourceFile(RESOURCE, path)
    if not chunk then
        log('error', ('missing module script %s'):format(path))
        return
    end

    local fn, err = load(chunk, ('@@%s/%s'):format(RESOURCE, path), 't')
    if not fn then
        log('error', ('compile error in %s: %s'):format(path, err))
        return
    end

    local ok, factory = pcall(fn)
    if not ok then
        log('error', ('runtime error while loading %s: %s'):format(path, factory))
        return
    end

    if type(factory) ~= 'function' then
        log('warn', ('module %s did not return an initializer function'):format(moduleName))
        return
    end

    local ctx = createContext(moduleName)
    local initOk, state = pcall(factory, ctx)
    if not initOk then
        log('error', ('initializer for %s failed: %s'):format(moduleName, state))
        return
    end

    registry[moduleName] = { context = ctx, state = state }
    dbg(('module %s loaded'):format(moduleName))
end

for _, entry in ipairs(orderedModules) do
    loadModule(entry.key, entry.script)
end

exports('CallAction', function(moduleName, actionName, ...)
    return callAction(moduleName, actionName, ...)
end)

exports('GetModuleState', function(moduleName)
    local record = registry[moduleName]
    return record and record.state or nil
end)

exports('RegisterAddonAction', function(actionName, handler)
    registerAction('addons', actionName, handler)
end)

exports('CallAddonAction', function(actionName, ...)
    return callAction('addons', actionName, ...)
end)

RegisterNetEvent('la_weather:action')
AddEventHandler('la_weather:action', function(moduleName, actionName, ...)
    local src = source
    if type(moduleName) ~= 'string' or type(actionName) ~= 'string' then return end
    local moduleActions = actions[moduleName]
    if not moduleActions then
        dbg(('net action ignored (module %s not registered)'):format(moduleName))
        return
    end

    local handler = moduleActions[actionName]
    if type(handler) ~= 'function' then
        dbg(('net action ignored (handler %s missing)'):format(actionName))
        return
    end

    local ok, err = safeInvoke(handler, src, ...)
    if not ok then
        log('error', ('net action %s:%s failed: %s'):format(moduleName, actionName, err))
    end
end)

TriggerEvent('la_weather:registryReady', registry)
