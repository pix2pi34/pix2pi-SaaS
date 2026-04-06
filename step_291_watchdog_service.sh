#!/bin/bash
set -e

BASE=~/pix2pi/pix2pi-SaaS

mkdir -p $BASE/cmd/service-watchdog
mkdir -p $BASE/config

cat <<'JSONEOF' > $BASE/config/service_watchdog_services.json
[
  {
    "name": "api_gateway",
    "port": 8080,
    "health_url": "http://127.0.0.1:8080/health"
  },
  {
    "name": "identity",
    "port": 9001,
    "health_url": "http://127.0.0.1:9001/health"
  },
  {
    "name": "auth",
    "port": 8082,
    "health_url": "http://127.0.0.1:8082/health"
  },
  {
    "name": "stock_service",
    "port": 8085,
    "health_url": ""
  },
  {
    "name": "accounting_service",
    "port": 8007,
    "health_url": ""
  },
  {
    "name": "reporting_service",
    "port": 8445,
    "health_url": ""
  },
  {
    "name": "service_discovery",
    "port": 6379,
    "health_url": ""
  },
  {
    "name": "query_read_model",
    "port": 8002,
    "health_url": ""
  },
  {
    "name": "nats",
    "port": 4222,
    "health_url": ""
  },
  {
    "name": "redis",
    "port": 6379,
    "health_url": ""
  },
  {
    "name": "nginx",
    "port": 80,
    "health_url": "http://127.0.0.1/health"
  }
]
JSONEOF

cat <<'GOEOF' > $BASE/cmd/service-watchdog/service_watchdog_main.go
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	monitor "github.com/divrigili/pix2pi-SaaS/internal/platform/monitor"
)

type Payload struct {
	UpdatedAt string                  `json:"updated_at"`
	Services  []monitor.ServiceStatus `json:"services"`
}

func main() {
	cfgPath := "/root/pix2pi/pix2pi-SaaS/config/service_watchdog_services.json"

	services, err := loadConfig(cfgPath)
	if err != nil {
		log.Fatalf("config okuma hatasi: %v", err)
	}

	checker := monitor.NewChecker(2 * time.Second)

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"ok":true,"service":"service_watchdog"}`))
	})

	http.HandleFunc("/status", func(w http.ResponseWriter, r *http.Request) {
		result := Payload{
			UpdatedAt: time.Now().UTC().Format(time.RFC3339),
			Services:  make([]monitor.ServiceStatus, 0, len(services)),
		}

		for _, svc := range services {
			result.Services = append(result.Services, checker.Check(svc))
		}

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(result)
	})

	log.Println("OK ✅ service watchdog basladi :9016")
	log.Fatal(http.ListenAndServe(":9016", nil))
}

func loadConfig(path string) ([]monitor.ServiceCheck, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var items []monitor.ServiceCheck
	if err := json.Unmarshal(b, &items); err != nil {
		return nil, err
	}

	return items, nil
}
GOEOF

cd $BASE
go test ./internal/platform/monitor -v
go build ./cmd/service-watchdog

echo "OK ✅ watchdog service hazir"
