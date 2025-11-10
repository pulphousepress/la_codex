CreateThread(function()
  exports['la_admin']:RegisterAction({
    id = 'era_gate_toggle', label = 'Vehicles → Toggle Era Gate', cat = 'vehicles',
    serverEvent = 'la_engine:era:toggle', args = {}
  })
end)

local ERA_ENABLED = true
RegisterNetEvent('la_engine:era:toggle', function(_, _)
  ERA_ENABLED = not ERA_ENABLED
  TriggerEvent('la_engine:era:setEnabled', ERA_ENABLED)
  print('[la_admin] era gate '..(ERA_ENABLED and 'ENABLED' or 'DISABLED'))
end)

-- your era module should subscribe to this:
AddEventHandler('la_engine:era:setEnabled', function(enabled)
  -- flip your era sweep loop on/off internally
  TriggerClientEvent('chat:addMessage', -1, { args={'LA', ('Era gate %s'):format(enabled and 'ON' or 'OFF')} })
end)
