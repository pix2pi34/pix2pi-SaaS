#!/bin/bash
set -e

echo "=== BACKUP ==="
TS="$(date +%Y%m%d_%H%M%S)"
cd ~/pix2pi/pix2pi-SaaS

cp cmd/service-watchdog/service_watchdog_main.go \
   cmd/service-watchdog/service_watchdog_main.go.bak_${TS}

echo "OK ✅ backup alindi -> cmd/service-watchdog/service_watchdog_main.go.bak_${TS}"

echo
echo "=== FULL REWRITE ==="

cat <<'GOEOF' > cmd/service-watchdog/service_watchdog_main.go
package main

import (
	"encoding/json"
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
	Services  []ServiceStatus `json:"services"`
	UpdatedAt string          `json:"updated_at"`
}

var (
	mu           sync.RWMutex
	current      StatusResponse
	stateStore   = map[string]ServiceState{}
	configPath   = "config/service_watchdog_services.json"
	checkEvery   = 10 * time.Second
	httpTimeout  = 2 * time.Second
	maxSamples   = 6
	flapWindow   = 5
	flapChanges  = 3
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
	if port == "" {
		port = "8090"
	}

	_ = http.ListenAndServe("127.0.0.1:"+port, nil)
}

func runChecks() {
	services := loadServices()

	var results []ServiceStatus
	now := time.Now().Format(time.RFC3339)

	for _, svc := range services {
		results = append(results, checkService(svc, now))
	}

	sort.Slice(results, func(i, j int) bool {
		return results[i].Name < results[j].Name
	})

	mu.Lock()
	current = StatusResponse{
		Services:  results,
		UpdatedAt: now,
	}
	mu.Unlock()
}

func loadServices() []ServiceConfig {
	b, err := os.ReadFile(configPath)
	if err != nil {
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

	var services []ServiceConfig
	if err := json.Unmarshal(b, &services); err != nil {
		return nil
	}
	return services
}

func checkService(svc ServiceConfig, now string) ServiceStatus {
	prev := stateStore[svc.Name]

	if svc.Method == "design" {
		st := prev
		st.LastStatus = "PLANNED"
		st.AvgResponseMS = 0
		st.RecentChecks = nil
		stateStore[svc.Name] = st

		return ServiceStatus{
			Name:       svc.Name,
			Status:     "PLANNED",
			Method:     "design",
			Detail:     svc.Target,
			ResponseMS: 0,
			CheckedAt:  now,
			State:      st,
		}
	}

	success, detail, ms := executeCheck(svc)

	status := deriveBaseStatus(success)

	st := prev
	st = appendSample(st, CheckSample{
		At:         now,
		Success:    success,
		ResponseMS: ms,
		Status:     status,
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

	finalStatus := decideAdvancedStatus(status, st)

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
		ms := time.Since(start).Milliseconds()
		hostPort := strings.TrimSpace(svc.Target)
		conn, err := netDialTimeout(hostPort, 1200*time.Millisecond)
		if err != nil {
			return false, hostPort, ms
		}
		_ = conn.Close()
		ms = time.Since(start).Milliseconds()
		return true, hostPort, ms

	default:
		return false, "unknown method", 0
	}
}

func deriveBaseStatus(success bool) string {
	if success {
		return "RUNNING"
	}
	return "STOPPED"
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

func isDegraded(st ServiceState) bool {
	if len(st.RecentChecks) == 0 {
		return false
	}

	last := st.RecentChecks[len(st.RecentChecks)-1]

	if last.ResponseMS > 200 {
		return true
	}

	if st.AvgResponseMS > 150 {
		return true
	}

	if hasLatencyTrendUp(st.RecentChecks) {
		return true
	}

	if hasLatencySpike(st.RecentChecks) {
		return true
	}

	return false
}

func hasLatencyTrendUp(samples []CheckSample) bool {
	okSamples := onlySuccessful(samples)
	if len(okSamples) < 3 {
		return false
	}

	n := len(okSamples)
	a := okSamples[n-3].ResponseMS
	b := okSamples[n-2].ResponseMS
	c := okSamples[n-1].ResponseMS

	return a < b && b < c && c >= 120
}

func hasLatencySpike(samples []CheckSample) bool {
	okSamples := onlySuccessful(samples)
	if len(okSamples) < 2 {
		return false
	}

	last := okSamples[len(okSamples)-1].ResponseMS
	avg := calcAvg(okSamples[:len(okSamples)-1])

	if avg <= 0 {
		return false
	}

	return last >= avg*3 && last >= 120
}

func isFlapping(samples []CheckSample) bool {
	if len(samples) < flapWindow {
		return false
	}

	window := samples[len(samples)-flapWindow:]
	changes := 0

	for i := 1; i < len(window); i++ {
		if window[i].Status != window[i-1].Status {
			changes++
		}
	}

	return changes >= flapChanges
}

func onlySuccessful(samples []CheckSample) []CheckSample {
	out := make([]CheckSample, 0, len(samples))
	for _, s := range samples {
		if s.Success {
			out = append(out, s)
		}
	}
	return out
}

func calcAvg(samples []CheckSample) int64 {
	if len(samples) == 0 {
		return 0
	}
	var total int64
	var count int64
	for _, s := range samples {
		if s.Success {
			total += s.ResponseMS
			count++
		}
	}
	if count == 0 {
		return 0
	}
	return total / count
}

func appendSample(st ServiceState, sample CheckSample) ServiceState {
	st.RecentChecks = append(st.RecentChecks, sample)
	if len(st.RecentChecks) > maxSamples {
		st.RecentChecks = st.RecentChecks[len(st.RecentChecks)-maxSamples:]
	}
	return st
}

func writeJSON(w http.ResponseWriter, code int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(payload)
}

type dummyConn interface {
	Close() error
}

func netDialTimeout(addr string, timeout time.Duration) (dummyConn, error) {
	return (&netDialer{}).DialTimeout("tcp", addr, timeout)
}
GOEOF

cat <<'GOEOF' > cmd/service-watchdog/net_compat.go
package main

import (
	"net"
	"time"
)

type netDialer struct{}

func (d *netDialer) DialTimeout(network, address string, timeout time.Duration) (net.Conn, error) {
	return net.DialTimeout(network, address, timeout)
}
GOEOF

echo "OK ✅ watchdog advanced state engine yazildi"
