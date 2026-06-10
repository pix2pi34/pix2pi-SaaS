package main

import "testing"

func TestNormalizePort(t *testing.T) {
	if got := normalizePort(":5950"); got != "5950" {
		t.Fatalf("beklenen 5950, gelen %s", got)
	}

	if got := normalizePort(""); got != "5950" {
		t.Fatalf("bos port default 5950 olmali, gelen %s", got)
	}
}

func TestParseLimit(t *testing.T) {
	if got := parseLimit("", 50, 200); got != 50 {
		t.Fatalf("default limit 50 olmali, gelen %d", got)
	}

	if got := parseLimit("500", 50, 200); got != 200 {
		t.Fatalf("max limit 200 olmali, gelen %d", got)
	}

	if got := parseLimit("abc", 50, 200); got != 50 {
		t.Fatalf("gecersiz limit default olmali, gelen %d", got)
	}
}

func TestAlertLevel(t *testing.T) {
	if got := alertLevel(0, 0); got != "ok" {
		t.Fatalf("beklenen ok, gelen %s", got)
	}

	if got := alertLevel(2, 0); got != "warning" {
		t.Fatalf("beklenen warning, gelen %s", got)
	}

	if got := alertLevel(2, 1); got != "critical" {
		t.Fatalf("beklenen critical, gelen %s", got)
	}
}

func TestLoadConfig_DefaultPort(t *testing.T) {
	t.Setenv("INCIDENT_AUDIT_RUNTIME_PORT", "")
	t.Setenv("DB_READ_DSN", "read-dsn")

	cfg := loadConfig()

	if cfg.Port != "5950" {
		t.Fatalf("beklenen port 5950, gelen %s", cfg.Port)
	}

	if cfg.DSN != "read-dsn" {
		t.Fatalf("beklenen read-dsn, gelen %s", cfg.DSN)
	}
}

func TestLoadConfig_WriteFallback(t *testing.T) {
	t.Setenv("INCIDENT_AUDIT_RUNTIME_PORT", "5996")
	t.Setenv("DB_READ_DSN", "")
	t.Setenv("DB_WRITE_DSN", "write-dsn")

	cfg := loadConfig()

	if cfg.Port != "5996" {
		t.Fatalf("beklenen port 5996, gelen %s", cfg.Port)
	}

	if cfg.DSN != "write-dsn" {
		t.Fatalf("beklenen write-dsn, gelen %s", cfg.DSN)
	}
}
