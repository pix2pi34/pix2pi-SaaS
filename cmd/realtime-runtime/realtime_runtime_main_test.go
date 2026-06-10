package main

import "testing"

func TestNormalizePort(t *testing.T) {
	if got := normalizePort(":5970"); got != "5970" {
		t.Fatalf("beklenen 5970, gelen %s", got)
	}

	if got := normalizePort(""); got != "5970" {
		t.Fatalf("bos port default 5970 olmali, gelen %s", got)
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

func TestQuoteIdent(t *testing.T) {
	if got := quoteIdent("runtime"); got != `"runtime"` {
		t.Fatalf("beklenen quote runtime, gelen %s", got)
	}
}

func TestFullTableName(t *testing.T) {
	if got := fullTableName("runtime", "realtime_connections"); got != `"runtime"."realtime_connections"` {
		t.Fatalf("beklenen full table, gelen %s", got)
	}
}

func TestLoadConfig_DefaultPort(t *testing.T) {
	t.Setenv("REALTIME_RUNTIME_PORT", "")
	t.Setenv("DB_READ_DSN", "read-dsn")

	cfg := loadConfig()

	if cfg.Port != "5970" {
		t.Fatalf("beklenen port 5970, gelen %s", cfg.Port)
	}

	if cfg.DSN != "read-dsn" {
		t.Fatalf("beklenen read-dsn, gelen %s", cfg.DSN)
	}
}

func TestLoadConfig_WriteFallback(t *testing.T) {
	t.Setenv("REALTIME_RUNTIME_PORT", "5998")
	t.Setenv("DB_READ_DSN", "")
	t.Setenv("DB_WRITE_DSN", "write-dsn")

	cfg := loadConfig()

	if cfg.Port != "5998" {
		t.Fatalf("beklenen port 5998, gelen %s", cfg.Port)
	}

	if cfg.DSN != "write-dsn" {
		t.Fatalf("beklenen write-dsn, gelen %s", cfg.DSN)
	}
}
