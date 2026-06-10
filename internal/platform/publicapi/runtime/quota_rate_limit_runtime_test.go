package publicapiruntime

import "testing"

func createTestQuotaPolicy(t *testing.T, runtime *QuotaRateLimitRuntime, maxRequests int) QuotaPolicy {
	t.Helper()

	policy, decision, err := runtime.CreatePolicy(QuotaPolicyCreateRequest{
		TenantID:      "tenant_7",
		AppID:         "app_7",
		KeyID:         "key_7",
		Environment:   APIKeyEnvironmentSandbox,
		Scope:         "read",
		WindowSeconds: 60,
		MaxRequests:   maxRequests,
		CreatedBy:     "admin_1",
	})
	if err != nil {
		t.Fatalf("create policy failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected policy create allowed, got reason=%s", decision.Reason)
	}

	return policy
}

func TestQuotaRateLimitRuntimeCreatesPolicy(t *testing.T) {
	runtime := NewQuotaRateLimitRuntime(DefaultQuotaRateLimitRuntimeConfig())

	policy := createTestQuotaPolicy(t, runtime, 10)

	if policy.PolicyID == "" {
		t.Fatal("expected policy id")
	}
	if policy.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", policy.TenantID)
	}
	if policy.Environment != APIKeyEnvironmentSandbox {
		t.Fatalf("expected sandbox, got %s", policy.Environment)
	}
	if policy.Scope != "read" {
		t.Fatalf("expected read scope, got %s", policy.Scope)
	}
	if policy.Status != QuotaPolicyStatusActive {
		t.Fatalf("expected ACTIVE, got %s", policy.Status)
	}
}

func TestQuotaRateLimitRuntimeAllowsWithinLimitAndDeniesAfterLimit(t *testing.T) {
	runtime := NewQuotaRateLimitRuntime(DefaultQuotaRateLimitRuntimeConfig())
	policy := createTestQuotaPolicy(t, runtime, 2)

	req := QuotaUsageRequest{
		TenantID:    "tenant_7",
		AppID:       "app_7",
		KeyID:       "key_7",
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
		PolicyID:    policy.PolicyID,
	}

	meter, decision, err := runtime.AllowRequest(req)
	if err != nil {
		t.Fatalf("first allow failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected first allowed, got reason=%s", decision.Reason)
	}
	if meter.Used != 1 || meter.Remaining != 1 {
		t.Fatalf("expected used=1 remaining=1, got used=%d remaining=%d", meter.Used, meter.Remaining)
	}

	meter, decision, err = runtime.AllowRequest(req)
	if err != nil {
		t.Fatalf("second allow failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected second allowed, got reason=%s", decision.Reason)
	}
	if meter.Used != 2 || meter.Remaining != 0 {
		t.Fatalf("expected used=2 remaining=0, got used=%d remaining=%d", meter.Used, meter.Remaining)
	}

	meter, decision, err = runtime.AllowRequest(req)
	if err != ErrQuotaLimitExceeded {
		t.Fatalf("expected limit exceeded, got %v", err)
	}
	if decision.Allowed {
		t.Fatal("expected deny after limit")
	}
	if decision.Reason != QuotaReasonLimitExceeded {
		t.Fatalf("expected limit exceeded reason, got %s", decision.Reason)
	}
	if meter.Used != 2 || meter.Remaining != 0 {
		t.Fatalf("expected meter to stay used=2 remaining=0, got used=%d remaining=%d", meter.Used, meter.Remaining)
	}
}

func TestQuotaRateLimitRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewQuotaRateLimitRuntime(DefaultQuotaRateLimitRuntimeConfig())

	_, decision, err := runtime.CreatePolicy(QuotaPolicyCreateRequest{
		AppID:         "app_7",
		KeyID:         "key_7",
		Environment:   APIKeyEnvironmentSandbox,
		Scope:         "read",
		WindowSeconds: 60,
		MaxRequests:   10,
	})

	if err != ErrQuotaMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != QuotaReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestQuotaRateLimitRuntimeRejectsInvalidLimit(t *testing.T) {
	runtime := NewQuotaRateLimitRuntime(DefaultQuotaRateLimitRuntimeConfig())

	_, decision, err := runtime.CreatePolicy(QuotaPolicyCreateRequest{
		TenantID:      "tenant_7",
		AppID:         "app_7",
		KeyID:         "key_7",
		Environment:   APIKeyEnvironmentSandbox,
		Scope:         "read",
		WindowSeconds: 60,
		MaxRequests:   0,
	})

	if err != ErrQuotaInvalidLimit {
		t.Fatalf("expected invalid limit error, got %v", err)
	}
	if decision.Reason != QuotaReasonInvalidLimit {
		t.Fatalf("expected invalid limit reason, got %s", decision.Reason)
	}
}

func TestQuotaRateLimitRuntimeRejectsEnvironmentMismatchPolicy(t *testing.T) {
	runtime := NewQuotaRateLimitRuntime(DefaultQuotaRateLimitRuntimeConfig())
	policy := createTestQuotaPolicy(t, runtime, 10)

	_, decision, err := runtime.AllowRequest(QuotaUsageRequest{
		TenantID:    "tenant_7",
		AppID:       "app_7",
		KeyID:       "key_7",
		Environment: APIKeyEnvironmentProduction,
		Scope:       "read",
		PolicyID:    policy.PolicyID,
	})

	if err != ErrQuotaPolicyMismatch {
		t.Fatalf("expected policy mismatch error, got %v", err)
	}
	if decision.Reason != QuotaReasonPolicyMismatch {
		t.Fatalf("expected policy mismatch reason, got %s", decision.Reason)
	}
}

func TestQuotaRateLimitRuntimeTenantSafePolicyAccess(t *testing.T) {
	runtime := NewQuotaRateLimitRuntime(DefaultQuotaRateLimitRuntimeConfig())
	policy := createTestQuotaPolicy(t, runtime, 10)

	_, err := runtime.GetPolicy("tenant_7", policy.PolicyID)
	if err != nil {
		t.Fatalf("get policy failed: %v", err)
	}

	_, err = runtime.GetPolicy("tenant_8", policy.PolicyID)
	if err != ErrQuotaCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
}

func TestQuotaRateLimitRuntimeTenantUsageSnapshotIsFiltered(t *testing.T) {
	runtime := NewQuotaRateLimitRuntime(DefaultQuotaRateLimitRuntimeConfig())
	policy := createTestQuotaPolicy(t, runtime, 10)

	_, _, err := runtime.AllowRequest(QuotaUsageRequest{
		TenantID:    "tenant_7",
		AppID:       "app_7",
		KeyID:       "key_7",
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
		PolicyID:    policy.PolicyID,
	})
	if err != nil {
		t.Fatalf("allow request failed: %v", err)
	}

	tenant7, err := runtime.TenantUsageSnapshot("tenant_7")
	if err != nil {
		t.Fatalf("tenant_7 snapshot failed: %v", err)
	}
	if len(tenant7) != 1 {
		t.Fatalf("expected tenant_7 meter count 1, got %d", len(tenant7))
	}

	tenant8, err := runtime.TenantUsageSnapshot("tenant_8")
	if err != nil {
		t.Fatalf("tenant_8 snapshot failed: %v", err)
	}
	if len(tenant8) != 0 {
		t.Fatalf("expected tenant_8 meter count 0, got %d", len(tenant8))
	}
}

func TestQuotaRateLimitRuntimeSuspendedPolicyDeniesUsage(t *testing.T) {
	runtime := NewQuotaRateLimitRuntime(DefaultQuotaRateLimitRuntimeConfig())
	policy := createTestQuotaPolicy(t, runtime, 10)

	policy, decision, err := runtime.SuspendPolicy("tenant_7", policy.PolicyID)
	if err != nil {
		t.Fatalf("suspend policy failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected suspend allowed, got reason=%s", decision.Reason)
	}
	if policy.Status != QuotaPolicyStatusSuspended {
		t.Fatalf("expected SUSPENDED, got %s", policy.Status)
	}

	_, decision, err = runtime.AllowRequest(QuotaUsageRequest{
		TenantID:    "tenant_7",
		AppID:       "app_7",
		KeyID:       "key_7",
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
		PolicyID:    policy.PolicyID,
	})
	if err != ErrQuotaInactivePolicy {
		t.Fatalf("expected inactive policy error, got %v", err)
	}
	if decision.Reason != QuotaReasonInactivePolicy {
		t.Fatalf("expected inactive policy reason, got %s", decision.Reason)
	}
}

func TestQuotaRateLimitRuntimeResolvesPolicyWithoutExplicitPolicyID(t *testing.T) {
	runtime := NewQuotaRateLimitRuntime(DefaultQuotaRateLimitRuntimeConfig())
	createTestQuotaPolicy(t, runtime, 5)

	meter, decision, err := runtime.AllowRequest(QuotaUsageRequest{
		TenantID:    "tenant_7",
		AppID:       "app_7",
		KeyID:       "key_7",
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
	})
	if err != nil {
		t.Fatalf("allow without policy id failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected allowed, got reason=%s", decision.Reason)
	}
	if meter.PolicyID == "" {
		t.Fatal("expected resolved policy id")
	}
}
