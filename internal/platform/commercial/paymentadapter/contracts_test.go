package paymentadapter

import "testing"

func TestProviderCapabilityMatrixAllowsAuthorize(t *testing.T) {
	matrix := mustCapabilityMatrix(t, []string{"AUTHORIZE"}, ModeSandbox, false)

	decision := matrix.ValidateRequest(OperationContractRequest{
		ProviderCode:   "pix2pi_simulation",
		TenantID:       "tenant_7",
		CorrelationID:  "corr_7_5p_1_001",
		RequestID:      "req_7_5p_1_001",
		IdempotencyKey: "idem_7_5p_1_001",
		Operation:      OperationAuthorize,
		Money:          Money{AmountMinor: 25000, Currency: "TRY"},
	})

	if !decision.Allowed {
		t.Fatalf("expected authorize to be allowed, got %s %s", decision.ErrorCode, decision.Message)
	}
	if decision.Status != ContractStatusAccepted {
		t.Fatalf("expected accepted status, got %s", decision.Status)
	}
	if decision.RealPayment {
		t.Fatal("sandbox authorize must not be real payment")
	}
	if err := EnsureContractDecisionIsAuditable(decision); err != nil {
		t.Fatalf("decision must be auditable: %v", err)
	}
}

func TestProviderCapabilityMatrixDeniesUnsupportedOperation(t *testing.T) {
	matrix := mustCapabilityMatrix(t, []string{"AUTHORIZE"}, ModeSandbox, false)

	decision := matrix.ValidateRequest(OperationContractRequest{
		ProviderCode:   "pix2pi_simulation",
		TenantID:       "tenant_7",
		CorrelationID:  "corr_7_5p_1_002",
		IdempotencyKey: "idem_7_5p_1_002",
		Operation:      OperationRefund,
		Money:          Money{AmountMinor: 10000, Currency: "TRY"},
	})

	if decision.Allowed {
		t.Fatal("refund must be denied when provider does not support refund")
	}
	if decision.ErrorCode != ErrorOperationUnsupported {
		t.Fatalf("expected unsupported error, got %s", decision.ErrorCode)
	}
}

func TestCaptureRequiresProviderTransactionID(t *testing.T) {
	matrix := mustCapabilityMatrix(t, []string{"CAPTURE"}, ModeSandbox, false)

	decision := matrix.ValidateRequest(OperationContractRequest{
		ProviderCode:   "pix2pi_simulation",
		TenantID:       "tenant_7",
		CorrelationID:  "corr_7_5p_1_003",
		IdempotencyKey: "idem_7_5p_1_003",
		Operation:      OperationCapture,
		Money:          Money{AmountMinor: 25000, Currency: "TRY"},
	})

	if decision.Allowed {
		t.Fatal("capture without provider transaction id must be denied")
	}
	if decision.ErrorCode != ErrorProviderTransactionRequired {
		t.Fatalf("expected provider transaction required, got %s", decision.ErrorCode)
	}
}

func TestRefundRequiresProviderTransactionID(t *testing.T) {
	matrix := mustCapabilityMatrix(t, []string{"REFUND"}, ModeSandbox, false)

	decision := matrix.ValidateRequest(OperationContractRequest{
		ProviderCode:   "pix2pi_simulation",
		TenantID:       "tenant_7",
		CorrelationID:  "corr_7_5p_1_004",
		IdempotencyKey: "idem_7_5p_1_004",
		Operation:      OperationRefund,
		Money:          Money{AmountMinor: 25000, Currency: "TRY"},
	})

	if decision.Allowed {
		t.Fatal("refund without provider transaction id must be denied")
	}
	if decision.ErrorCode != ErrorProviderTransactionRequired {
		t.Fatalf("expected provider transaction required, got %s", decision.ErrorCode)
	}
}

func TestVoidRequiresProviderTransactionIDButNotAmount(t *testing.T) {
	matrix := mustCapabilityMatrix(t, []string{"VOID"}, ModeSandbox, false)

	decision := matrix.ValidateRequest(OperationContractRequest{
		ProviderCode:          "pix2pi_simulation",
		TenantID:              "tenant_7",
		CorrelationID:         "corr_7_5p_1_005",
		IdempotencyKey:        "idem_7_5p_1_005",
		Operation:             OperationVoid,
		ProviderTransactionID: "prov_txn_001",
	})

	if !decision.Allowed {
		t.Fatalf("void should be allowed without amount when provider transaction exists: %s", decision.Message)
	}
}

func TestWebhookVerifyRequiresSignatureAndPayload(t *testing.T) {
	matrix := mustCapabilityMatrix(t, []string{"WEBHOOK_VERIFY"}, ModeSandbox, false)

	missingSignature := matrix.ValidateRequest(OperationContractRequest{
		ProviderCode:      "pix2pi_simulation",
		TenantID:          "tenant_7",
		CorrelationID:     "corr_7_5p_1_006",
		Operation:         OperationWebhookVerify,
		RawWebhookPayload: []byte(`{"event":"payment.succeeded"}`),
	})
	if missingSignature.Allowed {
		t.Fatal("webhook without signature must be denied")
	}
	if missingSignature.ErrorCode != ErrorWebhookSignatureRequired {
		t.Fatalf("expected webhook signature required, got %s", missingSignature.ErrorCode)
	}

	missingPayload := matrix.ValidateRequest(OperationContractRequest{
		ProviderCode:     "pix2pi_simulation",
		TenantID:         "tenant_7",
		CorrelationID:    "corr_7_5p_1_007",
		Operation:        OperationWebhookVerify,
		WebhookSignature: "sig_test",
	})
	if missingPayload.Allowed {
		t.Fatal("webhook without raw payload must be denied")
	}
	if missingPayload.ErrorCode != ErrorWebhookPayloadRequired {
		t.Fatalf("expected webhook payload required, got %s", missingPayload.ErrorCode)
	}
}

func TestProductionRealPaymentGateClosedAtContractLayer(t *testing.T) {
	matrix := mustCapabilityMatrix(t, []string{"AUTHORIZE"}, ModeProduction, false)

	decision := matrix.ValidateRequest(OperationContractRequest{
		ProviderCode:   "pix2pi_simulation",
		TenantID:       "tenant_7",
		CorrelationID:  "corr_7_5p_1_008",
		IdempotencyKey: "idem_7_5p_1_008",
		Operation:      OperationAuthorize,
		Money:          Money{AmountMinor: 25000, Currency: "TRY"},
	})

	if decision.Allowed {
		t.Fatal("production request must be denied while real payment gate is closed")
	}
	if decision.ErrorCode != ErrorProductionGateClosed {
		t.Fatalf("expected production gate closed, got %s", decision.ErrorCode)
	}
}

func TestProviderMismatchDenied(t *testing.T) {
	matrix := mustCapabilityMatrix(t, []string{"AUTHORIZE"}, ModeSandbox, false)

	decision := matrix.ValidateRequest(OperationContractRequest{
		ProviderCode:   "another_provider",
		TenantID:       "tenant_7",
		CorrelationID:  "corr_7_5p_1_009",
		IdempotencyKey: "idem_7_5p_1_009",
		Operation:      OperationAuthorize,
		Money:          Money{AmountMinor: 25000, Currency: "TRY"},
	})

	if decision.Allowed {
		t.Fatal("provider mismatch must be denied")
	}
	if decision.ErrorCode != ErrorProviderMismatch {
		t.Fatalf("expected provider mismatch, got %s", decision.ErrorCode)
	}
}

func TestStandardContractErrorCodes(t *testing.T) {
	codes := StandardContractErrorCodes()
	if len(codes) != 11 {
		t.Fatalf("expected 11 standard error codes, got %d", len(codes))
	}
	assertContainsCode(t, codes, ErrorTenantRequired)
	assertContainsCode(t, codes, ErrorCorrelationRequired)
	assertContainsCode(t, codes, ErrorIdempotencyRequired)
	assertContainsCode(t, codes, ErrorProductionGateClosed)
}

func mustCapabilityMatrix(t *testing.T, operations []string, mode ProviderMode, realPaymentEnabled bool) ProviderCapabilityMatrix {
	t.Helper()

	matrix, err := NewProviderCapabilityMatrix(ProviderConfig{
		ProviderName:       "Pix2pi Simulation Provider",
		ProviderCode:       "pix2pi_simulation",
		Mode:               string(mode),
		RealPaymentEnabled: realPaymentEnabled,
		AllowedOperations:  operations,
		SettlementCurrency: "TRY",
		WebhookRequired:    true,
		AuditEnabled:       true,
	})
	if err != nil {
		t.Fatalf("expected capability matrix, got error: %v", err)
	}

	return matrix
}

func assertContainsCode(t *testing.T, codes []ContractErrorCode, expected ContractErrorCode) {
	t.Helper()

	for _, code := range codes {
		if code == expected {
			return
		}
	}

	t.Fatalf("expected code %s in standard error codes", expected)
}
