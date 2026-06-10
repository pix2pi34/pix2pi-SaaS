package main

import "testing"

func TestNormalizePort(t *testing.T) {
	if got := normalizePort(":5940"); got != "5940" {
		t.Fatalf("beklenen 5940, gelen %s", got)
	}

	if got := normalizePort(""); got != "5940" {
		t.Fatalf("bos port default 5940 olmali, gelen %s", got)
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

func TestLevelFromPercent(t *testing.T) {
	if got := levelFromPercent(50, 80, 90); got != "ok" {
		t.Fatalf("beklenen ok, gelen %s", got)
	}

	if got := levelFromPercent(85, 80, 90); got != "warning" {
		t.Fatalf("beklenen warning, gelen %s", got)
	}

	if got := levelFromPercent(95, 80, 90); got != "critical" {
		t.Fatalf("beklenen critical, gelen %s", got)
	}
}

func TestMaxLevel(t *testing.T) {
	if got := maxLevel("ok", "warning"); got != "warning" {
		t.Fatalf("beklenen warning, gelen %s", got)
	}

	if got := maxLevel("ok", "warning", "critical"); got != "critical" {
		t.Fatalf("beklenen critical, gelen %s", got)
	}
}

func TestLoadConfig_DefaultPort(t *testing.T) {
	t.Setenv("EARLY_WARNING_RUNTIME_PORT", "")
	t.Setenv("DB_READ_DSN", "read-dsn")

	cfg := loadConfig()

	if cfg.Port != "5940" {
		t.Fatalf("beklenen port 5940, gelen %s", cfg.Port)
	}

	if cfg.DSN != "read-dsn" {
		t.Fatalf("beklenen read-dsn, gelen %s", cfg.DSN)
	}

	if len(cfg.Targets) == 0 {
		t.Fatalf("target listesi bos olmamali")
	}
}

func TestLoadConfig_WriteFallback(t *testing.T) {
	t.Setenv("EARLY_WARNING_RUNTIME_PORT", "5995")
	t.Setenv("DB_READ_DSN", "")
	t.Setenv("DB_WRITE_DSN", "write-dsn")

	cfg := loadConfig()

	if cfg.Port != "5995" {
		t.Fatalf("beklenen port 5995, gelen %s", cfg.Port)
	}

	if cfg.DSN != "write-dsn" {
		t.Fatalf("beklenen write-dsn, gelen %s", cfg.DSN)
	}
}
