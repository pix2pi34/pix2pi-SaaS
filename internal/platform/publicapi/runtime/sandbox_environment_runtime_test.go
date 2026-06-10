package publicapiruntime

import "testing"

func TestSandboxEnvironmentRuntimeBuildsSandboxContext(t *testing.T) {
	runtime := NewSandboxEnvironmentRuntime(DefaultSandboxEnvironmentRuntimeConfig())

	ctx, decision, err := runtime.BuildContext(SandboxRequestContextRequest{
		TenantID:    "tenant_7",
		AppID:       "app_7",
		KeyID:       "key_7",
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
		Method:      "get",
		Path:        "/v1/products",
	})
	if err != nil {
		t.Fatalf("build context failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected allowed decision, got reason=%s", decision.Reason)
	}
	if !ctx.IsSandbox {
		t.Fatal("expected sandbox context")
	}
	if ctx.Environment != APIKeyEnvironmentSandbox {
		t.Fatalf("expected SANDBOX, got %s", ctx.Environment)
	}
	if ctx.DataNamespace != "sandbox:tenant_7:app_7" {
		t.Fatalf("unexpected namespace %s", ctx.DataNamespace)
	}
	if ctx.Method != "GET" {
		t.Fatalf("expected GET method, got %s", ctx.Method)
	}
}

func TestSandboxEnvironmentRuntimeRejectsProductionByDefault(t *testing.T) {
	runtime := NewSandboxEnvironmentRuntime(DefaultSandboxEnvironmentRuntimeConfig())

	_, decision, err := runtime.BuildContext(SandboxRequestContextRequest{
		TenantID:    "tenant_7",
		AppID:       "app_7",
		KeyID:       "key_7",
		Environment: APIKeyEnvironmentProduction,
		Scope:       "read",
		Path:        "/v1/products",
	})

	if err != ErrSandboxProductionDenied {
		t.Fatalf("expected production denied error, got %v", err)
	}
	if decision.Reason != SandboxReasonProductionDenied {
		t.Fatalf("expected production denied reason, got %s", decision.Reason)
	}
}

func TestSandboxEnvironmentRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewSandboxEnvironmentRuntime(DefaultSandboxEnvironmentRuntimeConfig())

	_, decision, err := runtime.BuildContext(SandboxRequestContextRequest{
		AppID:       "app_7",
		KeyID:       "key_7",
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
		Path:        "/v1/products",
	})

	if err != ErrSandboxMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != SandboxReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestSandboxEnvironmentRuntimeValidateAppAuthBoundary(t *testing.T) {
	runtime := NewSandboxEnvironmentRuntime(DefaultSandboxEnvironmentRuntimeConfig())

	ctx, _, err := runtime.BuildContext(SandboxRequestContextRequest{
		TenantID:    "tenant_7",
		AppID:       "app_7",
		KeyID:       "key_7",
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
		Path:        "/v1/products",
	})
	if err != nil {
		t.Fatalf("build context failed: %v", err)
	}

	decision, err := runtime.ValidateAppAuthBoundary(ctx, AppAuthDecision{
		Decision:    AppAuthDecisionAllow,
		Allowed:     true,
		TenantID:    "tenant_7",
		AppID:       "app_7",
		KeyID:       "key_7",
		Environment: APIKeyEnvironmentSandbox,
		Scopes:      []string{"read", "write"},
		Reason:      AppAuthReasonAllowed,
	})
	if err != nil {
		t.Fatalf("validate boundary failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected allowed boundary, got reason=%s", decision.Reason)
	}
}

func TestSandboxEnvironmentRuntimeRejectsProductionAppAuthBoundary(t *testing.T) {
	runtime := NewSandboxEnvironmentRuntime(DefaultSandboxEnvironmentRuntimeConfig())

	ctx, _, err := runtime.BuildContext(SandboxRequestContextRequest{
		TenantID:    "tenant_7",
		AppID:       "app_7",
		KeyID:       "key_7",
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
		Path:        "/v1/products",
	})
	if err != nil {
		t.Fatalf("build context failed: %v", err)
	}

	_, err = runtime.ValidateAppAuthBoundary(ctx, AppAuthDecision{
		Decision:    AppAuthDecisionAllow,
		Allowed:     true,
		TenantID:    "tenant_7",
		AppID:       "app_7",
		KeyID:       "key_7",
		Environment: APIKeyEnvironmentProduction,
		Scopes:      []string{"read"},
		Reason:      AppAuthReasonAllowed,
	})

	if err != ErrSandboxAppAuthEnvironmentMismatch {
		t.Fatalf("expected app auth environment mismatch, got %v", err)
	}
}

func TestSandboxEnvironmentRuntimeRejectsCrossTenantAppAuthBoundary(t *testing.T) {
	runtime := NewSandboxEnvironmentRuntime(DefaultSandboxEnvironmentRuntimeConfig())

	ctx, _, err := runtime.BuildContext(SandboxRequestContextRequest{
		TenantID:    "tenant_7",
		AppID:       "app_7",
		KeyID:       "key_7",
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
		Path:        "/v1/products",
	})
	if err != nil {
		t.Fatalf("build context failed: %v", err)
	}

	_, err = runtime.ValidateAppAuthBoundary(ctx, AppAuthDecision{
		Decision:    AppAuthDecisionAllow,
		Allowed:     true,
		TenantID:    "tenant_8",
		AppID:       "app_7",
		KeyID:       "key_7",
		Environment: APIKeyEnvironmentSandbox,
		Scopes:      []string{"read"},
		Reason:      AppAuthReasonAllowed,
	})

	if err != ErrSandboxCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
}

func TestSandboxEnvironmentRuntimeQuotaBridgeAllowsAndDenies(t *testing.T) {
	sandboxRuntime := NewSandboxEnvironmentRuntime(DefaultSandboxEnvironmentRuntimeConfig())
	quotaRuntime := NewQuotaRateLimitRuntime(DefaultQuotaRateLimitRuntimeConfig())

	_, _, err := quotaRuntime.CreatePolicy(QuotaPolicyCreateRequest{
		TenantID:      "tenant_7",
		AppID:         "app_7",
		KeyID:         "key_7",
		Environment:   APIKeyEnvironmentSandbox,
		Scope:         "read",
		WindowSeconds: 60,
		MaxRequests:   1,
	})
	if err != nil {
		t.Fatalf("create quota policy failed: %v", err)
	}

	ctx, _, err := sandboxRuntime.BuildContext(SandboxRequestContextRequest{
		TenantID:    "tenant_7",
		AppID:       "app_7",
		KeyID:       "key_7",
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
		Path:        "/v1/products",
	})
	if err != nil {
		t.Fatalf("build context failed: %v", err)
	}

	meter, decision, err := sandboxRuntime.AllowSandboxQuota(ctx, quotaRuntime)
	if err != nil {
		t.Fatalf("first sandbox quota failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected first quota allowed, got reason=%s", decision.Reason)
	}
	if meter.Used != 1 {
		t.Fatalf("expected used=1, got %d", meter.Used)
	}

	_, decision, err = sandboxRuntime.AllowSandboxQuota(ctx, quotaRuntime)
	if err != ErrSandboxQuotaDenied {
		t.Fatalf("expected sandbox quota denied, got %v", err)
	}
	if decision.Reason != SandboxReasonQuotaDenied {
		t.Fatalf("expected quota denied reason, got %s", decision.Reason)
	}
}

func TestSandboxEnvironmentRuntimeTenantNamespaceIsolation(t *testing.T) {
	nsA := BuildSandboxDataNamespace("tenant_a", "app_1")
	nsB := BuildSandboxDataNamespace("tenant_b", "app_1")

	if nsA == nsB {
		t.Fatal("expected different namespaces for different tenants")
	}
	if nsA != "sandbox:tenant_a:app_1" {
		t.Fatalf("unexpected tenant_a namespace %s", nsA)
	}

	ctx := SandboxRequestContext{
		TenantID: "tenant_a",
		AppID:    "app_1",
	}

	if !SandboxContextMatchesTenant(ctx, "tenant_a") {
		t.Fatal("expected context to match tenant_a")
	}
	if SandboxContextMatchesTenant(ctx, "tenant_b") {
		t.Fatal("expected context not to match tenant_b")
	}
}
