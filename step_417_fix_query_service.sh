#!/bin/bash
set -euo pipefail

echo "=== STEP 417B / FIX QUERY SERVICE ==="

cat <<'INNER' > "$HOME/pix2pi/pix2pi-SaaS/internal/services/query_read_model/service.go"
package query_read_model

import (
	"log"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/kernel"
)

type Service struct{}

func New() *Service {
	return &Service{}
}

// GetUsers read DB uzerinden users tablosu count ceker.
func (s *Service) GetUsers() (int64, error) {
	db := kernel.GetReadDB()

	var count int64
	err := db.Table("users").Count(&count).Error
	if err != nil {
		log.Println("read error:", err)
		return 0, err
	}

	log.Println("OK ✅ read db calisti, user count:", count)
	return count, nil
}
INNER

gofmt -w "$HOME/pix2pi/pix2pi-SaaS/internal/services/query_read_model/service.go"

echo "OK ✅ service duzeltildi"
echo "=== STEP 417B TAMAM ✅ ==="
