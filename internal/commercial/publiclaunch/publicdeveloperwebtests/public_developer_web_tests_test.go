package publicdeveloperwebtests

import "testing"

func TestPublicDeveloperWebTestsPassInternalReadiness(t *testing.T) {
	input := validWebTestInput()

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
	if !result.InternalWebTestsReady {
		t.Fatal("internal web tests readiness must be true")
	}
	if !result.PublicDeveloperSurfaceTestsReady {
		t.Fatal("public developer surface tests readiness must be true")
	}
	if result.ProductionPublishAllowed {
		t.Fatal("production publish must remain disabled")
	}
	if result.RealCustomerAccessEnabled {
		t.Fatal("real customer access must remain disabled")
	}
	if result.RealDeveloperAccessEnabled {
		t.Fatal("real developer access must remain disabled")
	}
	if result.CheckoutEnabled {
		t.Fatal("checkout must remain disabled")
	}
	if result.PaymentCollectionEnabled {
		t.Fatal("payment collection must remain disabled")
	}
	if result.APIKeyCreationEnabled {
		t.Fatal("api key creation must remain disabled")
	}
	if result.SandboxLiveEnabled {
		t.Fatal("sandbox live must remain disabled")
	}
	if err := MustPass(result); err != nil {
		t.Fatal(err)
	}
}

func TestPublicDeveloperWebTestsBlockProductionPublish(t *testing.T) {
	input := validWebTestInput()
	input.ProductionPublishAllowed = true

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

func TestPublicDeveloperWebTestsRequireNoIndex(t *testing.T) {
	input := validWebTestInput()
	input.Surfaces[0].HasNoIndex = false

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

func TestPublicDeveloperWebTestsRequireDeferredReason(t *testing.T) {
	input := validWebTestInput()
	for idx := range input.Surfaces {
		if input.Surfaces[idx].DeferredToFinalClosure {
			input.Surfaces[idx].DeferredReason = ""
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

func TestRequiredSurfaceKeysSorted(t *testing.T) {
	input := WebTestInput{RequiredSurfaceKeys: []string{"pricing_pages_web", "developer_docs_web"}}
	keys := RequiredSurfaceKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}
	if keys[0] != "developer_docs_web" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validWebTestInput() WebTestInput {
	return WebTestInput{
		Phase:                            "FAZ_5_19_6",
		Target:                           "FAZ_5_R_PUBLIC_DEVELOPER_WEB_TESTS",
		InternalWebTestsReady:            true,
		PublicDeveloperSurfaceTestsReady: true,
		ProductionPublishAllowed:         false,
		RealCustomerAccessEnabled:        false,
		RealDeveloperAccessEnabled:       false,
		CheckoutEnabled:                  false,
		PaymentCollectionEnabled:         false,
		APIKeyCreationEnabled:            false,
		SandboxLiveEnabled:               false,
		RequiredSurfaceKeys: []string{
			"developer_docs_web",
			"api_key_management_web",
			"sandbox_surface_web",
			"pricing_pages_web",
			"launch_guard_matrix",
			"html_quality_matrix",
			"security_guard_matrix",
			"final_closure_deferred_marker",
		},
		RequiredDomains: []SurfaceDomain{
			DomainDeveloperDocs,
			DomainAPIKeyScreen,
			DomainSandbox,
			DomainPricingPages,
			DomainLaunchGuard,
			DomainHTMLQuality,
			DomainSecurity,
			DomainClosureNext,
		},
		RequireEvidence:                        true,
		RequireCounterBasedAudit:               true,
		RequireNoRequiredFail:                  true,
		RequireNoOptionalWarn:                  true,
		RequireStaticHTMLReady:                 true,
		RequireFileExists:                      true,
		RequireNoIndex:                         true,
		RequireViewport:                        true,
		RequireStartMarker:                     true,
		RequireLaunchGuard:                     true,
		RequireProductionDisabledMarker:        true,
		RequireRealAccessDisabledMarker:        true,
		RequireCheckoutDisabledMarker:          true,
		RequirePaymentCollectionDisabledMarker: true,
		RequireAPIKeyCreationDisabledMarker:    true,
		RequireSandboxLiveDisabledMarker:       true,
		RequireTenantSafetyText:                true,
		RequireSecurityNotice:                  true,
		RequireSupportPath:                     true,
		RequireProductionPublishBlock:          true,
		RequireRealCustomerBlock:               true,
		RequireRealDeveloperAccessBlock:        true,
		RequireCheckoutBlock:                   true,
		RequirePaymentCollectionBlock:          true,
		RequireAPIKeyCreationBlock:             true,
		RequireSandboxLiveBlock:                true,
		AllowFinalClosureDeferred:              true,
		Surfaces: []WebSurface{
			surface("developer_docs_web", DomainDeveloperDocs, "Developer Docs Web", "web/faz5r/developer-docs/index.html"),
			surface("api_key_management_web", DomainAPIKeyScreen, "API Key Management Web", "web/faz5r/api-key-management/index.html"),
			surface("sandbox_surface_web", DomainSandbox, "Sandbox Surface Web", "web/faz5r/sandbox-surface/index.html"),
			surface("pricing_pages_web", DomainPricingPages, "Pricing Pages Web", "web/faz5r/pricing-pages/index.html"),
			surface("launch_guard_matrix", DomainLaunchGuard, "Launch Guard Matrix", "configs/faz5r/public_developer_web_tests.public_launch.v1.json"),
			surface("html_quality_matrix", DomainHTMLQuality, "HTML Quality Matrix", "tests/faz5r/faz_5_19_6_public_developer_web_testleri_test.json"),
			surface("security_guard_matrix", DomainSecurity, "Security Guard Matrix", "configs/faz5r/public_developer_web_tests.public_launch.v1.json"),
			deferred("final_closure_deferred_marker", DomainClosureNext, "FAZ 5-R Final Closure Deferred Marker"),
		},
	}
}

func surface(key string, domain SurfaceDomain, title string, path string) WebSurface {
	return WebSurface{
		Key:                                     key,
		Domain:                                  domain,
		Title:                                   title,
		Path:                                    path,
		Owner:                                   "commercial_web_ops",
		Status:                                  StatusReady,
		Required:                                true,
		HasEvidence:                             true,
		HasCounterBasedAudit:                    true,
		RequiredFailCount:                       0,
		OptionalWarnCount:                       0,
		StaticHTMLReady:                         true,
		HasNoIndex:                              true,
		HasViewport:                             true,
		HasStartMarker:                          true,
		HasLaunchGuard:                          true,
		HasProductionDisabledMarker:             true,
		HasRealAccessDisabledMarker:             true,
		HasCheckoutDisabledMarker:               true,
		HasPaymentCollectionDisabledMarker:      true,
		HasAPIKeyCreationDisabledMarker:         true,
		HasSandboxLiveDisabledMarker:            true,
		HasTenantSafetyText:                     true,
		HasSecurityNotice:                       true,
		HasSupportPath:                          true,
		ProductionPublished:                     false,
		RealCustomerEnabled:                     false,
		RealDeveloperAccessEnabled:              false,
		CheckoutEnabled:                         false,
		PaymentCollectionEnabled:                false,
		APIKeyCreationEnabled:                   false,
		SandboxLiveEnabled:                      false,
		RequiresFileExists:                      true,
		RequiresNoIndex:                         true,
		RequiresViewport:                        true,
		RequiresStartMarker:                     true,
		RequiresLaunchGuard:                     true,
		RequiresProductionDisabledMarker:        true,
		RequiresRealAccessDisabledMarker:        true,
		RequiresCheckoutDisabledMarker:          true,
		RequiresPaymentCollectionDisabledMarker: true,
		RequiresAPIKeyCreationDisabledMarker:    true,
		RequiresSandboxLiveDisabledMarker:       true,
		RequiresTenantSafetyText:                true,
		RequiresSecurityNotice:                  true,
		RequiresSupportPath:                     true,
		BlocksProductionPublish:                 true,
		BlocksRealCustomer:                      true,
		BlocksRealDeveloperAccess:               true,
		BlocksCheckout:                          true,
		BlocksPaymentCollection:                 true,
		BlocksAPIKeyCreation:                    true,
		BlocksSandboxLive:                       true,
		DeferredToFinalClosure:                  false,
	}
}

func deferred(key string, domain SurfaceDomain, title string) WebSurface {
	s := surface(key, domain, title, "docs/faz5r/FAZ_5_R_FINAL_CLOSURE_PENDING.md")
	s.Status = StatusPendingNext
	s.DeferredToFinalClosure = true
	s.DeferredReason = "FAZ 5-R final review / closure sonraki adımda açılacak"
	return s
}
