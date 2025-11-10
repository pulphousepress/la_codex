-- la_core/config.lua — shared (no require, no return)
Config = {
  Version      = '1.0.2',
  EnableCore   = true,
  Debug        = false,          -- set true for verbose logs
  StatusCommand= 'la_status',
  logger       = nil,            -- optional function(level, message, formatted)
  CodexPath    = 'la_codex',     -- resource holding codex datasets
  SyncToDB     = false           -- reserved
}
