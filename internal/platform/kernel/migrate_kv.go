package kernel

import "gorm.io/gorm"

func MigrateKV(tx *gorm.DB) error {
	return tx.AutoMigrate(&KernelKV{})
}
