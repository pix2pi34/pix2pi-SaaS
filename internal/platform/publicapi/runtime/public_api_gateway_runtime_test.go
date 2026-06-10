package publicapiruntime

import (
	"strings"
	"testing"
)

type publicAPIGatewayFixture struct {
	apiKeyRuntime  *APIKeyIssuanceRuntime
	appRuntime     *AppAuthRuntime
	quotaRuntime   *QuotaRateLimitRuntime
	sandboxRuntime *SandboxEnvironmentRuntime
	docsRuntime    *DeveloperDocsPublishRuntime
	gateway        *PublicAPIGatewayRuntime
	keyResult      APIKeyIssueResult
	app            AppRegistration
	relation       AppAPIKeyRelation
}

func newPublicAPIGatewayFixture(t *testing.T, maxRequests int) publicAPIGatewayFixture {
	t.Helper()

	apiKeyRuntime := NewAPIKeyIssuanceRuntime(DefaultAPIKeyIssuanceRuntimeConfig())
	appRuntime := NewAppAuthRuntime(DefaultAppAuthRuntimeConfig())
	quotaRuntime := NewQuotaRateLimitRuntime(DefaultQuotaRateLimitRuntimeConfig())
	sandboxRuntime := NewSandboxEnvironmentRuntime(DefaultSandboxEnvironmentRuntimeConfig())
	docsRuntime := NewDeveloperDocsPublishRuntime(DefaultDeveloperDocsPublishRuntimeConfig())
	docsRuntime.SeedRequiredPublicAPISections()

	_, err := docsRuntime.RegisterEndpoint(DeveloperEndpointDoc{
		Method:         "GET",
		Path:           "/v1/products",
		Summary:        "List products",
		Description:    "Lists sandbox products for authenticated apps.",
		RequiredScopes: []string{"read"},
		Environment:    APIKeyEnvironmentSandbox,
	})
	if err != nil {
		t.Fatalf("register developer endpoint failed: %v", err)
	}

	keyResult, _, err := apiKeyRuntime.IssueKey(APIKeyIssueRequest{
		TenantID:    "tenant_7",
		Name:        "Gateway Key",
		Environment: APIKeyEnvironmentSandbox,
		Scopes:      []string{"read", "write"},
		CreatedBy:   "admin_1",
	})
	if err != nil {
		t.Fatalf("issue key failed: %v", err)
	}

	app, _, err := appRuntime.RegisterApp(AppRegistrationRequest{
		TenantID:      "tenant_7",
		Name:          "Gateway App",
		Environment:   APIKeyEnvironmentSandbox,
		AllowedScopes: []string{"read", "write"},
		CreatedBy:     "admin_1",
	})
	if err != nil {
		t.Fatalf("register app failed: %v", err)
	}

	relation, _, err := appRuntime.LinkAPIKey(AppAPIKeyRelationRequest{
		TenantID:     "tenant_7",
		AppID:        app.AppID,
		APIKeyRecord: keyResult.Record,
		CreatedBy:    "admin_1",
	})
	if err != nil {
		t.Fatalf("link api key failed: %v", err)
	}

	_, _, err = quotaRuntime.CreatePolicy(QuotaPolicyCreateRequest{
		TenantID:      "tenant_7",
		AppID:         app.AppID,
		KeyID:         keyResult.Record.KeyID,
		Environment:   APIKeyEnvironmentSandbox,
		Scope:         "read",
		WindowSeconds: 60,
		MaxRequests:   maxRequests,
		CreatedBy:     "admin_1",
	})
	if err != nil {
		t.Fatalf("create quota policy failed: %v", err)
	}

	gateway := NewPublicAPIGatewayRuntime(
		DefaultPublicAPIGatewayRuntimeConfig(),
		apiKeyRuntime,
		appRuntime,
		quotaRuntime,
		sandboxRuntime,
		docsRuntime,
	)

	return publicAPIGatewayFixture{
		apiKeyRuntime:  apiKeyRuntime,
		appRuntime:     appRuntime,
		quotaRuntime:   quotaRuntime,
		sandboxRuntime: sandboxRuntime,
		docsRuntime:    docsRuntime,
		gateway:        gateway,
		keyResult:      keyResult,
		app:            app,
		relation:       relation,
	}
}

func TestPublicAPIGatewayRuntimeHandlesSandboxRequest(t *testing.T) {
	fixture := newPublicAPIGatewayFixture(t, 5)

	response, decision, err := fixture.gateway.HandleRequest(PublicAPIGatewayRequest{
		TenantID:    "tenant_7",
		AppID:       fixture.app.AppID,
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
		Method:      "GET",
		Path:        "/v1/products",
		Headers: map[string]string{
			"Authorization": "Bearer " + fixture.keyResult.RawSecret,
		},
	})
	if err != nil {
		t.Fatalf("gateway request failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected gateway decision allowed, got reason=%s", decision.Reason)
	}
	if !response.Allowed {
		t.Fatal("expected response allowed")
	}
	if response.KeyID != fixture.keyResult.Record.KeyID {
		t.Fatalf("expected key id %s, got %s", fixture.keyResult.Record.KeyID, response.KeyID)
	}
	if response.DataNamespace != "sandbox:tenant_7:"+fixture.app.AppID {
		t.Fatalf("unexpected namespace %s", response.DataNamespace)
	}
}

func TestPublicAPIGatewayRuntimeExtractsAPIKeyFromXAPIKeyHeader(t *testing.T) {
	fixture := newPublicAPIGatewayFixture(t, 5)

	_, decision, err := fixture.gateway.HandleRequest(PublicAPIGatewayRequest{
		TenantID:    "tenant_7",
		AppID:       fixture.app.AppID,
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
		Method:      "GET",
		Path:        "/v1/products",
		Headers: map[string]string{
			"X-API-Key": fixture.keyResult.RawSecret,
		},
	})
	if err != nil {
		t.Fatalf("gateway request failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected allowed, got reason=%s", decision.Reason)
	}
}

func TestPublicAPIGatewayRuntimeRejectsMissingAPIKey(t *testing.T) {
	fixture := newPublicAPIGatewayFixture(t, 5)

	_, decision, err := fixture.gateway.HandleRequest(PublicAPIGatewayRequest{
		TenantID:    "tenant_7",
		AppID:       fixture.app.AppID,
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
		Method:      "GET",
		Path:        "/v1/products",
		Headers:     map[string]string{},
	})
	if err != ErrPublicAPIGatewayMissingAPIKey {
		t.Fatalf("expected missing api key error, got %v", err)
	}
	if decision.Reason != PublicAPIGatewayReasonMissingAPIKey {
		t.Fatalf("expected missing api key reason, got %s", decision.Reason)
	}
}

func TestPublicAPIGatewayRuntimeRejectsInvalidAPIKey(t *testing.T) {
	fixture := newPublicAPIGatewayFixture(t, 5)

	_, decision, err := fixture.gateway.HandleRequest(PublicAPIGatewayRequest{
		TenantID:    "tenant_7",
		AppID:       fixture.app.AppID,
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
		Method:      "GET",
		Path:        "/v1/products",
		Headers: map[string]string{
			"Authorization": "Bearer pix2pi_sandbox_invalid",
		},
	})
	if err != ErrPublicAPIGatewayAPIKeyNotFound {
		t.Fatalf("expected api key not found, got %v", err)
	}
	if decision.Reason != PublicAPIGatewayReasonAPIKeyNotFound {
		t.Fatalf("expected api key not found reason, got %s", decision.Reason)
	}
}

func TestPublicAPIGatewayRuntimeRejectsCrossTenantAPIKey(t *testing.T) {
	fixture := newPublicAPIGatewayFixture(t, 5)

	_, decision, err := fixture.gateway.HandleRequest(PublicAPIGatewayRequest{
		TenantID:    "tenant_8",
		AppID:       fixture.app.AppID,
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
		Method:      "GET",
		Path:        "/v1/products",
		Headers: map[string]string{
			"Authorization": "Bearer " + fixture.keyResult.RawSecret,
		},
	})
	if err != ErrPublicAPIGatewayCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != PublicAPIGatewayReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestPublicAPIGatewayRuntimeRejectsScopeDenied(t *testing.T) {
	fixture := newPublicAPIGatewayFixture(t, 5)

	_, decision, err := fixture.gateway.HandleRequest(PublicAPIGatewayRequest{
		TenantID:    "tenant_7",
		AppID:       fixture.app.AppID,
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "admin:limited",
		Method:      "GET",
		Path:        "/v1/products",
		Headers: map[string]string{
			"Authorization": "Bearer " + fixture.keyResult.RawSecret,
		},
	})
	if err != ErrPublicAPIGatewayScopeDenied {
		t.Fatalf("expected scope denied, got %v", err)
	}
	if decision.Reason != PublicAPIGatewayReasonScopeDenied {
		t.Fatalf("expected scope denied reason, got %s", decision.Reason)
	}
}

func TestPublicAPIGatewayRuntimeRejectsProductionSandboxRequest(t *testing.T) {
	fixture := newPublicAPIGatewayFixture(t, 5)

	_, decision, err := fixture.gateway.HandleRequest(PublicAPIGatewayRequest{
		TenantID:    "tenant_7",
		AppID:       fixture.app.AppID,
		Environment: APIKeyEnvironmentProduction,
		Scope:       "read",
		Method:      "GET",
		Path:        "/v1/products",
		Headers: map[string]string{
			"Authorization": "Bearer " + fixture.keyResult.RawSecret,
		},
	})
	if err != ErrPublicAPIGatewayEnvironmentMismatch {
		t.Fatalf("expected environment mismatch before sandbox bridge, got %v", err)
	}
	if decision.Reason != PublicAPIGatewayReasonEnvironmentMismatch {
		t.Fatalf("expected environment mismatch reason, got %s", decision.Reason)
	}
}

func TestPublicAPIGatewayRuntimeQuotaBridgeDeniesAfterLimit(t *testing.T) {
	fixture := newPublicAPIGatewayFixture(t, 1)

	req := PublicAPIGatewayRequest{
		TenantID:    "tenant_7",
		AppID:       fixture.app.AppID,
		Environment: APIKeyEnvironmentSandbox,
		Scope:       "read",
		Method:      "GET",
		Path:        "/v1/products",
		Headers: map[string]string{
			"Authorization": "Bearer " + fixture.keyResult.RawSecret,
		},
	}

	_, decision, err := fixture.gateway.HandleRequest(req)
	if err != nil {
		t.Fatalf("first request failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected first allowed, got reason=%s", decision.Reason)
	}

	_, decision, err = fixture.gateway.HandleRequest(req)
	if err != ErrPublicAPIGatewayQuotaDenied {
		t.Fatalf("expected quota denied, got %v", err)
	}
	if decision.Reason != PublicAPIGatewayReasonQuotaDenied {
		t.Fatalf("expected quota denied reason, got %s", decision.Reason)
	}
}

func TestPublicAPIGatewayRuntimeDeveloperDocsBridgeMarkdown(t *testing.T) {
	fixture := newPublicAPIGatewayFixture(t, 5)

	response, decision, err := fixture.gateway.HandleDeveloperDocsRequest("/developer/docs")
	if err != nil {
		t.Fatalf("developer docs markdown failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected developer docs allowed, got reason=%s", decision.Reason)
	}
	if response.DocsFormat != PublicAPIGatewayDocsFormatMarkdown {
		t.Fatalf("expected markdown format, got %s", response.DocsFormat)
	}
	if !strings.Contains(response.DocsContent, "Pix2pi Public API") {
		t.Fatal("expected docs content to contain title")
	}
	if !strings.Contains(response.DocsContent, "Sandbox") {
		t.Fatal("expected docs content to contain sandbox section")
	}
}

func TestPublicAPIGatewayRuntimeDeveloperDocsBridgeOpenAPITrace(t *testing.T) {
	fixture := newPublicAPIGatewayFixture(t, 5)

	response, decision, err := fixture.gateway.HandleDeveloperDocsRequest("/developer/openapi-trace")
	if err != nil {
		t.Fatalf("developer docs openapi trace failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected developer docs allowed, got reason=%s", decision.Reason)
	}
	if response.DocsFormat != PublicAPIGatewayDocsFormatOpenAPITrace {
		t.Fatalf("expected openapi trace format, got %s", response.DocsFormat)
	}
	if !strings.Contains(response.DocsContent, `"openapi_trace": "3.1.0-draft-ready"`) {
		t.Fatal("expected openapi trace marker")
	}
}
