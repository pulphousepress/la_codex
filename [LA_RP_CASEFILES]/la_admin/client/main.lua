local PANEL = { open = false }

local function toggle()
  PANEL.open = not PANEL.open
  -- if you wire NUI later:
  -- SetNuiFocus(PANEL.open, PANEL.open)
  -- SendNUIMessage({ type = 'toggle', open = PANEL.open })
  if PANEL.open then
    TriggerServerEvent('la_admin:rpc:getActions')  -- request latest registry
  end
end

-- keybind
RegisterKeyMapping('la_admin_toggle', 'Toggle LA Admin', 'keyboard', Config.ToggleKey or 'F10')
RegisterCommand('la_admin_toggle', toggle, false)

-- chat fallback
RegisterCommand(Config.Command or 'la_admin', toggle, false)

-- receive actions and draw a simple fallback menu
local lastActions = {}
RegisterNetEvent('la_admin:rpc:actions', function(categories, actions)
  lastActions = actions or {}
  -- fallback: print menu to chat
  TriggerEvent('chat:addMessage', { args = {'LA', ('Admin actions loaded: %d'):format((function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end)(lastActions))}})
end)

-- simple text menu: /la_act <id>
RegisterCommand('la_act', function(_, args)
  local id = args[1]
  if not id or not lastActions[id] then
    print('[la_admin] usage: /la_act <actionId>')
    return
  end
  TriggerServerEvent('la_admin:invoke', id)
end, false)

CreateThread(function()
  if Config.Debug then print('[la_admin] client ready') end
end)
