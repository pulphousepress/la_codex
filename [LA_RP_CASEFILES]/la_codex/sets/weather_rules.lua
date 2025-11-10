-- Weather rules used by la_engine's weather controller.
-- Contains sync parameters and weighted patterns for random selection.
return {
    sync = {
        intervalMs   = 30000,
        default      = 'EXTRASUNNY',
        initialHour  = 9,
        timeScale    = 1.0
    },
    patterns = {
        { name = 'EXTRASUNNY', weight = 60 },
        { name = 'CLEAR',      weight = 20 },
        { name = 'CLOUDS',     weight = 10 },
        { name = 'OVERCAST',   weight = 5  },
        { name = 'RAIN',       weight = 3  },
        { name = 'THUNDER',    weight = 2  }
    },
    transitions = {
        { from = 'RAIN',     to = 'THUNDER', chance = 0.4 },
        { from = 'OVERCAST', to = 'CLOUDS',  chance = 0.3 },
        { from = 'CLOUDS',   to = 'CLEAR',   chance = 0.2 }
    }
}