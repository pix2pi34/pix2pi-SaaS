package service

import "testing"

func TestRuntimeRequestGuardProfile_Validate_Success(t *testing.T) {
	profile := DefaultAPIRuntimeRequestGuardProfile()

	if err := profile.Validate(); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestRuntimeRequestGuardProfile_Validate_EmptyName(t *testing.T) {
	profile := DefaultAPIRuntimeRequestGuardProfile()
	profile.Name = ""

	err := profile.Validate()
	if err == nil {
		t.Fatal("expected empty name error")
	}
	if err != ErrRuntimeGuardProfileNameRequired {
		t.Fatalf("expected ErrRuntimeGuardProfileNameRequired, got %v", err)
	}
}

func TestGuardRuntimeRequestInput_Success(t *testing.T) {
	err := GuardRuntimeRequestInput(
		DefaultAPIRuntimeRequestGuardProfile(),
		RuntimeRequestInput{
			QueryParams: map[string]string{
				"tenant_id": "tenant_42",
				"branch_id": "branch_1",
			},
			Headers: map[string]string{
				"X-Tenant-ID":  "tenant_42",
				"X-Request-ID": "req_123",
			},
		},
	)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestGuardRuntimeRequestInput_UnknownQueryKey(t *testing.T) {
	err := GuardRuntimeRequestInput(
		DefaultAPIRuntimeRequestGuardProfile(),
		RuntimeRequestInput{
			QueryParams: map[string]string{
				"evil_key": "tenant_42",
			},
			Headers: map[string]string{},
		},
	)
	if err == nil {
		t.Fatal("expected unknown query key error")
	}
	if err != ErrInputKeyNotAllowed {
		t.Fatalf("expected ErrInputKeyNotAllowed, got %v", err)
	}
}

func TestGuardRuntimeRequestInput_UnknownHeaderKey(t *testing.T) {
	err := GuardRuntimeRequestInput(
		DefaultAPIRuntimeRequestGuardProfile(),
		RuntimeRequestInput{
			QueryParams: map[string]string{},
			Headers: map[string]string{
				"X-Evil-Header": "tenant_42",
			},
		},
	)
	if err == nil {
		t.Fatal("expected unknown header key error")
	}
	if err != ErrHeaderKeyNotAllowed {
		t.Fatalf("expected ErrHeaderKeyNotAllowed, got %v", err)
	}
}

func TestGuardRuntimeRequestInput_InjectionRisk(t *testing.T) {
	err := GuardRuntimeRequestInput(
		DefaultAPIRuntimeRequestGuardProfile(),
		RuntimeRequestInput{
			QueryParams: map[string]string{
				"tenant_id": "abc; DROP TABLE users",
			},
			Headers: map[string]string{},
		},
	)
	if err == nil {
		t.Fatal("expected injection risk error")
	}
	if err != ErrInputInjectionRiskDetected {
		t.Fatalf("expected ErrInputInjectionRiskDetected, got %v", err)
	}
}

func TestGuardRuntimeRequestInput_QueryWithoutAllowlist(t *testing.T) {
	profile := DefaultAPIRuntimeRequestGuardProfile()
	profile.AllowedQueryKeys = []string{}

	err := GuardRuntimeRequestInput(
		profile,
		RuntimeRequestInput{
			QueryParams: map[string]string{
				"tenant_id": "tenant_42",
			},
			Headers: map[string]string{},
		},
	)
	if err == nil {
		t.Fatal("expected query allowlist error")
	}
	if err != ErrInputKeyNotAllowed {
		t.Fatalf("expected ErrInputKeyNotAllowed, got %v", err)
	}
}

func TestGuardRuntimeRequestInput_HeaderWithoutAllowlist(t *testing.T) {
	profile := DefaultAPIRuntimeRequestGuardProfile()
	profile.AllowedHeaderKeys = []string{}

	err := GuardRuntimeRequestInput(
		profile,
		RuntimeRequestInput{
			QueryParams: map[string]string{},
			Headers: map[string]string{
				"X-Tenant-ID": "tenant_42",
			},
		},
	)
	if err == nil {
		t.Fatal("expected header allowlist error")
	}
	if err != ErrHeaderKeyNotAllowed {
		t.Fatalf("expected ErrHeaderKeyNotAllowed, got %v", err)
	}
}

func TestGuardRuntimeRequestInput_NilMaps(t *testing.T) {
	err := GuardRuntimeRequestInput(
		DefaultAPIRuntimeRequestGuardProfile(),
		RuntimeRequestInput{},
	)
	if err == nil {
		t.Fatal("expected nil maps error")
	}
	if err != ErrRuntimeGuardInputNilMaps {
		t.Fatalf("expected ErrRuntimeGuardInputNilMaps, got %v", err)
	}
}
