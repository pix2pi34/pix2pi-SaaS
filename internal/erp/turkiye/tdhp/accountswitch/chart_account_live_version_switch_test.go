package accountswitch

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:             true,
		DefaultCountryCode:         "TR",
		DefaultCurrencyCode:        "TRY",
		ApprovalRequired:           true,
		EvidenceRequired:           true,
		IdempotencyRequired:        true,
		CanaryAllowed:              true,
		RollbackAllowed:            true,
		MinCanaryPercent:           1,
		MaxCanaryPercent:           25,
		RequiredEvidenceFileSuffix: ".md",
		AllowedStrategies: []SwitchStrategy{
			StrategyFull,
			StrategyCanary,
			StrategyBlueGreen,
			StrategyRollback,
		},
		RequiredPurposes: []AccountPurpose{
			PurposeReceivable,
			PurposeSales,
			PurposeOutputKDV,
			PurposeInventory,
			PurposeInputKDV,
			PurposePayable,
			PurposeBank,
		},
	}
}

func chartRules() []ChartAccountRule {
	return []ChartAccountRule{
		{Purpose: PurposeReceivable, AccountCode: "120.01", AccountName: "Alıcılar", RequiredPrefix: "120", Active: true},
		{Purpose: PurposeSales, AccountCode: "600.01", AccountName: "Yurt içi satışlar", RequiredPrefix: "600", Active: true},
		{Purpose: PurposeOutputKDV, AccountCode: "391.01.20", AccountName: "Hesaplanan KDV", RequiredPrefix: "391", Active: true},
		{Purpose: PurposeInventory, AccountCode: "153.01", AccountName: "Ticari mallar", RequiredPrefix: "153", Active: true},
		{Purpose: PurposeInputKDV, AccountCode: "191.01.20", AccountName: "İndirilecek KDV", RequiredPrefix: "191", Active: true},
		{Purpose: PurposePayable, AccountCode: "320.01", AccountName: "Satıcılar", RequiredPrefix: "320", Active: true},
		{Purpose: PurposeBank, AccountCode: "102.01", AccountName: "Bankalar", RequiredPrefix: "102", Active: true},
		{Purpose: PurposeSalesReturn, AccountCode: "610.01", AccountName: "Satıştan iadeler", RequiredPrefix: "610", Active: true},
		{Purpose: PurposeOpeningBalance, AccountCode: "500.01", AccountName: "Sermaye", RequiredPrefix: "500", Active: true},
	}
}

func version(code string, status ChartVersionStatus) ChartVersion {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return ChartVersion{
		VersionID:           "chart-" + code,
		VersionCode:         code,
		PreviousVersion:     "PREV-" + code,
		Status:              status,
		CountryCode:         "TR",
		CurrencyCode:        "TRY",
		LegalReference:      "TR TDHP legal reference",
		ChartArtifactPath:   "configs/faz3/tdhp/" + code + ".json",
		MappingArtifactPath: "configs/faz3/tdhp/" + code + ".mapping.json",
		ConfigArtifactPath:  "configs/faz3/tdhp/" + code + ".config.json",
		EvidenceFilePath:    "docs/faz3/evidence/" + code + ".md",
		EvidenceHash:        "sha256:" + code,
		Rules:               chartRules(),
		EffectiveFrom:       now,
		ApprovedBy:          "tdhp-admin",
		ApprovedAt:          now,
		CreatedAt:           now,
	}
}

func validSwitchRequest() SwitchRequest {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return SwitchRequest{
		TenantID:       "tenant-001",
		CorrelationID:  "corr-001",
		RequestID:      "req-001",
		IdempotencyKey: "idem-switch-001",
		SwitchID:       "switch-001",
		Strategy:       StrategyFull,
		CurrentVersion: version("TR_TDHP_2026_V1", ChartVersionActive),
		TargetVersion:  version("TR_TDHP_2026_V2", ChartVersionReady),
		RequestedBy:    "tdhp-admin",
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
		ActiveVersion:   version("TR_TDHP_2026_V2", ChartVersionActive),
		RollbackVersion: version("TR_TDHP_2026_V1", ChartVersionSuperseded),
		ReasonCode:      "TDHP_SWITCH_ROLLBACK_TEST",
		ReasonText:      "Test rollback",
		RequestedBy:     "tdhp-admin",
		RequestedAt:     now,
	}
}

func newRuntime(t *testing.T) *ChartAccountLiveSwitchRuntime {
	t.Helper()

	runtime, err := NewChartAccountLiveSwitchRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	return runtime
}

func TestPrepareFullSwitchReady(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.PrepareSwitch(validSwitchRequest())
	if err != nil {
		t.Fatalf("prepare switch failed: %v", err)
	}

	if result.DecisionStatus != DecisionReady {
		t.Fatalf("expected READY, got %s", result.DecisionStatus)
	}
	if !result.RuntimeSwitchReady || !result.ConfigSwitchReady || !result.MappingReady || !result.AuditReady {
		t.Fatal("expected runtime/config/mapping/audit ready")
	}
}

func TestPrepareCanarySwitchStarted(t *testing.T) {
	runtime := newRuntime(t)

	req := validSwitchRequest()
	req.Strategy = StrategyCanary
	req.CanaryPercent = 10
	req.TenantAllowlist = []string{"tenant-001", "tenant-002"}

	result, err := runtime.PrepareSwitch(req)
	if err != nil {
		t.Fatalf("prepare canary failed: %v", err)
	}

	if result.DecisionStatus != DecisionCanaryStarted {
		t.Fatalf("expected CANARY_STARTED, got %s", result.DecisionStatus)
	}
	if result.TargetStatus != ChartVersionCanary {
		t.Fatalf("expected CANARY target status, got %s", result.TargetStatus)
	}
}

func TestPrepareCanaryRejectsMissingAllowlist(t *testing.T) {
	runtime := newRuntime(t)

	req := validSwitchRequest()
	req.Strategy = StrategyCanary
	req.CanaryPercent = 10

	result, err := runtime.PrepareSwitch(req)
	if err == nil {
		t.Fatal("expected canary allowlist error")
	}
	if result.ErrorCode != "CANARY_TENANT_ALLOWLIST_REQUIRED" {
		t.Fatalf("expected CANARY_TENANT_ALLOWLIST_REQUIRED, got %s", result.ErrorCode)
	}
}

func TestActivateSwitch(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.ActivateSwitch(validSwitchRequest())
	if err != nil {
		t.Fatalf("activate switch failed: %v", err)
	}

	if result.DecisionStatus != DecisionActivated {
		t.Fatalf("expected ACTIVATED, got %s", result.DecisionStatus)
	}
	if result.TargetStatus != ChartVersionActive {
		t.Fatalf("expected ACTIVE target status, got %s", result.TargetStatus)
	}
}

func TestActivateRejectsTargetNotReady(t *testing.T) {
	runtime := newRuntime(t)

	req := validSwitchRequest()
	req.TargetVersion.Status = ChartVersionDraft

	result, err := runtime.ActivateSwitch(req)
	if err == nil {
		t.Fatal("expected target not ready error")
	}
	if result.ErrorCode != "TARGET_VERSION_NOT_READY" {
		t.Fatalf("expected TARGET_VERSION_NOT_READY, got %s", result.ErrorCode)
	}
}

func TestRollbackSwitch(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.RollbackSwitch(validRollbackRequest())
	if err != nil {
		t.Fatalf("rollback failed: %v", err)
	}

	if result.DecisionStatus != DecisionRolledBack {
		t.Fatalf("expected ROLLED_BACK, got %s", result.DecisionStatus)
	}
	if result.ActiveVersionNewStatus != ChartVersionRolledBack {
		t.Fatalf("expected active version rolled back, got %s", result.ActiveVersionNewStatus)
	}
	if result.RollbackVersionStatus != ChartVersionActive {
		t.Fatalf("expected rollback version active, got %s", result.RollbackVersionStatus)
	}
}

func TestResolveAccount(t *testing.T) {
	runtime := newRuntime(t)
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	result, err := runtime.ResolveAccount(version("TR_TDHP_2026_V1", ChartVersionActive), ResolveRequest{
		TenantID:        "tenant-001",
		VersionCode:     "TR_TDHP_2026_V1",
		Purpose:         PurposeOutputKDV,
		DocumentContext: "SALES_INVOICE",
		RequestedAt:     now,
	})
	if err != nil {
		t.Fatalf("resolve account failed: %v", err)
	}

	if !result.Resolved {
		t.Fatal("expected account resolved")
	}
	if result.AccountCode != "391.01.20" {
		t.Fatalf("expected 391.01.20, got %s", result.AccountCode)
	}
}

func TestValidateRejectsInvalidAccountPrefix(t *testing.T) {
	runtime := newRuntime(t)

	req := validSwitchRequest()
	req.TargetVersion.Rules[2].AccountCode = "191.01.20"

	result, err := runtime.PrepareSwitch(req)
	if err == nil {
		t.Fatal("expected invalid account prefix error")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestValidateRejectsMissingEvidenceHash(t *testing.T) {
	runtime := newRuntime(t)

	req := validSwitchRequest()
	req.TargetVersion.EvidenceHash = ""

	result, err := runtime.PrepareSwitch(req)
	if err == nil {
		t.Fatal("expected missing evidence hash error")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewChartAccountLiveSwitchRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}
