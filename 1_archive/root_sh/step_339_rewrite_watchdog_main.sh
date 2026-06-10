#!/bin/bash
set -e

FILE="/pix2pi/pix2pi-SaaS/cmd/service-watchdog/service_watchdog_main.go"
BACKUP="${FILE}.bak_$(date +%Y%m%d_%H%M%S)"

echo "1. backup aliniyor..."
cp "$FILE" "$BACKUP"
echo "OK ✅ backup: $BACKUP"

echo
echo "2. watchdog main dosyasi komple yeniden yaziliyor..."

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
	configPath  = "/pix2pi/pix2pi-SaaS/config/service_watchdog_services.json"
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
			"ok":      true,
			"service": "watchdog",
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

	if len(services) == 0 {
		return defaultServices()
	}

	return services
}

func defaultServices() []ServiceConfig {
	return []ServiceConfig{
		{Name: "api_gateway", Method: "health", Target: "http://127.0.0.1:8080/health"},
		{Name: "identity", Method: "health", Target: "http://127.0.0.1:9001/health"},
		{Name: "accounting_service", Method: "port", Target: "127.0.0.1:8007"},
		{Name: "reporting_service", Method: "port", Target: "127.0.0.1:8445"},
		{Name: "service_discovery", Method: "port", Target: "127.0.0.1:6379"},
		{Name: "query_read_model", Method: "port", Target: "127.0.0.1:8002"},
		{Name: "nats", Method: "port", Target: "127.0.0.1:4222"},
		{Name: "redis", Method: "port", Target: "127.0.0.1:6379"},
		{Name: "nginx", Method: "port", Target: "127.0.0.1:8099"},
		{Name: "auth", Method: "design", Target: "not active"},
		{Name: "stock_service", Method: "design", Target: "not active"},
	}
}

func checkService(svc ServiceConfig, now string) ServiceStatus {
	prev := stateStore[svc.Name]

	if svc.Method == "design" {
		prev.LastStatus = "PLANNED"
		prev.AvgResponseMS = 0
		prev.RecentChecks = nil
		stateStore[svc.Name] = prev

		return ServiceStatus{
			Name:       svc.Name,
			Status:     "PLANNED",
			Method:     "design",
			Detail:     svc.Target,
			ResponseMS: 0,
			CheckedAt:  now,
			State:      prev,
		}
	}

	success, detail, ms := executeCheck(svc)

	st := prev
	baseStatus := "RUNNING"
	if !success {
		baseStatus = "STOPPED"
	}

	st = appendSample(st, CheckSample{
		At:         now,
		Success:    success,
		ResponseMS: ms,
		Status:     baseStatus,
	})

	if success {
		st.LastSuccessAt = now
		st.ConsecutiveSuccesses++
		st.ConsecutiveFailures = 0
	} else {
		st.LastFailureAt = now
		st.ConsecutiveFailures++
		st.ConsecutiveSuccesses = 0
	}

	st.AvgResponseMS = calcAvg(st.RecentChecks)

	finalStatus := decideAdvancedStatus(baseStatus, st)
	st.LastStatus = finalStatus
	stateStore[svc.Name] = st

	return ServiceStatus{
		Name:       svc.Name,
		Status:     finalStatus,
		Method:     svc.Method,
		Detail:     detail,
		ResponseMS: ms,
		CheckedAt:  now,
		State:      st,
	}
}

func executeCheck(svc ServiceConfig) (bool, string, int64) {
	start := time.Now()

	switch svc.Method {
	case "health":
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

	case "port":
		conn, err := net.DialTimeout("tcp", strings.TrimSpace(svc.Target), 1200*time.Millisecond)
		ms := time.Since(start).Milliseconds()
		if err != nil {
			return false, svc.Target, ms
		}
		_ = conn.Close()
		return true, svc.Target, ms

	default:
		return false, "unknown method", 0
	}
}

func decideAdvancedStatus(base string, st ServiceState) string {
	if base == "STOPPED" {
		return "STOPPED"
	}

	if isFlapping(st.RecentChecks) {
		return "FLAPPING"
	}

	if isDegraded(st) {
		return "DEGRADED"
	}

	return "RUNNING"
}

func isFlapping(samples []CheckSample) bool {
	if len(samples) < 4 {
		return false
	}

	changes := 0
	for i := 1; i < len(samples); i++ {
		if samples[i].Success != samples[i-1].Success {
			changes++
		}
	}

	return changes >= 3
}

func isDegraded(st ServiceState) bool {
	if len(st.RecentChecks) == 0 {
		return false
	}

	failCount := 0
	for _, s := range st.RecentChecks {
		if !s.Success {
			failCount++
		}
	}

	if failCount > 0 && st.LastStatus == "RUNNING" {
		return true
	}

	if st.AvgResponseMS >= 1500 {
		return true
	}

	return false
}

func computeGlobalStatus(services []ServiceStatus) string {
	hasStopped := false
	hasDegraded := false
	hasFlapping := false

	for _, s := range services {
		switch s.Status {
		case "STOPPED":
			hasStopped = true
		case "DEGRADED":
			hasDegraded = true
		case "FLAPPING":
			hasFlapping = true
		}
	}

	if hasStopped {
		return "CRITICAL"
	}
	if hasFlapping {
		return "FLAPPING"
	}
	if hasDegraded {
		return "DEGRADED"
	}
	return "RUNNING"
}

func appendSample(st ServiceState, sample CheckSample) ServiceState {
	st.RecentChecks = append(st.RecentChecks, sample)
	if len(st.RecentChecks) > maxSamples {
		st.RecentChecks = st.RecentChecks[len(st.RecentChecks)-maxSamples:]
	}
	return st
}

func calcAvg(samples []CheckSample) int64 {
	if len(samples) == 0 {
		return 0
	}

	var total int64
	for _, s := range samples {
		total += s.ResponseMS
	}
	return total / int64(len(samples))
}

func writeJSON(w http.ResponseWriter, code int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(payload)
}
GOEOF

echo "OK ✅ dosya yeniden yazildi"
echo
echo "3. gofmt..."
gofmt -w "$FILE"
echo "OK ✅ gofmt tamam"

echo
echo "4. build..."
cd /pix2pi/pix2pi-SaaS
go build -o bin/service-watchdog ./cmd/service-watchdog
echo "OK ✅ build tamam"

echo
echo "5. watchdog restart..."
systemctl restart pix2pi-watchdog
sleep 2
echo "OK ✅ restart tamam"

echo
echo "6. status test..."
curl -s http://127.0.0.1:8090/status
echo
echo "OK ✅ watchdog temiz rewrite bitti"
