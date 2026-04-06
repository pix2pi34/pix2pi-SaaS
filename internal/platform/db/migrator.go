package db

import (
	"log"

	"gorm.io/gorm"

	"github.com/divrigili/pix2pi-SaaS/internal/identity/domain"
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

	log.Println("✅ AutoMigrate completed")
}
