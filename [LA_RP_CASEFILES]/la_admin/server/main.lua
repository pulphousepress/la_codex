CreateThread(function()
  if Config.Debug then print('[la_admin] server ready') end
  -- seed common categories
  exports['la_admin']:RegisterCategory('world',   'World',    10)
  exports['la_admin']:RegisterCategory('vehicles','Vehicles', 20)
  exports['la_admin']:RegisterCategory('peds',    'Peds',     30)
  exports['la_admin']:RegisterCategory('radio',   'Radio',    40)
  exports['la_admin']:RegisterCategory('global',  'Global',    5)
end)

-- optional debug command
RegisterCommand('la_admin_debug', function(src)
  local cats, acts = exports['la_admin']:GetActions()
  print(('[la_admin] cats=%d actions=%d'):format(
    (cats and #cats) or 0, (acts and (function(t) local n=0 for _ in pairs(t) do n=n+1 end return n end)(acts)) or 0))
end)
