package main

import "testing"

func TestNormalizePort(t *testing.T) {
	if got := normalizePort(":5890"); got != "5890" {
		t.Fatalf("beklenen 5890, gelen %s", got)
	}

	if got := normalizePort(""); got != "5890" {
		t.Fatalf("bos port default 5890 olmali, gelen %s", got)
	}
}

func TestParseLimit(t *testing.T) {
	if got := parseLimit("", 25, 100); got != 25 {
		t.Fatalf("default limit 25 olmali, gelen %d", got)
	}

	if got := parseLimit("500", 25, 100); got != 100 {
		t.Fatalf("max limit 100 olmali, gelen %d", got)
	}

	if got := parseLimit("abc", 25, 100); got != 25 {
		t.Fatalf("gecersiz limit default olmali, gelen %d", got)
	}
}

func TestLoadConfig_DefaultPort(t *testing.T) {
	t.Setenv("WEBHOOK_RUNTIME_PORT", "")
	t.Setenv("DB_READ_DSN", "read-dsn")

	cfg := loadConfig()

	if cfg.Port != "5890" {
		t.Fatalf("beklenen port 5890, gelen %s", cfg.Port)
	}

	if cfg.DSN != "read-dsn" {
		t.Fatalf("beklenen read-dsn, gelen %s", cfg.DSN)
	}
}

func TestLoadConfig_WriteFallback(t *testing.T) {
	t.Setenv("WEBHOOK_RUNTIME_PORT", "5990")
	t.Setenv("DB_READ_DSN", "")
	t.Setenv("DB_WRITE_DSN", "write-dsn")

	cfg := loadConfig()

	if cfg.Port != "5990" {
		t.Fatalf("beklenen port 5990, gelen %s", cfg.Port)
	}

	if cfg.DSN != "write-dsn" {
		t.Fatalf("beklenen write-dsn, gelen %s", cfg.DSN)
	}
}
