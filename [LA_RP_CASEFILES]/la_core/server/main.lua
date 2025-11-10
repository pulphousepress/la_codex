-- la_core/server/main.lua — core runtime, codex loader, exports
local RES = GetCurrentResourceName()
local CODEX = Config.CodexPath or 'la_codex'
local cache, manifest = {}, nil

local function emit(level, message)
  local msg = string.format('[la_core][%s] %s', level, message)
  if type(Config.logger) == 'function' then
    local ok, err = pcall(Config.logger, level, message, msg)
    if not ok then print('[la_core][warn] logger callback failed: '..tostring(err)) end
  else
    print(msg)
  end
  return msg
end

local function dbg(m) if Config.Debug then emit('dbg', m) end end

local function loadFrom(res, path)
  local src = LoadResourceFile(res, path)
  if not src then return nil, ('missing %s:%s'):format(res, path) end
  local fn, err = load(src, ('@@%s/%s'):format(res, path))
  if not fn then return nil, err end
  local ok, out = pcall(fn)
  if not ok then return nil, out end
  return out
end

local function ensureManifest()
  if manifest then return true end
  manifest = loadFrom(CODEX, 'manifest.lua')
  if not manifest or type(manifest.sets) ~= 'table' then
    emit('error', 'Cannot load codex manifest')
    return false
  end
  dbg(('codex v%s ready'):format(tostring(manifest.version)))
  return true
end

local function loadSet(name)
  if not ensureManifest() then return nil end
  local path = manifest.sets[name]
  if not path then return nil end
  return loadFrom(CODEX, path)
end

-- public exports
exports('GetVersion', function() return Config.Version or '0.0.0' end)
exports('PrintStatus', function()
  print(('[la_core] v%s, codex=%s'):format(Config.Version or '0.0.0', CODEX))
end)
exports('GetData', function(name)
  if not name then return nil end
  cache[name] = cache[name] or loadSet(name)
  return cache[name]
end)

-- status command
RegisterCommand(Config.StatusCommand or 'la_status', function(src)
  local v = exports[RES]:GetVersion()
  if src == 0 then
    print(('[la_core] v%s OK'):format(v))
  else
    TriggerClientEvent('chat:addMessage', src, { args = { 'LA', ('core %s ok'):format(v) } })
  end
end, false)

-- lifecycle
AddEventHandler('onResourceStart', function(r)
  if r ~= RES then return end
  exports[RES]:PrintStatus()
  TriggerEvent('la_core:ready')
end)
