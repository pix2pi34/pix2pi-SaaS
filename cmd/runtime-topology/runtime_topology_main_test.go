package main

import "testing"

func TestNormalizePort(t *testing.T) {
	if got := normalizePort(":5960"); got != "5960" {
		t.Fatalf("beklenen 5960, gelen %s", got)
	}

	if got := normalizePort(""); got != "5960" {
		t.Fatalf("bos port default 5960 olmali, gelen %s", got)
	}
}

func TestParseLimit(t *testing.T) {
	if got := parseLimit("", 100, 300); got != 100 {
		t.Fatalf("default limit 100 olmali, gelen %d", got)
	}

	if got := parseLimit("500", 100, 300); got != 300 {
		t.Fatalf("max limit 300 olmali, gelen %d", got)
	}

	if got := parseLimit("abc", 100, 300); got != 100 {
		t.Fatalf("gecersiz limit default olmali, gelen %d", got)
	}
}

func TestTopologyStatus(t *testing.T) {
	okNodes := []TopologyNode{
		{NodeKey: "a", Status: "ok"},
		{NodeKey: "b", Status: "ok"},
	}

	if got := topologyStatus(okNodes); got != "ok" {
		t.Fatalf("beklenen ok, gelen %s", got)
	}

	degradedNodes := []TopologyNode{
		{NodeKey: "a", Status: "ok"},
		{NodeKey: "b", Status: "fail"},
	}

	if got := topologyStatus(degradedNodes); got != "degraded" {
		t.Fatalf("beklenen degraded, gelen %s", got)
	}
}

func TestLoadConfig_DefaultPort(t *testing.T) {
	t.Setenv("RUNTIME_TOPOLOGY_PORT", "")
	t.Setenv("DB_READ_DSN", "read-dsn")

	cfg := loadConfig()

	if cfg.Port != "5960" {
		t.Fatalf("beklenen port 5960, gelen %s", cfg.Port)
	}

	if cfg.DSN != "read-dsn" {
		t.Fatalf("beklenen read-dsn, gelen %s", cfg.DSN)
	}

	if len(cfg.Targets) < 10 {
		t.Fatalf("target sayisi beklenenden az: %d", len(cfg.Targets))
	}

	if len(cfg.Edges) == 0 {
		t.Fatalf("edge listesi bos olmamali")
	}
}

func TestLoadConfig_WriteFallback(t *testing.T) {
	t.Setenv("RUNTIME_TOPOLOGY_PORT", "5997")
	t.Setenv("DB_READ_DSN", "")
	t.Setenv("DB_WRITE_DSN", "write-dsn")

	cfg := loadConfig()

	if cfg.Port != "5997" {
		t.Fatalf("beklenen port 5997, gelen %s", cfg.Port)
	}

	if cfg.DSN != "write-dsn" {
		t.Fatalf("beklenen write-dsn, gelen %s", cfg.DSN)
	}
}
