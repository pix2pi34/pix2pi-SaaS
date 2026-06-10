package main

import (
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	cacheservice "github.com/divrigili/pix2pi-SaaS/internal/platform/cache/service"
)

type HealthResponse struct {
	OK      bool   `json:"ok"`
	Service string `json:"service"`
	Redis   string `json:"redis"`
	Addr    string `json:"addr"`
	Prefix  string `json:"prefix"`
}

type CacheSetResponse struct {
	OK         bool   `json:"ok"`
	TenantID   string `json:"tenant_id"`
	Entity     string `json:"entity"`
	Key        string `json:"key"`
	RawKey     string `json:"raw_key"`
	Value      string `json:"value"`
	TTLSeconds int    `json:"ttl_seconds"`
}

type CacheGetResponse struct {
	OK       bool   `json:"ok"`
	TenantID string `json:"tenant_id"`
	Entity   string `json:"entity"`
	Key      string `json:"key"`
	RawKey   string `json:"raw_key"`
	Value    string `json:"value"`
	Hit      bool   `json:"hit"`
}

type CacheDeleteResponse struct {
	OK       bool   `json:"ok"`
	TenantID string `json:"tenant_id"`
	Entity   string `json:"entity"`
	Key      string `json:"key"`
	RawKey   string `json:"raw_key"`
	Deleted  bool   `json:"deleted"`
}

func portGetir() string {
	port := os.Getenv("CACHE_PORT")
	if port == "" {
		return "9011"
	}
	return port
}

func main() {
	cacheSvc := cacheservice.NewRedisCacheServiceFromEnv()
	defer func() {
		if err := cacheSvc.Close(); err != nil {
			log.Printf("WARN cache close hatasi: %v\n", err)
		}
	}()

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		redisDurum := "down"

		if err := cacheSvc.Ping(); err == nil {
			redisDurum = "up"
		}

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(HealthResponse{
			OK:      redisDurum == "up",
			Service: "cache",
			Redis:   redisDurum,
			Addr:    cacheSvc.Addr(),
			Prefix:  cacheSvc.KeyPrefix(),
		})
	})

	http.HandleFunc("/cache/set", func(w http.ResponseWriter, r *http.Request) {
		tenantID := r.URL.Query().Get("tenant")
		entity := r.URL.Query().Get("entity")
		anahtar := r.URL.Query().Get("key")
		deger := r.URL.Query().Get("value")
		ttlStr := r.URL.Query().Get("ttl")

		if deger == "" {
			http.Error(w, "value zorunlu", http.StatusBadRequest)
			return
		}

		ttlSeconds := int(cacheSvc.DefaultTTL().Seconds())
		ttlDuration := time.Duration(0)

		if ttlStr != "" {
			n, err := strconv.Atoi(ttlStr)
			if err != nil || n <= 0 {
				http.Error(w, "ttl pozitif integer olmali", http.StatusBadRequest)
				return
			}
			ttlSeconds = n
			ttlDuration = time.Duration(n) * time.Second
		}

		rawKey, err := cacheSvc.RawKeyOlustur(tenantID, entity, anahtar)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		err = cacheSvc.Set(tenantID, entity, anahtar, deger, ttlDuration)
		if err != nil {
			http.Error(w, "redis set hatasi: "+err.Error(), http.StatusInternalServerError)
			return
		}

		log.Printf(
			"OK ✅ cache set | tenant=%s | entity=%s | key=%s | ttl=%d\n",
			tenantID,
			entity,
			anahtar,
			ttlSeconds,
		)

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(CacheSetResponse{
			OK:         true,
			TenantID:   tenantID,
			Entity:     entity,
			Key:        anahtar,
			RawKey:     rawKey,
			Value:      deger,
			TTLSeconds: ttlSeconds,
		})
	})

	http.HandleFunc("/cache/get", func(w http.ResponseWriter, r *http.Request) {
		tenantID := r.URL.Query().Get("tenant")
		entity := r.URL.Query().Get("entity")
		anahtar := r.URL.Query().Get("key")

		rawKey, err := cacheSvc.RawKeyOlustur(tenantID, entity, anahtar)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		deger, err := cacheSvc.Get(tenantID, entity, anahtar)
		if err != nil {
			if errors.Is(err, cacheservice.ErrCacheKeyBulunamadi) {
				w.Header().Set("Content-Type", "application/json")
				_ = json.NewEncoder(w).Encode(CacheGetResponse{
					OK:       true,
					TenantID: tenantID,
					Entity:   entity,
					Key:      anahtar,
					RawKey:   rawKey,
					Value:    "",
					Hit:      false,
				})
				return
			}

			http.Error(w, "redis get hatasi: "+err.Error(), http.StatusInternalServerError)
			return
		}

		log.Printf(
			"OK ✅ cache get | tenant=%s | entity=%s | key=%s\n",
			tenantID,
			entity,
			anahtar,
		)

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(CacheGetResponse{
			OK:       true,
			TenantID: tenantID,
			Entity:   entity,
			Key:      anahtar,
			RawKey:   rawKey,
			Value:    deger,
			Hit:      true,
		})
	})

	http.HandleFunc("/cache/delete", func(w http.ResponseWriter, r *http.Request) {
		tenantID := r.URL.Query().Get("tenant")
		entity := r.URL.Query().Get("entity")
		anahtar := r.URL.Query().Get("key")

		rawKey, err := cacheSvc.RawKeyOlustur(tenantID, entity, anahtar)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		err = cacheSvc.Delete(tenantID, entity, anahtar)
		if err != nil {
			http.Error(w, "redis delete hatasi: "+err.Error(), http.StatusInternalServerError)
			return
		}

		log.Printf(
			"OK ✅ cache delete | tenant=%s | entity=%s | key=%s\n",
			tenantID,
			entity,
			anahtar,
		)

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(CacheDeleteResponse{
			OK:       true,
			TenantID: tenantID,
			Entity:   entity,
			Key:      anahtar,
			RawKey:   rawKey,
			Deleted:  true,
		})
	})

	port := portGetir()

	log.Printf(
		"OK ✅ cache service basladi | port=%s | redis=%s | prefix=%s\n",
		port,
		cacheSvc.Addr(),
		cacheSvc.KeyPrefix(),
	)

	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Fatal(err)
	}
}
