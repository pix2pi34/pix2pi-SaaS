package apikeymanagementscreen

import "testing"

func TestAPIKeyManagementScreenPassesInternalReadiness(t *testing.T) {
	input := validScreenInput()

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
	if !result.InternalAPIKeyScreenReady {
		t.Fatal("internal API key screen readiness must be true")
	}
	if !result.StaticHTMLReady {
		t.Fatal("static HTML readiness must be true")
	}
	if result.ProductionScreenPublished {
		t.Fatal("production screen must remain unpublished")
	}
	if result.RealDeveloperAccessEnabled {
		t.Fatal("real developer access must remain disabled")
	}
	if result.APIKeyCreationEnabled {
		t.Fatal("API key creation must remain disabled")
	}
	if result.APIKeyRevealEnabled {
		t.Fatal("API key reveal must remain disabled")
	}
	if result.APIKeyRotationEnabled {
		t.Fatal("API key rotation must remain disabled")
	}
	if result.SandboxLiveEnabled {
		t.Fatal("sandbox live must remain disabled")
	}
	if err := MustPass(result); err != nil {
		t.Fatal(err)
	}
}

func TestAPIKeyManagementScreenBlocksCreation(t *testing.T) {
	input := validScreenInput()
	input.APIKeyCreationEnabled = true

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

func TestAPIKeyManagementScreenRequiresMaskedSecret(t *testing.T) {
	input := validScreenInput()
	input.Sections[0].RequiresMaskedSecretDisplay = false

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

func TestAPIKeyManagementScreenRequiresDeferredReason(t *testing.T) {
	input := validScreenInput()
	for idx := range input.Sections {
		if input.Sections[idx].DeferredToSandboxSurface {
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
	input := ScreenInput{RequiredSectionKeys: []string{"key_rotation_preview", "key_inventory"}}
	keys := RequiredSectionKeys(input)

	if len(keys) != 2 {
		t.Fatalf("expected 2 keys got %d", len(keys))
	}
	if keys[0] != "key_inventory" {
		t.Fatalf("expected sorted keys got %v", keys)
	}
}

func validScreenInput() ScreenInput {
	return ScreenInput{
		Phase:                      "FAZ_5_19_4",
		Target:                     "FAZ_5_R_API_KEY_MANAGEMENT_SCREEN",
		InternalAPIKeyScreenReady:  true,
		StaticHTMLReady:            true,
		ProductionScreenPublished:  false,
		RealDeveloperAccessEnabled: false,
		APIKeyCreationEnabled:      false,
		APIKeyRevealEnabled:        false,
		APIKeyRotationEnabled:      false,
		SandboxLiveEnabled:         false,
		RequiredSectionKeys: []string{
			"key_inventory",
			"key_create_disabled_panel",
			"key_masked_secret_panel",
			"key_rotation_preview",
			"key_revoke_preview",
			"permission_scope_panel",
			"tenant_scope_panel",
			"audit_trail_panel",
			"security_policy_panel",
			"sandbox_surface_deferred_marker",
		},
		RequiredDomains: []ScreenDomain{
			DomainKeyInventory,
			DomainKeyLifecycle,
			DomainPermission,
			DomainTenantScope,
			DomainAudit,
			DomainSecurity,
			DomainSandboxNext,
		},
		RequireEvidence:                 true,
		RequireCounterBasedAudit:        true,
		RequireNoRequiredFail:           true,
		RequireNoOptionalWarn:           true,
		RequireTenantID:                 true,
		RequireDeveloperAccount:         true,
		RequireRoleGuard:                true,
		RequirePermissionScope:          true,
		RequireKeyName:                  true,
		RequireMaskedSecretDisplay:      true,
		RequireCreateDisabledGuard:      true,
		RequireRevealDisabledGuard:      true,
		RequireRotateDisabledGuard:      true,
		RequireRevokePreview:            true,
		RequireAuditTrail:               true,
		RequireRateLimitPolicy:          true,
		RequireExpiryPolicy:             true,
		RequireSecurityNotice:           true,
		RequireLegalReview:              true,
		RequireFounderApproval:          true,
		RequireChangeLog:                true,
		RequireProductionPublishBlock:   true,
		RequireRealDeveloperAccessBlock: true,
		RequireAPIKeyCreationBlock:      true,
		RequireAPIKeyRevealBlock:        true,
		RequireAPIKeyRotationBlock:      true,
		RequireSandboxLiveBlock:         true,
		AllowSandboxSurfaceDeferred:     true,
		Sections: []ScreenSection{
			section("key_inventory", DomainKeyInventory, "API Key Inventory"),
			section("key_create_disabled_panel", DomainKeyLifecycle, "API Key Create Disabled Panel"),
			section("key_masked_secret_panel", DomainKeyLifecycle, "Masked Secret Panel"),
			section("key_rotation_preview", DomainKeyLifecycle, "Key Rotation Preview"),
			section("key_revoke_preview", DomainKeyLifecycle, "Key Revoke Preview"),
			section("permission_scope_panel", DomainPermission, "Permission Scope Panel"),
			section("tenant_scope_panel", DomainTenantScope, "Tenant Scope Panel"),
			section("audit_trail_panel", DomainAudit, "Audit Trail Panel"),
			section("security_policy_panel", DomainSecurity, "Security Policy Panel"),
			deferred("sandbox_surface_deferred_marker", DomainSandboxNext, "Sandbox Kullanım Yüzeyi Deferred Marker"),
		},
	}
}

func section(key string, domain ScreenDomain, title string) ScreenSection {
	return ScreenSection{
		Key:                         key,
		Domain:                      domain,
		Title:                       title,
		Owner:                       "developer_platform_ops",
		Status:                      StatusReady,
		Required:                    true,
		HasEvidence:                 true,
		HasCounterBasedAudit:        true,
		RequiredFailCount:           0,
		OptionalWarnCount:           0,
		ProductionScreenPublished:   false,
		RealDeveloperAccessEnabled:  false,
		APIKeyCreationEnabled:       false,
		APIKeyRevealEnabled:         false,
		APIKeyRotationEnabled:       false,
		SandboxLiveEnabled:          false,
		RequiresTenantID:            true,
		RequiresDeveloperAccount:    true,
		RequiresRoleGuard:           true,
		RequiresPermissionScope:     true,
		RequiresKeyName:             true,
		RequiresMaskedSecretDisplay: true,
		RequiresCreateDisabledGuard: true,
		RequiresRevealDisabledGuard: true,
		RequiresRotateDisabledGuard: true,
		RequiresRevokePreview:       true,
		RequiresAuditTrail:          true,
		RequiresRateLimitPolicy:     true,
		RequiresExpiryPolicy:        true,
		RequiresSecurityNotice:      true,
		RequiresLegalReview:         true,
		RequiresFounderApproval:     true,
		RequiresChangeLog:           true,
		BlocksProductionPublish:     true,
		BlocksRealDeveloperAccess:   true,
		BlocksAPIKeyCreation:        true,
		BlocksAPIKeyReveal:          true,
		BlocksAPIKeyRotation:        true,
		BlocksSandboxLive:           true,
		DeferredToSandboxSurface:    false,
	}
}

func deferred(key string, domain ScreenDomain, title string) ScreenSection {
	s := section(key, domain, title)
	s.Status = StatusPendingNext
	s.DeferredToSandboxSurface = true
	s.DeferredReason = "Sandbox kullanım yüzeyi 277 — FAZ 5-19.5 içinde açılacak"
	return s
}
