-- Example schema placeholder
-- This file can be copied and modified for each dataset you add to the codex.
-- It must return a function that takes a data table and returns (ok:boolean, errs:table).
return function(data)
    if type(data) ~= 'table' then
        return false, { 'Data must be a table' }
    end
    return true, {}
end