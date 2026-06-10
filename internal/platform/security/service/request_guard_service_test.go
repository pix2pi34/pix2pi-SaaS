package service

import "testing"

func TestValidateInputKey_Success(t *testing.T) {
	err := ValidateInputKey("tenant_id")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestValidateInputKey_Invalid(t *testing.T) {
	err := ValidateInputKey("tenant id")
	if err == nil {
		t.Fatal("expected invalid key error")
	}
	if err != ErrInputKeyInvalid {
		t.Fatalf("expected ErrInputKeyInvalid, got %v", err)
	}
}

func TestValidateHeaderKey_Success(t *testing.T) {
	err := ValidateHeaderKey("X-Tenant-ID")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestValidateHeaderKey_Invalid(t *testing.T) {
	err := ValidateHeaderKey("X Tenant ID")
	if err == nil {
		t.Fatal("expected invalid header key error")
	}
	if err != ErrHeaderKeyInvalid {
		t.Fatalf("expected ErrHeaderKeyInvalid, got %v", err)
	}
}

func TestDetectInjectionRisk(t *testing.T) {
	if !DetectInjectionRisk("abc; DROP TABLE users") {
		t.Fatal("expected injection risk")
	}
	if DetectInjectionRisk("tenant_42") {
		t.Fatal("did not expect injection risk")
	}
}

func TestValidateSafeInputValue_Success(t *testing.T) {
	err := ValidateSafeInputValue("tenant_42", 64)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestValidateSafeInputValue_TooLong(t *testing.T) {
	err := ValidateSafeInputValue("abcdefghijklmnopqrstuvwxyz", 5)
	if err == nil {
		t.Fatal("expected too long error")
	}
	if err != ErrInputTooLong {
		t.Fatalf("expected ErrInputTooLong, got %v", err)
	}
}

func TestValidateSafeInputValue_InjectionRisk(t *testing.T) {
	err := ValidateSafeInputValue("abc; DROP TABLE users", 128)
	if err == nil {
		t.Fatal("expected injection risk error")
	}
	if err != ErrInputInjectionRiskDetected {
		t.Fatalf("expected ErrInputInjectionRiskDetected, got %v", err)
	}
}

func TestValidateAllowedQueryParams_Success(t *testing.T) {
	err := ValidateAllowedQueryParams(
		map[string]string{
			"tenant_id": "tenant_42",
			"branch_id": "branch_1",
		},
		[]string{"tenant_id", "branch_id", "period_key"},
		64,
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestValidateAllowedQueryParams_UnknownKey(t *testing.T) {
	err := ValidateAllowedQueryParams(
		map[string]string{
			"evil_key": "tenant_42",
		},
		[]string{"tenant_id", "branch_id"},
		64,
	)
	if err == nil {
		t.Fatal("expected unknown key error")
	}
	if err != ErrInputKeyNotAllowed {
		t.Fatalf("expected ErrInputKeyNotAllowed, got %v", err)
	}
}

func TestValidateAllowedQueryParams_InjectionValue(t *testing.T) {
	err := ValidateAllowedQueryParams(
		map[string]string{
			"tenant_id": "tenant_42",
			"branch_id": "abc; DROP TABLE x",
		},
		[]string{"tenant_id", "branch_id"},
		128,
	)
	if err == nil {
		t.Fatal("expected injection risk error")
	}
	if err != ErrInputInjectionRiskDetected {
		t.Fatalf("expected ErrInputInjectionRiskDetected, got %v", err)
	}
}

func TestValidateAllowedHeaderInputs_Success(t *testing.T) {
	err := ValidateAllowedHeaderInputs(
		map[string]string{
			"X-Tenant-ID":  "tenant_42",
			"X-Request-ID": "req_123",
		},
		[]string{"X-Tenant-ID", "X-Request-ID"},
		64,
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestValidateAllowedHeaderInputs_UnknownKey(t *testing.T) {
	err := ValidateAllowedHeaderInputs(
		map[string]string{
			"X-Evil-Header": "tenant_42",
		},
		[]string{"X-Tenant-ID", "X-Request-ID"},
		64,
	)
	if err == nil {
		t.Fatal("expected unknown header key error")
	}
	if err != ErrHeaderKeyNotAllowed {
		t.Fatalf("expected ErrHeaderKeyNotAllowed, got %v", err)
	}
}
