-- la_core/client/main.lua — minimal client helper
local initialized = false

local function dbg(msg)
  if Config and Config.Debug then
    print('[la_core][client] '..msg)
  end
end

local function validateOptions(opts)
  if opts == nil then return true end
  if type(opts) ~= 'table' then return false, 'expected table' end
  if opts.StatusCommand and type(opts.StatusCommand) ~= 'string' then
    return false, 'StatusCommand must be string'
  end
  return true
end

local function mergeConfig(opts)
  if type(opts) ~= 'table' then return end
  for k,v in pairs(opts) do Config[k] = v end
end

CoreClient = {} -- optional global for other resources (no exports needed here)

function CoreClient.init(opts)
  if initialized then
    return { ok = true, alreadyInitialized = true }
  end
  local ok, err = validateOptions(opts)
  if not ok then return { ok = false, err = err } end
  mergeConfig(opts)

  local cmd = Config.StatusCommand or 'la_status'
  RegisterCommand(cmd, function()
    print('[la_core] Active=true')
  end, false)

  initialized = true
  dbg('client helper ready')
  return { ok = true, command = cmd }
end

-- auto-init with current Config
CreateThread(function()
  Wait(200)
  CoreClient.init({})
end)
