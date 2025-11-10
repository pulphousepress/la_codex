-- central registry; no globals leaked
local REG = {
  categories = {},    -- id -> { id,label,order }
  actions = {}        -- id -> { id,label,cat,serverEvent,clientEvent,payloadBuilder }
}

local function isAllowed(src)
  if Config.AllowAnyoneInDev then return true end
  -- ACE: require admin group in prod
  return IsPlayerAceAllowed(src or -1, Config.AcePrincipal or 'group.admin')
end

-- Add or replace a category
exports('RegisterCategory', function(id, label, order)
  if type(id) ~= 'string' then return false, 'bad id' end
  REG.categories[id] = { id = id, label = label or id, order = order or 100 }
  return true
end)

-- Register an action
-- spec = { id,label,cat,serverEvent?,clientEvent?,args? (table) }
exports('RegisterAction', function(spec)
  if type(spec) ~= 'table' or type(spec.id) ~= 'string' then
    return false, 'bad spec'
  end
  REG.actions[spec.id] = {
    id = spec.id,
    label = spec.label or spec.id,
    cat = spec.cat or 'misc',
    serverEvent = spec.serverEvent,
    clientEvent = spec.clientEvent,
    args = spec.args
  }
  return true
end)

exports('GetActions', function()
  return REG.categories, REG.actions
end)

-- client asks for menu data
RegisterNetEvent('la_admin:rpc:getActions', function()
  local src = source
  if not isAllowed(src) then return end
  TriggerClientEvent('la_admin:rpc:actions', src, REG.categories, REG.actions)
end)

-- client invokes an action id
RegisterNetEvent('la_admin:invoke', function(actionId)
  local src = source
  if not isAllowed(src) then return end
  local a = REG.actions[actionId]
  if not a then return end
  if a.serverEvent then
    TriggerEvent(a.serverEvent, src, a.args)
  end
  if a.clientEvent then
    -- broadcast or self only depending on args.scope
    if a.args and a.args.scope == 'self' then
      TriggerClientEvent(a.clientEvent, src, a.args)
    else
      TriggerClientEvent(a.clientEvent, -1, a.args)
    end
  end
end)

return true
