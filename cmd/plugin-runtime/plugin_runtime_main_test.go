package main

import "testing"

func TestNormalizePort(t *testing.T) {
	if got := normalizePort(":5910"); got != "5910" {
		t.Fatalf("beklenen 5910, gelen %s", got)
	}

	if got := normalizePort(""); got != "5910" {
		t.Fatalf("bos port default 5910 olmali, gelen %s", got)
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

func TestLoadConfig_DefaultPort(t *testing.T) {
	t.Setenv("PLUGIN_RUNTIME_PORT", "")
	t.Setenv("DB_READ_DSN", "read-dsn")

	cfg := loadConfig()

	if cfg.Port != "5910" {
		t.Fatalf("beklenen port 5910, gelen %s", cfg.Port)
	}

	if cfg.DSN != "read-dsn" {
		t.Fatalf("beklenen read-dsn, gelen %s", cfg.DSN)
	}
}

func TestLoadConfig_WriteFallback(t *testing.T) {
	t.Setenv("PLUGIN_RUNTIME_PORT", "5992")
	t.Setenv("DB_READ_DSN", "")
	t.Setenv("DB_WRITE_DSN", "write-dsn")

	cfg := loadConfig()

	if cfg.Port != "5992" {
		t.Fatalf("beklenen port 5992, gelen %s", cfg.Port)
	}

	if cfg.DSN != "write-dsn" {
		t.Fatalf("beklenen write-dsn, gelen %s", cfg.DSN)
	}
}
