package developerdocsportal

import "testing"

func TestDeveloperDocsPortalPassesInternalReadiness(t *testing.T) {
	input := validPortalInput()

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

	if !result.InternalDeveloperDocsPortalReady {
		t.Fatal("internal developer docs portal readiness must be true")
	}

	if !result.StaticHTMLReady {
		t.Fatal("static HTML readiness must be true")
	}

	if result.ProductionDocsPublished {
		t.Fatal("production docs must remain unpublished")
	}

	if result.RealDeveloperAccessEnabled {
		t.Fatal("real developer access must remain disabled")
	}

	if result.APIKeyCreationEnabled {
		t.Fatal("API key creation must remain disabled")
	}

	if result.SandboxLiveEnabled {
		t.Fatal("sandbox live must remain disabled")
	}

	if err := MustPass(result); err != nil {
		t.Fatal(err)
	}
}

func TestDeveloperDocsPortalBlocksProductionPublish(t *testing.T) {
	input := validPortalInput()
	input.ProductionDocsPublished = true

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

func TestDeveloperDocsPortalRequiresAuthGuide(t *testing.T) {
	input := validPortalInput()
	input.Sections[0].RequiresAuthGuide = false

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

func TestDeveloperDocsPortalRequiresDeferredReason(t *testing.T) {
	input := validPortalInput()

	for idx := range input.Sections {
		if input.Sections[idx].DeferredToAPIKeyManagementScreen {
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
	input := PortalInput{RequiredSectionKeys: []string{"webhook_docs", "authentication_docs"}}
	keys := RequiredSectionKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}
	if keys[0] != "authentication_docs" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validPortalInput() PortalInput {
	return PortalInput{
		Phase:                            "FAZ_5_19_3",
		Target:                           "FAZ_5_R_DEVELOPER_DOCS_PORTAL",
		InternalDeveloperDocsPortalReady: true,
		StaticHTMLReady:                  true,
		ProductionDocsPublished:          false,
		RealDeveloperAccessEnabled:       false,
		APIKeyCreationEnabled:            false,
		SandboxLiveEnabled:               false,
		RequiredSectionKeys: []string{
			"developer_overview",
			"authentication_docs",
			"tenant_context_docs",
			"api_reference_docs",
			"webhook_docs",
			"sandbox_usage_docs",
			"security_compliance_docs",
			"support_sla_docs",
			"api_key_screen_deferred_marker",
		},
		RequiredDomains: []DocsDomain{
			DomainOverview,
			DomainAuthAPI,
			DomainTenantAPI,
			DomainAPIReference,
			DomainWebhookAPI,
			DomainSandbox,
			DomainSecurity,
			DomainSupport,
			DomainNextPriority,
		},
		RequireEvidence:                     true,
		RequireCounterBasedAudit:            true,
		RequireNoRequiredFail:               true,
		RequireNoOptionalWarn:               true,
		RequirePublicCopyGuard:              true,
		RequireVersioning:                   true,
		RequireEndpointCatalog:              true,
		RequireAuthGuide:                    true,
		RequireTenantHeaderGuide:            true,
		RequireRateLimitNotice:              true,
		RequireWebhookGuide:                 true,
		RequireSandboxGuide:                 true,
		RequireSecurityNotice:               true,
		RequireSupportPath:                  true,
		RequireLegalReview:                  true,
		RequireFounderApproval:              true,
		RequireChangeLog:                    true,
		RequireAuditTrail:                   true,
		RequireProductionPublishBlock:       true,
		RequireRealDeveloperAccessBlock:     true,
		RequireAPIKeyCreationBlock:          true,
		RequireSandboxLiveBlock:             true,
		AllowAPIKeyManagementScreenDeferred: true,
		Sections: []DocsSection{
			section("developer_overview", DomainOverview, "Developer Overview"),
			section("authentication_docs", DomainAuthAPI, "Authentication Docs"),
			section("tenant_context_docs", DomainTenantAPI, "Tenant Context Docs"),
			section("api_reference_docs", DomainAPIReference, "API Reference Docs"),
			section("webhook_docs", DomainWebhookAPI, "Webhook Docs"),
			section("sandbox_usage_docs", DomainSandbox, "Sandbox Usage Docs"),
			section("security_compliance_docs", DomainSecurity, "Security Compliance Docs"),
			section("support_sla_docs", DomainSupport, "Support SLA Docs"),
			deferred("api_key_screen_deferred_marker", DomainNextPriority, "API Key Yönetim Ekranı Deferred Marker"),
		},
	}
}

func section(key string, domain DocsDomain, title string) DocsSection {
	return DocsSection{
		Key:                              key,
		Domain:                           domain,
		Title:                            title,
		Owner:                            "developer_platform_ops",
		Status:                           StatusReady,
		Required:                         true,
		HasEvidence:                      true,
		HasCounterBasedAudit:             true,
		RequiredFailCount:                0,
		OptionalWarnCount:                0,
		ProductionDocsPublished:          false,
		RealDeveloperAccessEnabled:       false,
		APIKeyCreationEnabled:            false,
		SandboxLiveEnabled:               false,
		RequiresPublicCopyGuard:          true,
		RequiresVersioning:               true,
		RequiresEndpointCatalog:          true,
		RequiresAuthGuide:                true,
		RequiresTenantHeaderGuide:        true,
		RequiresRateLimitNotice:          true,
		RequiresWebhookGuide:             true,
		RequiresSandboxGuide:             true,
		RequiresSecurityNotice:           true,
		RequiresSupportPath:              true,
		RequiresLegalReview:              true,
		RequiresFounderApproval:          true,
		RequiresChangeLog:                true,
		RequiresAuditTrail:               true,
		BlocksProductionPublish:          true,
		BlocksRealDeveloperAccess:        true,
		BlocksAPIKeyCreation:             true,
		BlocksSandboxLive:                true,
		DeferredToAPIKeyManagementScreen: false,
	}
}

func deferred(key string, domain DocsDomain, title string) DocsSection {
	s := section(key, domain, title)
	s.Status = StatusPendingNext
	s.DeferredToAPIKeyManagementScreen = true
	s.DeferredReason = "API key yönetim ekranı 276 — FAZ 5-19.4 içinde açılacak"
	return s
}
