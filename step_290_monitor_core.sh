#!/bin/bash
set -e

BASE=~/pix2pi/pix2pi-SaaS

mkdir -p $BASE/internal/platform/monitor

cat <<'GOEOF' > $BASE/internal/platform/monitor/monitor.go
package monitor

import (
	"net"
	"net/http"
	"time"
)

type ServiceCheck struct {
	Name      string `json:"name"`
	Port      int    `json:"port"`
	HealthURL string `json:"health_url"`
}

type ServiceStatus struct {
	Name       string `json:"name"`
	Status     string `json:"status"`
	Method     string `json:"method"`
	Detail      string `json:"detail"`
	CheckedAt  string `json:"checked_at"`
	ResponseMS int64  `json:"response_ms"`
}

type Checker struct {
	Client *http.Client
}

func NewChecker(timeout time.Duration) *Checker {
	return &Checker{
		Client: &http.Client{Timeout: timeout},
	}
}

func (c *Checker) Check(s ServiceCheck) ServiceStatus {
	now := time.Now().UTC().Format(time.RFC3339)

	if s.HealthURL != "" {
		start := time.Now()
		resp, err := c.Client.Get(s.HealthURL)
		elapsed := time.Since(start).Milliseconds()

		if err == nil && resp != nil {
			defer resp.Body.Close()
			if resp.StatusCode >= 200 && resp.StatusCode < 300 {
				return ServiceStatus{
					Name:       s.Name,
					Status:     "RUNNING",
					Method:     "health",
					Detail:     resp.Status,
					CheckedAt:  now,
					ResponseMS: elapsed,
				}
			}

			return ServiceStatus{
				Name:       s.Name,
				Status:     "STOPPED",
				Method:     "health",
				Detail:     resp.Status,
				CheckedAt:  now,
				ResponseMS: elapsed,
			}
		}
	}

	address := net.JoinHostPort("127.0.0.1", intToString(s.Port))
	start := time.Now()
	conn, err := net.DialTimeout("tcp", address, 1500*time.Millisecond)
	elapsed := time.Since(start).Milliseconds()

	if err == nil {
		_ = conn.Close()
		return ServiceStatus{
			Name:       s.Name,
			Status:     "RUNNING",
			Method:     "port",
			Detail:     address,
			CheckedAt:  now,
			ResponseMS: elapsed,
		}
	}

	return ServiceStatus{
		Name:       s.Name,
		Status:     "STOPPED",
		Method:     "port",
		Detail:     address,
		CheckedAt:  now,
		ResponseMS: elapsed,
	}
}

func intToString(v int) string {
	if v == 0 {
		return "0"
	}

	buf := [20]byte{}
	i := len(buf)
	n := v

	for n > 0 {
		i--
		buf[i] = byte('0' + n%10)
		n /= 10
	}

	return string(buf[i:])
}
GOEOF

cat <<'GOEOF' > $BASE/internal/platform/monitor/monitor_test.go
package monitor

import (
	"net"
	"net/http"
	"testing"
	"time"
)

func TestCheck_PortRunning(t *testing.T) {
	ln, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen hatasi: %v", err)
	}
	defer ln.Close()

	port := ln.Addr().(*net.TCPAddr).Port

	c := NewChecker(2 * time.Second)
	res := c.Check(ServiceCheck{
		Name: "test-port",
		Port: port,
	})

	if res.Status != "RUNNING" {
		t.Fatalf("beklenen RUNNING, gelen=%s", res.Status)
	}

	if res.Method != "port" {
		t.Fatalf("beklenen port method, gelen=%s", res.Method)
	}
}

func TestCheck_PortStopped(t *testing.T) {
	c := NewChecker(500 * time.Millisecond)
	res := c.Check(ServiceCheck{
		Name: "test-port-down",
		Port: 6553,
	})

	if res.Status != "STOPPED" {
		t.Fatalf("beklenen STOPPED, gelen=%s", res.Status)
	}
}

func TestCheck_HealthRunning(t *testing.T) {
	mux := http.NewServeMux()
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"ok":true}`))
	})

	srv := &http.Server{
		Addr:    "127.0.0.1:18091",
		Handler: mux,
	}

	go func() {
		_ = srv.ListenAndServe()
	}()
	defer func() {
		_ = srv.Close()
	}()

	time.Sleep(100 * time.Millisecond)

	c := NewChecker(2 * time.Second)
	res := c.Check(ServiceCheck{
		Name:      "test-health",
		Port:      18091,
		HealthURL: "http://127.0.0.1:18091/health",
	})

	if res.Status != "RUNNING" {
		t.Fatalf("beklenen RUNNING, gelen=%s", res.Status)
	}

	if res.Method != "health" {
		t.Fatalf("beklenen health method, gelen=%s", res.Method)
	}
}
GOEOF

cd $BASE
go test ./internal/platform/monitor -v

echo "OK ✅ monitor core hazir"
