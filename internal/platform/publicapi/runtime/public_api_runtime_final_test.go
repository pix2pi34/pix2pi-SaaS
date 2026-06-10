package publicapiruntime

import (
	"strings"
	"testing"
)

func TestPublicAPIRuntimeFinalEndToEndSandboxFlow(t *testing.T) {
	apiKeyRuntime := NewAPIKeyIssuanceRuntime(DefaultAPIKeyIssuanceRuntimeConfig())

	issuedKey, keyDecision, err := apiKeyRuntime.IssueKey(APIKeyIssueRequest{
		TenantID:    "tenant_final",
		Name:        "Final Sandbox API Key",
		Environment: APIKeyEnvironmentSandbox,
		Scopes:      []string{"read", "write"},
		CreatedBy:   "admin_final",
	})
	if err != nil {
		t.Fatalf("issue API key failed: %v", err)
	}
	if !keyDecision.Allowed {
		t.Fatalf("expected API key issue allowed, got reason=%s", keyDecision.Reason)
	}
	if issuedKey.RawSecret == "" {
		t.Fatal("expected one-time raw secret")
	}
	if strings.Contains(issuedKey.Record.SecretHash, issuedKey.RawSecret) {
		t.Fatal("secret hash must not contain raw secret")
	}

	appRuntime := NewAppAuthRuntime(DefaultAppAuthRuntimeConfig())

	app, appDecision, err := appRuntime.RegisterApp(AppRegistrationRequest{
		TenantID:      "tenant_final",
		Name:          "Final Sandbox App",
		Environment:   APIKeyEnvironmentSandbox,
		AllowedScopes: []string{"read", "write", "report:read"},
		CreatedBy:     "admin_final",
	})
	if err != nil {
		t.Fatalf("register app failed: %v", err)
	}
	if !appDecision.Allowed {
		t.Fatalf("expected app register allowed, got reason=%s", appDecision.Reason)
	}

	relation, relationDecision, err := appRuntime.LinkAPIKey(AppAPIKeyRelationRequest{
		TenantID:     "tenant_final",
		AppID:        app.AppID,
		APIKeyRecord: issuedKey.Record,
		CreatedBy:    "admin_final",
	})
	if err != nil {
		t.Fatalf("link API key failed: %v", err)
	}
	if !relationDecision.Allowed {
		t.Fatalf("expected relation allowed, got reason=%s", relationDecision.Reason)
	}
	if relation.AppID != app.AppID || relation.KeyID != issuedKey.Record.KeyID {
		t.Fatalf("unexpected relation app/key mapping")
	}

	authDecision, err := appRuntime.ValidateAppAuth(AppAuthValidationRequest{
		TenantID:        "tenant_final",
		AppID:           app.AppID,
		KeyID:           issuedKey.Record.KeyID,
		RequestedScopes: []string{"read"},
		Environment:     APIKeyEnvironmentSandbox,
	})
	if err != nil {
		t.Fatalf("validate app auth failed: %v", err)
	}
	if !authDecision.Allowed {
		t.Fatalf("expected app auth allowed, got reason=%s", authDecision.Reason)
	}

	quotaRuntime := NewQuotaRateLimitRuntime(DefaultQuotaRateLimitRuntimeConfig())

	quotaPolicy, quotaPolicyDecision, err := quotaRuntime.CreatePolicy(QuotaPolicyCreateRequest{
		TenantID:      "tenant_final",
		AppID:         app.AppID,
		KeyID:         issuedKey.Record.KeyID,
		Environment:   APIKeyEnvironmentSandbox,
		Scope:         "read",
		WindowSeconds: 60,
		MaxRequests:   2,
		CreatedBy:     "admin_final",
	})
	if err != nil {
		t.Fatalf("create quota policy failed: %v", err)
	}
	if !quotaPolicyDecision.Allowed {
		t.Fatalf("expected quota policy allowed, got reason=%s", quotaPolicyDecision.Reason)
	}
	if quotaPolicy.PolicyID == "" {
		t.Fatal("expected quota policy id")
	}

	sandboxRuntime := NewSandboxEnvironmentRuntime(DefaultSandboxEnvironmentRuntimeConfig())

	ctx, sandboxDecision, err := sandboxRuntime.BuildContext(SandboxRequestContextRequest{
		TenantID:    "tenant_final",
		AppID:       app.AppID,
		KeyID:       issuedKey.Record.KeyID,
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
		Method:      "GET",
		Path:        "/v1/products",
	})
	if err != nil {
		t.Fatalf("build sandbox context failed: %v", err)
	}
	if !sandboxDecision.Allowed {
		t.Fatalf("expected sandbox context allowed, got reason=%s", sandboxDecision.Reason)
	}
	if ctx.DataNamespace != "sandbox:tenant_final:"+app.AppID {
		t.Fatalf("unexpected sandbox namespace %s", ctx.DataNamespace)
	}

	boundaryDecision, err := sandboxRuntime.ValidateAppAuthBoundary(ctx, authDecision)
	if err != nil {
		t.Fatalf("sandbox app auth boundary failed: %v", err)
	}
	if !boundaryDecision.Allowed {
		t.Fatalf("expected sandbox app auth boundary allowed, got reason=%s", boundaryDecision.Reason)
	}

	meter, quotaBridgeDecision, err := sandboxRuntime.AllowSandboxQuota(ctx, quotaRuntime)
	if err != nil {
		t.Fatalf("first sandbox quota bridge failed: %v", err)
	}
	if !quotaBridgeDecision.Allowed {
		t.Fatalf("expected first quota bridge allowed, got reason=%s", quotaBridgeDecision.Reason)
	}
	if meter.Used != 1 || meter.Remaining != 1 {
		t.Fatalf("expected used=1 remaining=1, got used=%d remaining=%d", meter.Used, meter.Remaining)
	}

	meter, quotaBridgeDecision, err = sandboxRuntime.AllowSandboxQuota(ctx, quotaRuntime)
	if err != nil {
		t.Fatalf("second sandbox quota bridge failed: %v", err)
	}
	if !quotaBridgeDecision.Allowed {
		t.Fatalf("expected second quota bridge allowed, got reason=%s", quotaBridgeDecision.Reason)
	}
	if meter.Used != 2 || meter.Remaining != 0 {
		t.Fatalf("expected used=2 remaining=0, got used=%d remaining=%d", meter.Used, meter.Remaining)
	}

	_, quotaBridgeDecision, err = sandboxRuntime.AllowSandboxQuota(ctx, quotaRuntime)
	if err != ErrSandboxQuotaDenied {
		t.Fatalf("expected sandbox quota denied after limit, got %v", err)
	}
	if quotaBridgeDecision.Reason != SandboxReasonQuotaDenied {
		t.Fatalf("expected sandbox quota denied reason, got %s", quotaBridgeDecision.Reason)
	}

	docsRuntime := NewDeveloperDocsPublishRuntime(DefaultDeveloperDocsPublishRuntimeConfig())
	docsRuntime.SeedRequiredPublicAPISections()

	endpointDecision, err := docsRuntime.RegisterEndpoint(DeveloperEndpointDoc{
		Method:          "GET",
		Path:            "/v1/products",
		Summary:         "List products",
		Description:     "Lists sandbox products for the authenticated app.",
		RequiredScopes:  []string{"read"},
		Environment:     APIKeyEnvironmentSandbox,
		RequestExample:  `{"limit":10}`,
		ResponseExample: `{"items":[]}`,
	})
	if err != nil {
		t.Fatalf("register developer endpoint failed: %v", err)
	}
	if !endpointDecision.Allowed {
		t.Fatalf("expected endpoint register allowed, got reason=%s", endpointDecision.Reason)
	}

	markdownResult, markdownDecision, err := docsRuntime.PublishMarkdown()
	if err != nil {
		t.Fatalf("publish markdown failed: %v", err)
	}
	if !markdownDecision.Allowed {
		t.Fatalf("expected markdown publish allowed, got reason=%s", markdownDecision.Reason)
	}
	if !strings.Contains(markdownResult.Content, "`GET /v1/products`") {
		t.Fatal("expected markdown to include final endpoint")
	}
	if !strings.Contains(markdownResult.Content, "Sandbox") {
		t.Fatal("expected markdown to include sandbox section")
	}

	openAPITraceResult, openAPITraceDecision, err := docsRuntime.PublishOpenAPITrace()
	if err != nil {
		t.Fatalf("publish openapi trace failed: %v", err)
	}
	if !openAPITraceDecision.Allowed {
		t.Fatalf("expected openapi trace publish allowed, got reason=%s", openAPITraceDecision.Reason)
	}
	if !strings.Contains(openAPITraceResult.Content, `"openapi_trace": "3.1.0-draft-ready"`) {
		t.Fatal("expected openapi trace marker")
	}
}

func TestPublicAPIRuntimeFinalCrossTenantDenyAcrossModules(t *testing.T) {
	apiKeyRuntime := NewAPIKeyIssuanceRuntime(DefaultAPIKeyIssuanceRuntimeConfig())

	issuedKey, _, err := apiKeyRuntime.IssueKey(APIKeyIssueRequest{
		TenantID:    "tenant_final",
		Name:        "Cross Tenant Key",
		Environment: APIKeyEnvironmentSandbox,
		Scopes:      []string{"read"},
	})
	if err != nil {
		t.Fatalf("issue API key failed: %v", err)
	}

	_, err = apiKeyRuntime.GetKey("tenant_other", issuedKey.Record.KeyID)
	if err != ErrAPIKeyCrossTenant {
		t.Fatalf("expected api key cross tenant error, got %v", err)
	}

	appRuntime := NewAppAuthRuntime(DefaultAppAuthRuntimeConfig())

	app, _, err := appRuntime.RegisterApp(AppRegistrationRequest{
		TenantID:      "tenant_final",
		Name:          "Cross Tenant App",
		Environment:   APIKeyEnvironmentSandbox,
		AllowedScopes: []string{"read"},
	})
	if err != nil {
		t.Fatalf("register app failed: %v", err)
	}

	foreignKey := APIKeyRecord{
		TenantID:    "tenant_other",
		KeyID:       "ak_foreign",
		Name:        "Foreign Key",
		Environment: APIKeyEnvironmentSandbox,
		Scopes:      []string{"read"},
		Status:      APIKeyStatusActive,
	}

	_, appRelationDecision, err := appRuntime.LinkAPIKey(AppAPIKeyRelationRequest{
		TenantID:     "tenant_final",
		AppID:        app.AppID,
		APIKeyRecord: foreignKey,
	})
	if err != ErrAppAuthCrossTenant {
		t.Fatalf("expected app auth cross tenant error, got %v", err)
	}
	if appRelationDecision.Reason != AppAuthReasonCrossTenant {
		t.Fatalf("expected app auth cross tenant reason, got %s", appRelationDecision.Reason)
	}

	quotaRuntime := NewQuotaRateLimitRuntime(DefaultQuotaRateLimitRuntimeConfig())

	policy, _, err := quotaRuntime.CreatePolicy(QuotaPolicyCreateRequest{
		TenantID:      "tenant_final",
		AppID:         app.AppID,
		KeyID:         issuedKey.Record.KeyID,
		Environment:   APIKeyEnvironmentSandbox,
		Scope:         "read",
		WindowSeconds: 60,
		MaxRequests:   10,
	})
	if err != nil {
		t.Fatalf("create quota policy failed: %v", err)
	}

	_, err = quotaRuntime.GetPolicy("tenant_other", policy.PolicyID)
	if err != ErrQuotaCrossTenant {
		t.Fatalf("expected quota cross tenant error, got %v", err)
	}

	sandboxRuntime := NewSandboxEnvironmentRuntime(DefaultSandboxEnvironmentRuntimeConfig())

	ctx, _, err := sandboxRuntime.BuildContext(SandboxRequestContextRequest{
		TenantID:    "tenant_final",
		AppID:       app.AppID,
		KeyID:       issuedKey.Record.KeyID,
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
		Method:      "GET",
		Path:        "/v1/products",
	})
	if err != nil {
		t.Fatalf("build sandbox context failed: %v", err)
	}

	_, err = sandboxRuntime.ValidateAppAuthBoundary(ctx, AppAuthDecision{
		Decision:    AppAuthDecisionAllow,
		Allowed:     true,
		TenantID:    "tenant_other",
		AppID:       app.AppID,
		KeyID:       issuedKey.Record.KeyID,
		Environment: APIKeyEnvironmentSandbox,
		Scopes:      []string{"read"},
		Reason:      AppAuthReasonAllowed,
	})
	if err != ErrSandboxCrossTenant {
		t.Fatalf("expected sandbox cross tenant error, got %v", err)
	}

	_, productionDecision, err := sandboxRuntime.BuildContext(SandboxRequestContextRequest{
		TenantID:    "tenant_final",
		AppID:       app.AppID,
		KeyID:       issuedKey.Record.KeyID,
		Environment: APIKeyEnvironmentProduction,
		Scope:       "read",
		Method:      "GET",
		Path:        "/v1/products",
	})
	if err != ErrSandboxProductionDenied {
		t.Fatalf("expected sandbox production denied, got %v", err)
	}
	if productionDecision.Reason != SandboxReasonProductionDenied {
		t.Fatalf("expected production denied reason, got %s", productionDecision.Reason)
	}
}
