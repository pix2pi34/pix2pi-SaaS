package db

import "database/sql"

// EnsureTenantTables: search_path tenant schema'ya set edildikten sonra çağrılmalı (tx üzerinde)
func EnsureTenantTables(tx *sql.Tx) error {
	_, err := tx.Exec(`
CREATE TABLE IF NOT EXISTS kernel_kv (
  k TEXT PRIMARY KEY,
  v TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
)`)
	return err
}
