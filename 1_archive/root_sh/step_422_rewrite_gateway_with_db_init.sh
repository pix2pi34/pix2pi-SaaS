#!/bin/bash
set -euo pipefail

echo "=== STEP 422B / REWRITE GATEWAY WITH DB INIT ==="

cat <<'INNER' > "$HOME/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go"
package main

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/kernel"
	query "github.com/divrigili/pix2pi-SaaS/internal/services/query_read_model"
)

func main() {
	log.Println("STEP ▶ API Gateway boot basladi")

	kernel.InitDB()
	log.Println("OK ✅ kernel.InitDB tamam")

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		_, _ = w.Write([]byte("Pix2pi API Gateway OK"))
	})

	http.HandleFunc("/api/query/users", func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if rec := recover(); rec != nil {
				log.Println("PANIC ❌:", rec)
				w.WriteHeader(http.StatusInternalServerError)
				_, _ = w.Write([]byte("panic oldu"))
			}
		}()

		svc := query.New()

		count, err := svc.GetUsers()
		if err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			_ = json.NewEncoder(w).Encode(map[string]interface{}{
				"status": "error",
				"error":  err.Error(),
			})
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(map[string]interface{}{
			"status":     "ok",
			"user_count": count,
		})
	})

	log.Println("🚀 Pix2pi API Gateway running on :9010")

	if err := http.ListenAndServe(":9010", nil); err != nil {
		log.Fatal(err)
	}
}
INNER

gofmt -w "$HOME/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go"

echo "OK ✅ gateway db init ile yeniden yazildi"
echo "=== STEP 422B TAMAM ✅ ==="
