package sandboxsurface

import "testing"

func TestSandboxSurfacePassesInternalReadiness(t *testing.T) {
	input := validSandboxInput()

	result, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}

	if result.Status != "PASS" {
		t.Fatalf("expected PASS got %s findings=%v", result.Status, result.Findings)
	}
	if result.RequiredFailCount != 0 {
		t.Fatalf("expected zero required fails got %d", result.RequiredFailCount)
	}
	if !result.InternalSandboxSurfaceReady {
		t.Fatal("internal sandbox surface readiness must be true")
	}
	if !result.StaticHTMLReady {
		t.Fatal("static HTML readiness must be true")
	}
	if result.ProductionSandboxPublished {
		t.Fatal("production sandbox must remain unpublished")
	}
	if result.RealDeveloperAccessEnabled {
		t.Fatal("real developer access must remain disabled")
	}
	if result.LiveAPICallEnabled {
		t.Fatal("live API call must remain disabled")
	}
	if result.LiveDataMutationEnabled {
		t.Fatal("live data mutation must remain disabled")
	}
	if result.PaymentSimulationLiveEnabled {
		t.Fatal("payment simulation live must remain disabled")
	}
	if result.APIKeyCreationEnabled {
		t.Fatal("API key creation must remain disabled")
	}
	if err := MustPass(result); err != nil {
		t.Fatal(err)
	}
}

func TestSandboxSurfaceBlocksLiveAPICall(t *testing.T) {
	input := validSandboxInput()
	input.LiveAPICallEnabled = true

	result, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}
	if result.Status != "FAIL" {
		t.Fatalf("expected FAIL got %s", result.Status)
	}
	if result.RequiredFailCount == 0 {
		t.Fatal("expected required fail")
	}
}

func TestSandboxSurfaceRequiresMockCredential(t *testing.T) {
	input := validSandboxInput()
	input.Sections[0].RequiresMockCredential = false

	result, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}
	if result.Status != "FAIL" {
		t.Fatalf("expected FAIL got %s", result.Status)
	}
	if result.RequiredFailCount == 0 {
		t.Fatal("expected required fail")
	}
}

func TestSandboxSurfaceRequiresDeferredReason(t *testing.T) {
	input := validSandboxInput()
	for idx := range input.Sections {
		if input.Sections[idx].DeferredToPricingPages {
			input.Sections[idx].DeferredReason = ""
		}
	}

	result, err := Evaluate(input)
	if err != nil {
		t.Fatal(err)
	}
	if result.Status != "FAIL" {
		t.Fatalf("expected FAIL got %s", result.Status)
	}
	if result.RequiredFailCount == 0 {
		t.Fatal("expected required fail")
	}
}

func TestRequiredSectionKeysSorted(t *testing.T) {
	input := SandboxInput{RequiredSectionKeys: []string{"webhook_mock_panel", "mock_credentials_panel"}}
	keys := RequiredSectionKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}
	if keys[0] != "mock_credentials_panel" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validSandboxInput() SandboxInput {
	return SandboxInput{
		Phase:                        "FAZ_5_19_5",
		Target:                       "FAZ_5_R_SANDBOX_USAGE_SURFACE",
		InternalSandboxSurfaceReady:  true,
		StaticHTMLReady:              true,
		ProductionSandboxPublished:   false,
		RealDeveloperAccessEnabled:   false,
		LiveAPICallEnabled:           false,
		LiveDataMutationEnabled:      false,
		PaymentSimulationLiveEnabled: false,
		APIKeyCreationEnabled:        false,
		RequiredSectionKeys: []string{
			"sandbox_overview",
			"mock_credentials_panel",
			"sample_requests_panel",
			"sample_responses_panel",
			"webhook_mock_panel",
			"tenant_scope_panel",
			"data_reset_policy_panel",
			"security_notice_panel",
			"pricing_pages_deferred_marker",
		},
		RequiredDomains: []SandboxDomain{
			DomainSandboxOverview,
			DomainMockCredential,
			DomainAPISample,
			DomainWebhookMock,
			DomainTenantScope,
			DomainDataReset,
			DomainSecurity,
			DomainPricingNext,
		},
		RequireEvidence:                   true,
		RequireCounterBasedAudit:          true,
		RequireNoRequiredFail:             true,
		RequireNoOptionalWarn:             true,
		RequireTenantID:                   true,
		RequireMockCredential:             true,
		RequireSampleRequest:              true,
		RequireSampleResponse:             true,
		RequireTenantIsolationNotice:      true,
		RequireRateLimitPreview:           true,
		RequireWebhookMockGuide:           true,
		RequireDataResetPolicy:            true,
		RequireAuditTrail:                 true,
		RequireSecurityNotice:             true,
		RequireSupportPath:                true,
		RequireLegalReview:                true,
		RequireFounderApproval:            true,
		RequireChangeLog:                  true,
		RequireProductionPublishBlock:     true,
		RequireRealDeveloperAccessBlock:   true,
		RequireLiveAPICallBlock:           true,
		RequireLiveDataMutationBlock:      true,
		RequirePaymentSimulationLiveBlock: true,
		RequireAPIKeyCreationBlock:        true,
		AllowPricingPagesDeferred:         true,
		Sections: []SandboxSection{
			section("sandbox_overview", DomainSandboxOverview, "Sandbox Overview"),
			section("mock_credentials_panel", DomainMockCredential, "Mock Credentials Panel"),
			section("sample_requests_panel", DomainAPISample, "Sample Requests Panel"),
			section("sample_responses_panel", DomainAPISample, "Sample Responses Panel"),
			section("webhook_mock_panel", DomainWebhookMock, "Webhook Mock Panel"),
			section("tenant_scope_panel", DomainTenantScope, "Tenant Scope Panel"),
			section("data_reset_policy_panel", DomainDataReset, "Data Reset Policy Panel"),
			section("security_notice_panel", DomainSecurity, "Security Notice Panel"),
			deferred("pricing_pages_deferred_marker", DomainPricingNext, "Fiyatlama Sayfaları Deferred Marker"),
		},
	}
}

func section(key string, domain SandboxDomain, title string) SandboxSection {
	return SandboxSection{
		Key:                           key,
		Domain:                        domain,
		Title:                         title,
		Owner:                         "developer_platform_ops",
		Status:                        StatusReady,
		Required:                      true,
		HasEvidence:                   true,
		HasCounterBasedAudit:          true,
		RequiredFailCount:             0,
		OptionalWarnCount:             0,
		ProductionSandboxPublished:    false,
		RealDeveloperAccessEnabled:    false,
		LiveAPICallEnabled:            false,
		LiveDataMutationEnabled:       false,
		PaymentSimulationLiveEnabled:  false,
		APIKeyCreationEnabled:         false,
		RequiresTenantID:              true,
		RequiresMockCredential:        true,
		RequiresSampleRequest:         true,
		RequiresSampleResponse:        true,
		RequiresTenantIsolationNotice: true,
		RequiresRateLimitPreview:      true,
		RequiresWebhookMockGuide:      true,
		RequiresDataResetPolicy:       true,
		RequiresAuditTrail:            true,
		RequiresSecurityNotice:        true,
		RequiresSupportPath:           true,
		RequiresLegalReview:           true,
		RequiresFounderApproval:       true,
		RequiresChangeLog:             true,
		BlocksProductionPublish:       true,
		BlocksRealDeveloperAccess:     true,
		BlocksLiveAPICall:             true,
		BlocksLiveDataMutation:        true,
		BlocksPaymentSimulationLive:   true,
		BlocksAPIKeyCreation:          true,
		DeferredToPricingPages:        false,
	}
}

func deferred(key string, domain SandboxDomain, title string) SandboxSection {
	s := section(key, domain, title)
	s.Status = StatusPendingNext
	s.DeferredToPricingPages = true
	s.DeferredReason = "Fiyatlama sayfaları 278 — FAZ 5-19.2 içinde açılacak"
	return s
}
