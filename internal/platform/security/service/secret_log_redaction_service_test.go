package service

import "testing"

func TestIsSensitiveSecretKey(t *testing.T) {
	cases := map[string]bool{
		"JWT_SECRET":     true,
		"db_password":    true,
		"ACCESS_TOKEN":   true,
		"client_secret":  true,
		"api_key":        true,
		"tenant_id":      false,
		"service_name":   false,
		"environment":    false,
	}

	for key, expected := range cases {
		got := IsSensitiveSecretKey(key)
		if got != expected {
			t.Fatalf("key %s expected %v got %v", key, expected, got)
		}
	}
}

func TestRedactSecretValue(t *testing.T) {
	got := RedactSecretValue("Pix2piSuperSecret123")
	if got != RedactedSecretValue {
		t.Fatalf("expected %s, got %s", RedactedSecretValue, got)
	}
}

func TestSanitizeLogFields(t *testing.T) {
	fields := map[string]string{
		"service":      "identity",
		"JWT_SECRET":   "Pix2piSuperSecret123",
		"db_password":  "PostgresStrongPass123",
		"tenant_id":    "tenant_42",
	}

	sanitized := SanitizeLogFields(fields)

	if sanitized["service"] != "identity" {
		t.Fatalf("expected identity, got %s", sanitized["service"])
	}
	if sanitized["tenant_id"] != "tenant_42" {
		t.Fatalf("expected tenant_42, got %s", sanitized["tenant_id"])
	}
	if sanitized["JWT_SECRET"] != RedactedSecretValue {
		t.Fatalf("expected redacted jwt secret, got %s", sanitized["JWT_SECRET"])
	}
	if sanitized["db_password"] != RedactedSecretValue {
		t.Fatalf("expected redacted db password, got %s", sanitized["db_password"])
	}
}

func TestSecretAppearsInLogLine(t *testing.T) {
	logLine := "config loaded jwt=Pix2piSuperSecret123"

	if !SecretAppearsInLogLine("Pix2piSuperSecret123", logLine) {
		t.Fatal("expected secret to appear in log line")
	}
	if SecretAppearsInLogLine("", logLine) {
		t.Fatal("empty secret must not match")
	}
}

func TestValidateNoSecretLeak_Success(t *testing.T) {
	err := ValidateNoSecretLeak(
		"config loaded jwt=[REDACTED] db=[REDACTED]",
		[]SecretContractInput{
			{Name: "JWT_SECRET", Value: "Pix2piSuperSecret123"},
			{Name: "DB_PASSWORD", Value: "PostgresStrongPass123"},
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestValidateNoSecretLeak_LeakDetected(t *testing.T) {
	err := ValidateNoSecretLeak(
		"config loaded jwt=Pix2piSuperSecret123",
		[]SecretContractInput{
			{Name: "JWT_SECRET", Value: "Pix2piSuperSecret123"},
		},
	)
	if err == nil {
		t.Fatal("expected leak detected error")
	}
	if err != ErrSecretLogLeakDetected {
		t.Fatalf("expected ErrSecretLogLeakDetected, got %v", err)
	}
}
