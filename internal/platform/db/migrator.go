package db

import (
	"log"

	"github.com/divrigili/pix2pi-SaaS/internal/identity/domain"
	"gorm.io/gorm"
)

func AutoMigrate(db *gorm.DB) {
	log.Println("🚀 Running AutoMigrate...")

	err := db.AutoMigrate(
		&domain.Tenant{},
		&domain.User{},
	)
	if err != nil {
		log.Fatal(err)
	}

	err = ApplyExistingCoreTenantRLSPolicies(db)
	if err != nil {
		log.Fatal(err)
	}

	log.Println("✅ AutoMigrate completed")
}
