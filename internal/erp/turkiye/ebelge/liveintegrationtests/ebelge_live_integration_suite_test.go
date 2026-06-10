package liveintegrationtests

import (
	"testing"
	"time"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:            true,
		Mode:                      TestModeSimulation,
		RealProviderGateOpen:      false,
		ProductionApproved:        false,
		ProviderCode:              "SIM_EBELGE_PROVIDER",
		EndpointBaseURL:           "https://simulation.local/ebelge",
		CredentialRef:             "secret://simulation/ebelge-provider",
		RawSecretPolicy:           "CREDENTIAL_REF_ONLY_NO_RAW_SECRET",
		TenantRequired:            true,
		IdempotencyRequired:       true,
		SignatureRequired:         true,
		CallbackRequired:          true,
		PollRequired:              true,
		RetryRequired:             true,
		DLQRequired:               true,
		ManualReviewRequired:      true,
		LiveSmokeAllowedInSandbox: false,
		SupportedDocuments: []DocumentKind{
			DocumentKindEFatura,
			DocumentKindEArsiv,
			DocumentKindEAdisyon,
		},
		RequiredOperations: []LiveOperation{
			OperationSendDocument,
			OperationCheckStatus,
			OperationCancelDocument,
			OperationDownloadUBL,
			OperationDownloadPDF,
			OperationHandleCallback,
			OperationPollStatus,
			OperationRetryFailed,
			OperationDLQRoute,
			OperationManualReview,
			OperationLiveSmokeReadiness,
		},
	}
}

func validRequest(kind DocumentKind, operation LiveOperation) LiveIntegrationRequest {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return LiveIntegrationRequest{
		TenantID:            "tenant-001",
		CorrelationID:       "corr-live-001",
		RequestID:           "req-live-001",
		IdempotencyKey:      "idem-live-" + string(kind) + "-" + string(operation),
		DocumentKind:        kind,
		DocumentID:          "doc-" + string(kind),
		DocumentNo:          "DOC-" + string(kind),
		ProviderCode:        "SIM_EBELGE_PROVIDER",
		ProviderDocumentID:  "provider-doc-" + string(kind),
		ProviderPayloadHash: "sha256:provider-payload-" + string(kind),
		UBLHash:             "sha256:ubl-" + string(kind),
		PDFHash:             "sha256:pdf-" + string(kind),
		CallbackSignature:   "sha256:callback-signature",
		CallbackPayloadHash: "sha256:callback-payload",
		CancelReason:        "operator cancel test",
		ErrorCode:           "PROVIDER_TIMEOUT",
		RetryCount:          0,
		Operation:           operation,
		RequestedBy:         "ebelge-test-suite",
		RequestedAt:         now,
	}
}

func TestLiveGateDeniesProductionWithoutApprovals(t *testing.T) {
	cfg := validConfig()
	cfg.Mode = TestModeProduction
	cfg.RealProviderGateOpen = false
	cfg.ProductionApproved = false

	if _, err := NewLiveIntegrationSuite(cfg); err == nil {
		t.Fatal("expected production live provider gate error")
	}
}

func TestSimulationLiveGateSkipsProviderCall(t *testing.T) {
	suite, err := NewLiveIntegrationSuite(validConfig())
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	result := suite.ValidateLiveGate()

	if result.DecisionStatus != DecisionSkipped {
		t.Fatalf("expected skipped, got %s", result.DecisionStatus)
	}
	if result.ProviderCallAllowed {
		t.Fatal("expected provider call denied in simulation")
	}
	if !result.SimulationOnly {
		t.Fatal("expected simulation only")
	}
}

func TestEFaturaLiveReadinessMatrix(t *testing.T) {
	suite, err := NewLiveIntegrationSuite(validConfig())
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	send, err := suite.ValidateSendDocument(validRequest(DocumentKindEFatura, OperationSendDocument))
	if err != nil {
		t.Fatalf("send validation failed: %v", err)
	}
	if send.DecisionStatus != DecisionPassed {
		t.Fatalf("expected passed, got %s", send.DecisionStatus)
	}

	status, err := suite.ValidateStatusCheck(validRequest(DocumentKindEFatura, OperationCheckStatus))
	if err != nil {
		t.Fatalf("status validation failed: %v", err)
	}
	if status.ProviderStatus != ProviderStatusAccepted {
		t.Fatalf("expected accepted status, got %s", status.ProviderStatus)
	}

	artifact, err := suite.ValidateDownloadArtifact(validRequest(DocumentKindEFatura, OperationDownloadUBL))
	if err != nil {
		t.Fatalf("download UBL validation failed: %v", err)
	}
	if !artifact.ArtifactReady {
		t.Fatal("expected artifact ready")
	}
}

func TestEArsivLiveReadinessMatrix(t *testing.T) {
	suite, err := NewLiveIntegrationSuite(validConfig())
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	send, err := suite.ValidateSendDocument(validRequest(DocumentKindEArsiv, OperationSendDocument))
	if err != nil {
		t.Fatalf("send validation failed: %v", err)
	}
	if send.ProviderStatus != ProviderStatusQueued {
		t.Fatalf("expected queued, got %s", send.ProviderStatus)
	}

	artifact, err := suite.ValidateDownloadArtifact(validRequest(DocumentKindEArsiv, OperationDownloadPDF))
	if err != nil {
		t.Fatalf("download PDF validation failed: %v", err)
	}
	if !artifact.ArtifactReady {
		t.Fatal("expected PDF artifact ready")
	}
}

func TestEAdisyonLiveReadinessMatrix(t *testing.T) {
	suite, err := NewLiveIntegrationSuite(validConfig())
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	send, err := suite.ValidateSendDocument(validRequest(DocumentKindEAdisyon, OperationSendDocument))
	if err != nil {
		t.Fatalf("send validation failed: %v", err)
	}
	if send.DecisionStatus != DecisionPassed {
		t.Fatalf("expected passed, got %s", send.DecisionStatus)
	}

	cancel, err := suite.ValidateCancelDocument(validRequest(DocumentKindEAdisyon, OperationCancelDocument))
	if err != nil {
		t.Fatalf("cancel validation failed: %v", err)
	}
	if cancel.ProviderStatus != ProviderStatusCancelled {
		t.Fatalf("expected cancelled, got %s", cancel.ProviderStatus)
	}
}

func TestCallbackPollRetryAndDLQReadiness(t *testing.T) {
	suite, err := NewLiveIntegrationSuite(validConfig())
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	callback, err := suite.ValidateCallback(validRequest(DocumentKindEFatura, OperationHandleCallback))
	if err != nil {
		t.Fatalf("callback validation failed: %v", err)
	}
	if !callback.CallbackVerified {
		t.Fatal("expected callback verified")
	}

	poll, err := suite.ValidatePollPlan(validRequest(DocumentKindEFatura, OperationPollStatus))
	if err != nil {
		t.Fatalf("poll validation failed: %v", err)
	}
	if !poll.PollReady {
		t.Fatal("expected poll ready")
	}

	retryReq := validRequest(DocumentKindEFatura, OperationRetryFailed)
	retryReq.RetryCount = 3

	retry, err := suite.ValidateRetryAndDLQ(retryReq)
	if err != nil {
		t.Fatalf("retry validation failed: %v", err)
	}
	if retry.ProviderStatus != ProviderStatusDLQ {
		t.Fatalf("expected DLQ, got %s", retry.ProviderStatus)
	}
	if !retry.RetryReady || !retry.DLQReady || !retry.ManualReviewReady {
		t.Fatal("expected retry/DLQ/manual review ready")
	}
}

func TestReadinessMatrixCoversAllDocuments(t *testing.T) {
	suite, err := NewLiveIntegrationSuite(validConfig())
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	results, err := suite.RunReadinessMatrix([]LiveIntegrationRequest{
		validRequest(DocumentKindEFatura, OperationSendDocument),
		validRequest(DocumentKindEArsiv, OperationSendDocument),
		validRequest(DocumentKindEAdisyon, OperationSendDocument),
		validRequest(DocumentKindEFatura, OperationHandleCallback),
		validRequest(DocumentKindEFatura, OperationPollStatus),
		validRequest(DocumentKindEFatura, OperationRetryFailed),
	})
	if err != nil {
		t.Fatalf("readiness matrix failed: %v", err)
	}

	if len(results) != 7 {
		t.Fatalf("expected 7 results including live gate, got %d", len(results))
	}
}

func TestRejectsMissingCallbackSignature(t *testing.T) {
	suite, err := NewLiveIntegrationSuite(validConfig())
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	req := validRequest(DocumentKindEFatura, OperationHandleCallback)
	req.CallbackSignature = ""

	result, err := suite.ValidateCallback(req)
	if err == nil {
		t.Fatal("expected callback signature error")
	}
	if result.ErrorCode != "CALLBACK_SIGNATURE_REQUIRED" {
		t.Fatalf("expected CALLBACK_SIGNATURE_REQUIRED, got %s", result.ErrorCode)
	}
}

func TestRejectsMissingCancelReason(t *testing.T) {
	suite, err := NewLiveIntegrationSuite(validConfig())
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	req := validRequest(DocumentKindEFatura, OperationCancelDocument)
	req.CancelReason = ""

	result, err := suite.ValidateCancelDocument(req)
	if err == nil {
		t.Fatal("expected cancel reason error")
	}
	if result.ErrorCode != "CANCEL_REASON_REQUIRED" {
		t.Fatalf("expected CANCEL_REASON_REQUIRED, got %s", result.ErrorCode)
	}
}

func TestRejectsRawSecretPolicyViolation(t *testing.T) {
	cfg := validConfig()
	cfg.CredentialRef = "password=raw-secret"

	if _, err := NewLiveIntegrationSuite(cfg); err == nil {
		t.Fatal("expected raw secret credential ref error")
	}
}
