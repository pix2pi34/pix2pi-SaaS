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
