package main

import (
	"os"
	"testing"
)

func TestRequiredEnvReturnsValue(t *testing.T) {
	t.Setenv("JWT_SECRET", "dev-jwt-secret")

	got := requiredEnv("JWT_SECRET")
	if got != "dev-jwt-secret" {
		t.Fatalf("beklenen dev-jwt-secret, gelen %q", got)
	}
}

func TestRequiredEnvPanicsWhenMissing(t *testing.T) {
	_ = os.Unsetenv("JWT_SECRET")

	defer func() {
		if r := recover(); r == nil {
			t.Fatal("JWT_SECRET bosken panic bekleniyordu")
		}
	}()

	_ = requiredEnv("JWT_SECRET")
}
