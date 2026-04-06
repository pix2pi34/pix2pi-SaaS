#!/bin/bash
set -euo pipefail

echo "=== STEP 420 / FULL REWRITE API GATEWAY ==="

FILE="$HOME/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go"

cp "$FILE" "$FILE.bak_$(date +%s)"

cat <<'INNER' > "$FILE"
package main

import (
	"encoding/json"
	"log"
	"net/http"

	query "github.com/divrigili/pix2pi-SaaS/internal/services/query_read_model"
)

func main() {

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("Pix2pi API Gateway OK"))
	})

	http.HandleFunc("/api/query/users", func(w http.ResponseWriter, r *http.Request) {

		defer func() {
			if rec := recover(); rec != nil {
				log.Println("PANIC ❌:", rec)
				w.WriteHeader(http.StatusInternalServerError)
				w.Write([]byte("panic oldu"))
			}
		}()

		svc := query.New()

		count, err := svc.GetUsers()
		if err != nil {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"status": "error",
				"error":  err.Error(),
			})
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
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

gofmt -w "$FILE"

echo "OK ✅ temiz gateway yazildi"
echo "=== STEP 420 TAMAM ✅ ==="
