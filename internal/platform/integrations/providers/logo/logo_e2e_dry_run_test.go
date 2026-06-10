package logo

import "testing"

func TestLogoE2EDryRunContractReadiness(t *testing.T) {
	contract := NewLogoE2EDryRunContract()

	if err := contract.Validate(); err != nil {
		t.Fatalf("Logo E2E dry-run contract must validate: %v", err)
	}

	if contract.Step != StepFAZ78L9 {
		t.Fatalf("step mismatch: got %s", contract.Step)
	}

	if contract.E2EMode != LogoE2EDryRunMode {
		t.Fatalf("E2E mode mismatch: got %s", contract.E2EMode)
	}

	t.Log("7-8L IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.9 IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.9.1 E2E dry-run contract readiness IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.9.2 admin ops dependency validation IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoE2EDryRunKeepsRealIntegrationsClosed(t *testing.T) {
	contract := NewLogoE2EDryRunContract()

	if !contract.RealIntegrationsClosed() {
		t.Fatal("real provider API, file delivery, and ERP write must remain closed")
	}

	for _, operation := range contract.Operations {
		if !operation.DryRunE2EAllowed {
			t.Fatalf("operation %s must allow E2E dry-run", operation.Name)
		}
		if operation.ExternalCallAllowed {
			t.Fatalf("operation %s must not allow external calls", operation.Name)
		}
		if operation.RealFileDeliveryAllowed {
			t.Fatalf("operation %s must not allow real file delivery", operation.Name)
		}
		if operation.ERPWriteAllowed {
			t.Fatalf("operation %s must not allow ERP writes", operation.Name)
		}
	}

	t.Log("7-8L.9.3 dry-run E2E allowed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.9.4 real Logo provider API closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.9.5 real Logo file delivery closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.9.6 real ERP write closed IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoE2ESuccessfulDryRunFlow(t *testing.T) {
	contract := NewLogoE2EDryRunContract()
	input := NewLogoSampleDryRunExportInput()

	result, err := contract.RunSuccessfulDryRunFlow(input, "tenant_7")
	if err != nil {
		t.Fatalf("successful E2E dry-run flow must run: %v", err)
	}

	if result.FinalAction != LogoDecisionPass {
		t.Fatalf("expected PASS action, got %s", result.FinalAction)
	}

	if err := result.ValidateNoRealSideEffects(); err != nil {
		t.Fatalf("result must not have real side effects: %v", err)
	}

	if err := result.ValidateRequiredSteps(); err != nil {
		t.Fatalf("result must contain required steps: %v", err)
	}

	t.Log("7-8L.9.7 successful dry-run E2E flow IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.9.8 file generation linked in E2E IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.9.9 import delivery linked in E2E IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.9.10 validation linked in E2E IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.9.11 no real side effects in E2E IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoE2EValidationFailureToDLQFlow(t *testing.T) {
	contract := NewLogoE2EDryRunContract()
	input := NewLogoSampleDryRunExportInput()
	input.Header.TenantID = ""

	result, err := contract.RunSuccessfulDryRunFlow(input, "tenant_7")
	if err != nil {
		t.Fatalf("validation failure E2E flow should return decision result without runtime error: %v", err)
	}

	if result.FinalAction != LogoDecisionDLQ {
		t.Fatalf("expected DLQ action, got %s", result.FinalAction)
	}

	if !result.DLQDecisionCreated {
		t.Fatal("DLQ decision must be created")
	}

	t.Log("7-8L.9.12 validation failure E2E flow IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.9.13 DLQ decision linked in E2E IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoE2ERetryDecisionFlow(t *testing.T) {
	contract := NewLogoE2EDryRunContract()

	decision, err := contract.RunRetryDecisionDryRunFlow(LogoErrorProviderTimeout, 0)
	if err != nil {
		t.Fatalf("retry decision flow must run: %v", err)
	}

	if decision.Action != LogoDecisionRetry {
		t.Fatalf("expected RETRY action, got %s", decision.Action)
	}

	if decision.NextAttempt != 1 {
		t.Fatalf("expected next attempt 1, got %d", decision.NextAttempt)
	}

	t.Log("7-8L.9.14 transient provider retry E2E flow IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.9.15 retry decision linked in E2E IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoE2ERetryLimitToDLQFlow(t *testing.T) {
	contract := NewLogoE2EDryRunContract()

	decision, err := contract.RunRetryDecisionDryRunFlow(LogoErrorProviderRateLimit, 3)
	if err != nil {
		t.Fatalf("retry limit E2E flow must run: %v", err)
	}

	if decision.Action != LogoDecisionDLQ {
		t.Fatalf("expected DLQ action, got %s", decision.Action)
	}

	if !decision.DLQ {
		t.Fatal("DLQ flag must be true")
	}

	t.Log("7-8L.9.16 retry limit E2E flow IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.9.17 retry limit DLQ linked in E2E IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoE2EManualReviewDryRunFlow(t *testing.T) {
	contract := NewLogoE2EDryRunContract()
	input := NewLogoSampleDryRunExportInput()

	result, err := contract.RunManualReviewDryRunFlow(input)
	if err != nil {
		t.Fatalf("manual review E2E dry-run flow must run: %v", err)
	}

	if result.FinalAction != LogoDecisionManualReview {
		t.Fatalf("expected MANUAL_REVIEW action, got %s", result.FinalAction)
	}

	if !result.ManualReviewCreated {
		t.Fatal("manual review must be created")
	}

	if result.ManualReviewID == "" {
		t.Fatal("manual review id must exist")
	}

	if err := result.ValidateNoRealSideEffects(); err != nil {
		t.Fatalf("manual review result must not have real side effects: %v", err)
	}

	t.Log("7-8L.9.18 unknown provider manual review E2E flow IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.9.19 admin ops manual review linked in E2E IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoE2ERejectsExternalOperation(t *testing.T) {
	contract := NewLogoE2EDryRunContract()
	contract.Operations[0].ExternalCallAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when external call is allowed")
	}

	t.Log("7-8L.9.20 external call guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoE2ERejectsRealFileDeliveryOperation(t *testing.T) {
	contract := NewLogoE2EDryRunContract()
	contract.Operations[0].RealFileDeliveryAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when real file delivery is allowed")
	}

	t.Log("7-8L.9.21 real file delivery guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoE2ERejectsERPWriteOperation(t *testing.T) {
	contract := NewLogoE2EDryRunContract()
	contract.Operations[0].ERPWriteAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when ERP write is allowed")
	}

	t.Log("7-8L.9.22 ERP write guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoE2ERejectsRealSideEffectResult(t *testing.T) {
	result := LogoE2EDryRunResult{
		FlowID:                "invalid",
		FlowType:              LogoE2EFlowSuccessfulDryRun,
		TenantID:              "tenant_7",
		CorrelationID:         "corr",
		IdempotencyKey:        "idem",
		FinalAction:           LogoDecisionPass,
		DryRunOnly:            true,
		RealProviderAPICalled: true,
	}

	if err := result.ValidateNoRealSideEffects(); err == nil {
		t.Fatal("expected validation error when real provider API is called")
	}

	t.Log("7-8L.9.23 real side effect result rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}
