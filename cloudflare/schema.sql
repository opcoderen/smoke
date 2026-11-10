CREATE TABLE IF NOT EXISTS smoke_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  local_date TEXT NOT NULL,
  smoked_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_smoke_logs_date ON smoke_logs (local_date);
CREATE INDEX IF NOT EXISTS idx_smoke_logs_smoked_at ON smoke_logs (smoked_at);
