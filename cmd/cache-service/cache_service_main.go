package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/redis/go-redis/v9"
)

type HealthResponse struct {
	OK      bool   `json:"ok"`
	Service string `json:"service"`
	Redis   string `json:"redis"`
}

type CacheSetResponse struct {
	OK    bool   `json:"ok"`
	Key   string `json:"key"`
	Value string `json:"value"`
	TTL   int    `json:"ttl"`
}

type CacheGetResponse struct {
	OK    bool   `json:"ok"`
	Key   string `json:"key"`
	Value string `json:"value"`
	Hit   bool   `json:"hit"`
}

func main() {
	ctx := context.Background()

	rdb := redis.NewClient(&redis.Options{
		Addr: "127.0.0.1:6379",
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		redisDurum := "down"

		if err := rdb.Ping(ctx).Err(); err == nil {
			redisDurum = "up"
		}

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(HealthResponse{
			OK:      redisDurum == "up",
			Service: "cache",
			Redis:   redisDurum,
		})
	})

	http.HandleFunc("/cache/set", func(w http.ResponseWriter, r *http.Request) {
		anahtar := r.URL.Query().Get("key")
		deger := r.URL.Query().Get("value")
		ttl := 60

		if anahtar == "" {
			http.Error(w, "key zorunlu", http.StatusBadRequest)
			return
		}

		if deger == "" {
			http.Error(w, "value zorunlu", http.StatusBadRequest)
			return
		}

		err := rdb.Set(ctx, anahtar, deger, time.Duration(ttl)*time.Second).Err()
		if err != nil {
			http.Error(w, "redis set hatasi: "+err.Error(), http.StatusInternalServerError)
			return
		}

		log.Printf("OK ✅ cache set | key=%s | value=%s | ttl=%d\n", anahtar, deger, ttl)

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(CacheSetResponse{
			OK:    true,
			Key:   anahtar,
			Value: deger,
			TTL:   ttl,
		})
	})

	http.HandleFunc("/cache/get", func(w http.ResponseWriter, r *http.Request) {
		anahtar := r.URL.Query().Get("key")
		if anahtar == "" {
			http.Error(w, "key zorunlu", http.StatusBadRequest)
			return
		}

		deger, err := rdb.Get(ctx, anahtar).Result()
		if err == redis.Nil {
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(CacheGetResponse{
				OK:    true,
				Key:   anahtar,
				Value: "",
				Hit:   false,
			})
			return
		}
		if err != nil {
			http.Error(w, "redis get hatasi: "+err.Error(), http.StatusInternalServerError)
			return
		}

		log.Printf("OK ✅ cache get | key=%s | value=%s\n", anahtar, deger)

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(CacheGetResponse{
			OK:    true,
			Key:   anahtar,
			Value: deger,
			Hit:   true,
		})
	})

	log.Println("OK ✅ cache service basladi | port=9011")

	err := http.ListenAndServe(":9011", nil)
	if err != nil {
		log.Fatal(err)
	}
}
