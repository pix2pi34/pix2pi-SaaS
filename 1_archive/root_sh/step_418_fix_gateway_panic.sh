#!/bin/bash
set -euo pipefail

echo "=== STEP 418B / PANIC PROTECTION ==="

FILE="$HOME/pix2pi/pix2pi-SaaS/cmd/api-gateway/api_gateway_main.go"

cp "$FILE" "$FILE.bak_$(date +%s)"

# handler içine recover ekle
sed -i '/http.HandleFunc("\/api\/query\/users"/,/})/c\
	http.HandleFunc("/api/query/users", func(w http.ResponseWriter, r *http.Request) {\
		defer func() {\
			if rec := recover(); rec != nil {\
				log.Println("PANIC ❌:", rec)\
				w.WriteHeader(http.StatusInternalServerError)\
				w.Write([]byte("panic oldu"))\
			}\
		}()\
\
		svc := query.New()\
\
		count, err := svc.GetUsers()\
		if err != nil {\
			w.Header().Set("Content-Type", "application/json")\
			w.WriteHeader(http.StatusInternalServerError)\
			json.NewEncoder(w).Encode(map[string]interface{}{\
				"status": "error",\
				"error": err.Error(),\
			})\
			return\
		}\
\
		w.Header().Set("Content-Type", "application/json")\
		w.WriteHeader(http.StatusOK)\
		json.NewEncoder(w).Encode(map[string]interface{}{\
			"status": "ok",\
			"user_count": count,\
		})\
	})' "$FILE"

gofmt -w "$FILE"

echo "OK ✅ panic protection eklendi"
echo "=== STEP 418B TAMAM ✅ ==="
