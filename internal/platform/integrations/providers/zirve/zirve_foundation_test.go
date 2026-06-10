package zirve

import (
	"testing"
	"time"
)

func TestZirveProviderIdentityValidates(t *testing.T) {
	identity := NewZirveProviderIdentity(time.Date(2026, 5, 3, 12, 0, 0, 0, time.UTC))

	if err := identity.Validate(); err != nil {
		t.Fatalf("expected Zirve foundation identity to validate, got error: %v", err)
	}

	if identity.ModuleCode != "FAZ_7_8Z" {
		t.Fatalf("unexpected module code: %s", identity.ModuleCode)
	}

	if identity.ProviderID != "zirve" {
		t.Fatalf("unexpected provider id: %s", identity.ProviderID)
	}

	if identity.DisplayName != "Zirve" {
		t.Fatalf("unexpected display name: %s", identity.DisplayName)
	}
}

func TestZirveRealProviderBoundariesRemainClosed(t *testing.T) {
	identity := NewZirveProviderIdentity(time.Time{})

	if identity.CanUseRealProviderAPI() {
		t.Fatal("real Zirve provider API must remain closed")
	}
	if identity.CanDeliverRealFile() {
		t.Fatal("real Zirve file delivery must remain closed")
	}
	if identity.CanWriteERP() {
		t.Fatal("real ERP write must remain closed")
	}
	if identity.CanUseRealDeliveryChannel() {
		t.Fatal("real delivery channel must remain closed")
	}
	if identity.CanRunRealOperatorProviderAction() {
		t.Fatal("real operator provider action must remain closed")
	}

	readiness := identity.Readiness()
	if readiness.RealProviderAPIAllowed ||
		readiness.RealFileDeliveryAllowed ||
		readiness.RealERPWriteAllowed ||
		readiness.RealDeliveryChannelAllowed ||
		readiness.RealOperatorProviderActionAllowed {
		t.Fatalf("readiness must report all real operations closed: %+v", readiness)
	}
}

func TestZirveCapabilitiesAndContracts(t *testing.T) {
	identity := NewZirveProviderIdentity(time.Time{})

	requiredCapabilities := []CapabilityCode{
		CapabilityProviderIdentity,
		CapabilityExportPackage,
		CapabilityImportDelivery,
		CapabilityValidation,
		CapabilityRetryDLQ,
		CapabilityManualReview,
		CapabilityE2EDryRun,
	}

	for _, capability := range requiredCapabilities {
		if !identity.HasCapability(capability) {
			t.Fatalf("missing capability: %s", capability)
		}
	}

	if !identity.SupportsAuthMode(AuthModeNoneDryRun) {
		t.Fatal("dry-run auth mode must be supported")
	}
	if !identity.SupportsAuthMode(AuthModeCredentialRefOnly) {
		t.Fatal("credential reference auth mode must be supported")
	}
	if !identity.SupportsAuthMode(AuthModeProviderLiveOnly) {
		t.Fatal("provider live auth mode marker must be supported")
	}

	if !identity.SupportsDeliveryMode(DeliveryModeNoneDryRun) {
		t.Fatal("none dry-run delivery mode must be supported")
	}
	if !identity.SupportsDeliveryMode(DeliveryModeFilePackageDryRun) {
		t.Fatal("file package dry-run delivery mode must be supported")
	}
	if !identity.SupportsDeliveryMode(DeliveryModeProviderLiveOnly) {
		t.Fatal("provider live delivery marker must be supported")
	}

	if !identity.SupportsDirection(DirectionPix2piToZirve) {
		t.Fatal("PIX2PI_TO_ZIRVE direction must be supported")
	}
	if !identity.SupportsDirection(DirectionZirveToPix2pi) {
		t.Fatal("ZIRVE_TO_PIX2PI direction must be supported")
	}
}

func TestZirveDryRunOperationDecisions(t *testing.T) {
	identity := NewZirveProviderIdentity(time.Time{})

	allowed := []string{
		"DRY_RUN_PROVIDER_IDENTITY",
		"DRY_RUN_EXPORT_PACKAGE_BUILD",
		"DRY_RUN_VALIDATION",
		"DRY_RUN_RETRY_DLQ_DECISION",
		"DRY_RUN_MANUAL_REVIEW_PREVIEW",
		"DRY_RUN_E2E_CHAIN",
	}

	for _, operation := range allowed {
		decision := identity.DecideOperation(operation)
		if !decision.Allowed {
			t.Fatalf("expected dry-run operation to be allowed: %+v", decision)
		}
	}

	realDecision := identity.DecideOperation("REAL_ZIRVE_PROVIDER_API_CALL")
	if realDecision.Allowed {
		t.Fatalf("real operation must not be allowed: %+v", realDecision)
	}
	if realDecision.RequiredGate != HandoffGateStatus {
		t.Fatalf("real operation must require handoff gate, got: %s", realDecision.RequiredGate)
	}
}

func TestZirveNoSecretTenantAndAuditPolicies(t *testing.T) {
	identity := NewZirveProviderIdentity(time.Time{})

	if identity.NoSecretPolicy != "FORBIDDEN_IN_CODE_CONFIG_DOCS" {
		t.Fatalf("unexpected secret policy: %s", identity.NoSecretPolicy)
	}

	if identity.TenantSafetyMode != "TENANT_CONTEXT_REQUIRED" {
		t.Fatalf("unexpected tenant safety mode: %s", identity.TenantSafetyMode)
	}

	if identity.AuditPolicy != "AUDIT_DECISION_REQUIRED_FOR_EVERY_OPERATION" {
		t.Fatalf("unexpected audit policy: %s", identity.AuditPolicy)
	}
}
