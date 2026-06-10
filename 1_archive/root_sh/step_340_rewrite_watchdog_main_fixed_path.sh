#!/bin/bash
set -e

FILE=~/pix2pi/pix2pi-SaaS/cmd/service-watchdog/service_watchdog_main.go
BACKUP="${FILE}.bak_$(date +%Y%m%d_%H%M%S)"

echo "1. backup aliniyor..."
cp "$FILE" "$BACKUP"
echo "OK ✅ backup: $BACKUP"

echo
echo "2. watchdog main dosyasi yeniden yaziliyor..."

cat <<'GOEOF' > "$FILE"
package main

import (
	"encoding/json"
	"net"
	"net/http"
	"os"
	"sort"
	"strings"
	"sync"
	"time"
)

type ServiceConfig struct {
	Name   string `json:"name"`
	Method string `json:"method"`
	Target string `json:"target"`
}

type CheckSample struct {
	At         string `json:"at"`
	Success    bool   `json:"success"`
	ResponseMS int64  `json:"response_ms"`
	Status     string `json:"status"`
}

type ServiceState struct {
	LastStatus           string        `json:"last_status"`
	LastSuccessAt        string        `json:"last_success_at"`
	LastFailureAt        string        `json:"last_failure_at"`
	ConsecutiveFailures  int           `json:"consecutive_failures"`
	ConsecutiveSuccesses int           `json:"consecutive_successes"`
	AvgResponseMS        int64         `json:"avg_response_ms"`
	RecentChecks         []CheckSample `json:"recent_checks"`
}

type ServiceStatus struct {
	Name       string       `json:"name"`
	Status     string       `json:"status"`
	Method     string       `json:"method"`
	Detail     string       `json:"detail"`
	ResponseMS int64        `json:"response_ms"`
	CheckedAt  string       `json:"checked_at"`
	State      ServiceState `json:"state"`
}

type StatusResponse struct {
	Services     []ServiceStatus `json:"services"`
	UpdatedAt    string          `json:"updated_at"`
	GlobalStatus string          `json:"global_status"`
}

var (
	mu          sync.RWMutex
	current     StatusResponse
	stateStore  = map[string]ServiceState{}
	configPath  = "config/service_watchdog_services.json"
	checkEvery  = 10 * time.Second
	httpTimeout = 2 * time.Second
	maxSamples  = 6
)

func main() {
	runChecks()

	go func() {
		ticker := time.NewTicker(checkEvery)
		defer ticker.Stop()
		for range ticker.C {
			runChecks()
		}
	}()

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{
			"ok": true,
		})
	})

	http.HandleFunc("/status", func(w http.ResponseWriter, r *http.Request) {
		mu.RLock()
		defer mu.RUnlock()
		writeJSON(w, http.StatusOK, current)
	})

	port := os.Getenv("PIX2PI_WATCHDOG_PORT")
	if strings.TrimSpace(port) == "" {
		port = "8090"
	}

	_ = http.ListenAndServe("127.0.0.1:"+port, nil)
}

func runChecks() {
	services := loadServices()
	results := make([]ServiceStatus, 0, len(services))
	now := time.Now().Format(time.RFC3339)

	for _, svc := range services {
		results = append(results, checkService(svc, now))
	}

	sort.Slice(results, func(i, j int) bool {
		return results[i].Name < results[j].Name
	})

	global := computeGlobalStatus(results)

	mu.Lock()
	current = StatusResponse{
		Services:     results,
		UpdatedAt:    now,
		GlobalStatus: global,
	}
	mu.Unlock()
}

func loadServices() []ServiceConfig {
	b, err := os.ReadFile(configPath)
	if err != nil {
		return defaultServices()
	}

	var services []ServiceConfig
	if err := json.Unmarshal(b, &services); err != nil {
		return defaultServices()
	}

	return services
}

func defaultServices() []ServiceConfig {
	return []ServiceConfig{
		{Name: "api_gateway", Method: "health", Target: "http://127.0.0.1:8080/health"},
		{Name: "identity", Method: "health", Target: "http://127.0.0.1:9001/health"},
		{Name: "accounting_service", Method: "port", Target: "127.0.0.1:8007"},
	}
}

func checkService(svc ServiceConfig, now string) ServiceStatus {
	success, detail, ms := executeCheck(svc)

	status := "RUNNING"
	if !success {
		status = "STOPPED"
	}

	return ServiceStatus{
		Name:       svc.Name,
		Status:     status,
		Method:     svc.Method,
		Detail:     detail,
		ResponseMS: ms,
		CheckedAt:  now,
	}
}

func executeCheck(svc ServiceConfig) (bool, string, int64) {
	start := time.Now()

	if svc.Method == "health" {
		client := &http.Client{Timeout: httpTimeout}
		resp, err := client.Get(svc.Target)
		ms := time.Since(start).Milliseconds()

		if err != nil {
			return false, svc.Target, ms
		}
		defer resp.Body.Close()

		if resp.StatusCode >= 200 && resp.StatusCode < 300 {
			return true, svc.Target, ms
		}
		return false, svc.Target, ms
	}

	conn, err := net.DialTimeout("tcp", svc.Target, 1*time.Second)
	ms := time.Since(start).Milliseconds()

	if err != nil {
		return false, svc.Target, ms
	}
	conn.Close()

	return true, svc.Target, ms
}

func computeGlobalStatus(services []ServiceStatus) string {
	for _, s := range services {
		if s.Status == "STOPPED" {
			return "CRITICAL"
		}
	}
	return "RUNNING"
}

func writeJSON(w http.ResponseWriter, code int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(payload)
}
GOEOF

echo "OK ✅ dosya yazildi"

echo
echo "3. build..."
cd ~/pix2pi/pix2pi-SaaS
go build -o bin/service-watchdog ./cmd/service-watchdog

echo
echo "4. restart..."
systemctl restart pix2pi-watchdog
sleep 2

echo
echo "5. test..."
curl http://127.0.0.1:8090/status

echo
echo "OK ✅ TAMAM"
