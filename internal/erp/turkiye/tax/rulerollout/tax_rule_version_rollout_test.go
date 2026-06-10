package rulerollout

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:             true,
		DefaultCountryCode:         "TR",
		ApprovalRequired:           true,
		LegalReferenceRequired:     true,
		AuditRequired:              true,
		IdempotencyRequired:        true,
		CanaryAllowed:              true,
		RollbackAllowed:            true,
		MinCanaryPercent:           1,
		MaxCanaryPercent:           25,
		RequiredEvidenceFileSuffix: ".md",
		AllowedTaxFamilies: []TaxFamily{
			TaxFamilyKDV,
			TaxFamilyStopaj,
			TaxFamilyTaxExemption,
			TaxFamilyOTV,
			TaxFamilyDamga,
			TaxFamilyCustom,
		},
		AllowedRolloutStrategies: []RolloutStrategy{
			StrategyFull,
			StrategyCanary,
			StrategyBlueGreen,
			StrategyRollback,
		},
	}
}

func version(code string, family TaxFamily, status VersionStatus) TaxRuleVersion {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return TaxRuleVersion{
		VersionID:           "ver-" + code,
		TaxFamily:           family,
		VersionCode:         code,
		PreviousVersionCode: "PREV-" + code,
		Status:              status,
		CountryCode:         "TR",
		LegalReference:      "TR tax legal reference",
		RuleArtifactPath:    "internal/erp/turkiye/tax/" + code,
		ConfigArtifactPath:  "configs/faz3/tax/" + code + ".json",
		EvidenceFilePath:    "docs/faz3/evidence/" + code + ".md",
		EvidenceHash:        "sha256:" + code,
		EffectiveFrom:       now,
		ApprovedBy:          "tax-admin",
		ApprovedAt:          now,
		CreatedAt:           now,
	}
}

func validRolloutRequest() RolloutRequest {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return RolloutRequest{
		TenantID:       "tenant-001",
		CorrelationID:  "corr-001",
		RequestID:      "req-001",
		IdempotencyKey: "idem-001",
		RolloutID:      "rollout-001",
		Strategy:       StrategyFull,
		CurrentVersion: version("TR_KDV_2026_V1", TaxFamilyKDV, VersionStatusActive),
		TargetVersion:  version("TR_KDV_2026_V2", TaxFamilyKDV, VersionStatusReady),
		RequestedBy:    "tax-admin",
		RequestedAt:    now,
	}
}

func validRollbackRequest() RollbackRequest {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return RollbackRequest{
		TenantID:        "tenant-001",
		CorrelationID:   "corr-rollback-001",
		RequestID:       "req-rollback-001",
		IdempotencyKey:  "idem-rollback-001",
		RollbackID:      "rollback-001",
		ActiveVersion:   version("TR_KDV_2026_V2", TaxFamilyKDV, VersionStatusActive),
		RollbackVersion: version("TR_KDV_2026_V1", TaxFamilyKDV, VersionStatusSuperseded),
		ReasonCode:      "TAX_RULE_ROLLBACK_TEST",
		ReasonText:      "Test rollback",
		RequestedBy:     "tax-admin",
		RequestedAt:     now,
	}
}

func TestPrepareFullRolloutReady(t *testing.T) {
	runtime, err := NewTaxRuleVersionRolloutRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	result, err := runtime.PrepareRollout(validRolloutRequest())
	if err != nil {
		t.Fatalf("prepare rollout failed: %v", err)
	}

	if result.DecisionStatus != DecisionReady {
		t.Fatalf("expected ready, got %s", result.DecisionStatus)
	}
	if result.TargetStatus != VersionStatusReady {
		t.Fatalf("expected target ready, got %s", result.TargetStatus)
	}
	if !result.RuntimeSwitchReady || !result.ConfigSwitchReady || !result.AuditReady {
		t.Fatal("expected runtime/config/audit switch ready")
	}
}

func TestPrepareCanaryRolloutStarted(t *testing.T) {
	runtime, err := NewTaxRuleVersionRolloutRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRolloutRequest()
	req.Strategy = StrategyCanary
	req.CanaryPercent = 10
	req.TenantAllowlist = []string{"tenant-001", "tenant-002"}

	result, err := runtime.PrepareRollout(req)
	if err != nil {
		t.Fatalf("prepare canary failed: %v", err)
	}

	if result.DecisionStatus != DecisionCanaryStarted {
		t.Fatalf("expected canary started, got %s", result.DecisionStatus)
	}
	if result.TargetStatus != VersionStatusCanary {
		t.Fatalf("expected canary status, got %s", result.TargetStatus)
	}
	if result.CanaryPercent != 10 {
		t.Fatalf("expected canary percent 10, got %d", result.CanaryPercent)
	}
}

func TestPrepareCanaryRejectsMissingAllowlist(t *testing.T) {
	runtime, err := NewTaxRuleVersionRolloutRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRolloutRequest()
	req.Strategy = StrategyCanary
	req.CanaryPercent = 10
	req.TenantAllowlist = nil

	result, err := runtime.PrepareRollout(req)
	if err == nil {
		t.Fatal("expected canary allowlist error")
	}
	if result.ErrorCode != "CANARY_TENANT_ALLOWLIST_REQUIRED" {
		t.Fatalf("expected CANARY_TENANT_ALLOWLIST_REQUIRED, got %s", result.ErrorCode)
	}
}

func TestActivateVersion(t *testing.T) {
	runtime, err := NewTaxRuleVersionRolloutRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	result, err := runtime.ActivateVersion(validRolloutRequest())
	if err != nil {
		t.Fatalf("activate version failed: %v", err)
	}

	if result.DecisionStatus != DecisionActivated {
		t.Fatalf("expected activated, got %s", result.DecisionStatus)
	}
	if result.TargetStatus != VersionStatusActive {
		t.Fatalf("expected target active, got %s", result.TargetStatus)
	}
}

func TestActivateRejectsTargetNotReady(t *testing.T) {
	runtime, err := NewTaxRuleVersionRolloutRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRolloutRequest()
	req.TargetVersion.Status = VersionStatusDraft

	result, err := runtime.ActivateVersion(req)
	if err == nil {
		t.Fatal("expected target not ready error")
	}
	if result.ErrorCode != "TARGET_VERSION_NOT_READY" {
		t.Fatalf("expected TARGET_VERSION_NOT_READY, got %s", result.ErrorCode)
	}
}

func TestRollbackVersion(t *testing.T) {
	runtime, err := NewTaxRuleVersionRolloutRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	result, err := runtime.RollbackVersion(validRollbackRequest())
	if err != nil {
		t.Fatalf("rollback failed: %v", err)
	}

	if result.DecisionStatus != DecisionRolledBack {
		t.Fatalf("expected rolled back, got %s", result.DecisionStatus)
	}
	if result.ActiveVersionNewStatus != VersionStatusRolledBack {
		t.Fatalf("expected active version rolled back, got %s", result.ActiveVersionNewStatus)
	}
	if result.RollbackVersionStatus != VersionStatusActive {
		t.Fatalf("expected rollback version active, got %s", result.RollbackVersionStatus)
	}
}

func TestRollbackRejectsFamilyMismatch(t *testing.T) {
	runtime, err := NewTaxRuleVersionRolloutRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRollbackRequest()
	req.RollbackVersion.TaxFamily = TaxFamilyStopaj

	result, err := runtime.RollbackVersion(req)
	if err == nil {
		t.Fatal("expected family mismatch error")
	}
	if result.ErrorCode != "ROLLBACK_TAX_FAMILY_MISMATCH" {
		t.Fatalf("expected ROLLBACK_TAX_FAMILY_MISMATCH, got %s", result.ErrorCode)
	}
}

func TestValidateRejectsEvidenceSuffix(t *testing.T) {
	runtime, err := NewTaxRuleVersionRolloutRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	req := validRolloutRequest()
	req.TargetVersion.EvidenceFilePath = "docs/faz3/evidence/bad.txt"

	result, err := runtime.PrepareRollout(req)
	if err == nil {
		t.Fatal("expected evidence suffix error")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	if _, err := NewTaxRuleVersionRolloutRuntime(cfg); err == nil {
		t.Fatal("expected disabled runtime error")
	}
}
