package paymentadapter

import "testing"

func TestPaymentModuleClosurePassesWhenRequiredEngineeringGatesPassAndRealPaymentClosed(t *testing.T) {
	runtime := NewPaymentModuleClosureRuntime()

	decision, err := runtime.Evaluate(paymentModuleClosurePassingRequest())
	if err != nil {
		t.Fatalf("expected closure decision, got %v", err)
	}

	if decision.FinalStatus != PaymentModuleClosurePass {
		t.Fatalf("expected PASS final status, got %s blockers=%v", decision.FinalStatus, decision.Blockers)
	}
	if decision.RealPaymentLiveStatus != PaymentRealPaymentClosed {
		t.Fatalf("real payment must stay CLOSED, got %s", decision.RealPaymentLiveStatus)
	}
	if !decision.PaymentProviderAdapterModuleSeal {
		t.Fatal("payment provider adapter module must be sealed")
	}
	if !decision.ReturnToFAZ7Main {
		t.Fatal("expected return to FAZ 7 main after payment module seal")
	}
	if decision.NextMainModuleCode != "7-8" {
		t.Fatalf("expected next main module 7-8, got %s", decision.NextMainModuleCode)
	}
	if decision.RequiredGateCount != decision.PassedRequiredGateCount {
		t.Fatalf("expected all required gates pass, required=%d passed=%d", decision.RequiredGateCount, decision.PassedRequiredGateCount)
	}
	if decision.BlockerCount != 0 {
		t.Fatalf("expected zero blockers, got %d", decision.BlockerCount)
	}
}

func TestPaymentModuleClosureBlocksWhenRealPaymentEnabled(t *testing.T) {
	runtime := NewPaymentModuleClosureRuntime()
	req := paymentModuleClosurePassingRequest()
	req.RealPaymentEnabled = true

	decision, err := runtime.Evaluate(req)
	if err != nil {
		t.Fatalf("expected closure decision, got %v", err)
	}

	if decision.FinalStatus != PaymentModuleClosureBlocked {
		t.Fatalf("expected BLOCKED final status when real payment enabled, got %s", decision.FinalStatus)
	}
	if decision.BlockerCount != 1 {
		t.Fatalf("expected one blocker, got %d blockers=%v", decision.BlockerCount, decision.Blockers)
	}
	if decision.PaymentProviderAdapterModuleSeal {
		t.Fatal("module must not seal when real payment gate is open")
	}
}

func TestPaymentModuleClosureBlocksWhenCriticalEngineeringGateMissing(t *testing.T) {
	runtime := NewPaymentModuleClosureRuntime()
	req := paymentModuleClosurePassingRequest()
	req.SandboxE2EPassed = false

	decision, err := runtime.Evaluate(req)
	if err != nil {
		t.Fatalf("expected closure decision, got %v", err)
	}

	if decision.FinalStatus != PaymentModuleClosureBlocked {
		t.Fatalf("expected BLOCKED final status, got %s", decision.FinalStatus)
	}
	if decision.BlockerCount == 0 {
		t.Fatal("expected blocker for missing sandbox e2e")
	}
	if decision.ReturnToFAZ7Main {
		t.Fatal("must not return to FAZ 7 main while blocker exists")
	}
}

func TestPaymentModuleClosureProviderHandoffCanBeNotReadyWithoutBlockingModuleSeal(t *testing.T) {
	runtime := NewPaymentModuleClosureRuntime()
	req := paymentModuleClosurePassingRequest()
	req.ProductionProviderSelected = false
	req.LegalApprovalReady = false
	req.FinanceTaxApprovalReady = false
	req.SecurityApprovalReady = false
	req.ProviderSecretPrepared = false
	req.RollbackPlanReady = false

	decision, err := runtime.Evaluate(req)
	if err != nil {
		t.Fatalf("expected closure decision, got %v", err)
	}

	if decision.FinalStatus != PaymentModuleClosurePass {
		t.Fatalf("expected module closure PASS, got %s", decision.FinalStatus)
	}
	if decision.ProductionProviderHandoffStatus != PaymentProviderHandoffNotReady {
		t.Fatalf("expected provider handoff NOT_READY, got %s", decision.ProductionProviderHandoffStatus)
	}
	if decision.RealPaymentLiveStatus != PaymentRealPaymentClosed {
		t.Fatalf("real payment must remain CLOSED, got %s", decision.RealPaymentLiveStatus)
	}
}

func TestPaymentModuleClosureProviderHandoffReadyWhenApprovalGatesPass(t *testing.T) {
	runtime := NewPaymentModuleClosureRuntime()

	decision, err := runtime.Evaluate(paymentModuleClosurePassingRequest())
	if err != nil {
		t.Fatalf("expected closure decision, got %v", err)
	}

	if decision.ProductionProviderHandoffStatus != PaymentProviderHandoffReady {
		t.Fatalf("expected provider handoff READY, got %s", decision.ProductionProviderHandoffStatus)
	}
}

func TestPaymentModuleClosureRejectsMissingModuleCode(t *testing.T) {
	runtime := NewPaymentModuleClosureRuntime()
	req := paymentModuleClosurePassingRequest()
	req.ModuleCode = ""

	_, err := runtime.Evaluate(req)
	if err == nil {
		t.Fatal("missing module code must fail")
	}
}

func TestPaymentModuleClosureStaticGateCatalogs(t *testing.T) {
	required := PaymentModuleClosureRequiredGateCodes()
	handoff := PaymentModuleClosureProviderHandoffGateCodes()

	if len(required) != 14 {
		t.Fatalf("expected 14 required gates, got %d", len(required))
	}
	if len(handoff) != 6 {
		t.Fatalf("expected 6 provider handoff gates, got %d", len(handoff))
	}

	assertPaymentClosureGateExists(t, required, "real_payment_disabled")
	assertPaymentClosureGateExists(t, required, "postgres_migration_audit_passed")
	assertPaymentClosureGateExists(t, required, "admin_ops_ready")
	assertPaymentClosureGateExists(t, handoff, "legal_approval_ready")
	assertPaymentClosureGateExists(t, handoff, "provider_secret_prepared")
}

func paymentModuleClosurePassingRequest() PaymentModuleClosureRequest {
	return PaymentModuleClosureRequest{
		ModuleCode:                   "7-5P",
		BillingCoreSeparated:         true,
		ProviderContractReady:        true,
		AttemptLifecycleReady:        true,
		RepositoryContractReady:      true,
		PostgresMigrationAuditPassed: true,
		ServiceOrchestrationReady:    true,
		WebhookIntakeReady:           true,
		SimulationAdapterReady:       true,
		SandboxE2EPassed:             true,
		FailureRetryIdempotencyReady: true,
		ObservabilityReady:           true,
		AdminOpsReady:                true,
		RealPaymentEnabled:           false,
		ProductionProviderSelected:   true,
		LegalApprovalReady:           true,
		FinanceTaxApprovalReady:      true,
		SecurityApprovalReady:        true,
		ProviderSecretPrepared:       true,
		RollbackPlanReady:            true,
	}
}

func assertPaymentClosureGateExists(t *testing.T, values []string, expected string) {
	t.Helper()

	for _, value := range values {
		if value == expected {
			return
		}
	}

	t.Fatalf("expected gate %s in catalog", expected)
}
