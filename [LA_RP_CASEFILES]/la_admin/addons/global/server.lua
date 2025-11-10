CreateThread(function()
  exports['la_admin']:RegisterAction({
    id = 'resmon_toggle', label = 'Global → Toggle resmon', cat = 'global',
    clientEvent = 'la_admin:client:resmon', args = { scope='self' }
  })
end)

RegisterNetEvent('la_admin:client:resmon') -- client handled; args.scope='self'
