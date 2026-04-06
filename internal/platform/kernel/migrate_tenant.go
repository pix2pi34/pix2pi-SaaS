package kernel

import (
	"fmt"

	"gorm.io/gorm"
)

func EnsureTenantSchema(db *gorm.DB, schema string) error {
	q := fmt.Sprintf(`CREATE SCHEMA IF NOT EXISTS "%s"`, schema)
	return db.Exec(q).Error
}

func PrepareTenant(db *gorm.DB, schema string) error {
	tx := db.Begin()
	if tx.Error != nil {
		return tx.Error
	}

	// aynı connection üzerinde tenant schema
	if err := tx.Exec(fmt.Sprintf(`SET LOCAL search_path TO "%s", public`, schema)).Error; err != nil {
		_ = tx.Rollback()
		return err
	}

	if err := MigrateKV(tx); err != nil {
		_ = tx.Rollback()
		return err
	}

	return tx.Commit().Error
}
