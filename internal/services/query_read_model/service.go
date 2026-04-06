package query_read_model

import (
	"errors"
	"log"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/kernel"
)

type Service struct{}

func New() *Service {
	return &Service{}
}

func (s *Service) GetUsers() (int64, error) {
	log.Println("DEBUG ▶ GetUsers basladi")

	db := kernel.GetReadDB()

	if db == nil {
		log.Println("ERROR ❌ read DB nil")
		return 0, errors.New("read db nil")
	}

	log.Println("DEBUG ▶ db baglantisi OK")

	var count int64
	err := db.Table("users").Count(&count).Error
	if err != nil {
		log.Println("ERROR ❌ db query:", err)
		return 0, err
	}

	log.Println("OK ✅ user count:", count)
	return count, nil
}
