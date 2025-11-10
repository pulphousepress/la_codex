CreateThread(function()
  -- simple weather set actions calling la_engine
  exports['la_admin']:RegisterAction({
    id = 'weather_extrasunny', label = 'Weather → EXTRASUNNY', cat = 'world',
    serverEvent = 'la_engine:weather:set', args = { name = 'EXTRASUNNY' }
  })
  exports['la_admin']:RegisterAction({
    id = 'weather_clear', label = 'Weather → CLEAR', cat = 'world',
    serverEvent = 'la_engine:weather:set', args = { name = 'CLEAR' }
  })
end)

-- la_engine side should listen to this and apply
RegisterNetEvent('la_engine:weather:set', function(src, args)
  local name = args and args.name or 'EXTRASUNNY'
  TriggerClientEvent('la_engine:weather:update', -1, name, nil, 10)
  print(('[la_admin] weather set to %s by %s'):format(name, src or 'console'))
end)
