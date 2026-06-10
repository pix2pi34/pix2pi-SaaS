package mikro

import (
	"errors"
	"testing"
)

func logMikroValidationOK(t *testing.T, code string, message string) {
	t.Helper()
	t.Logf("%s %s / OK ✅", code, message)
}

func validMikroValidationPackage(t *testing.T) MikroDryRunPackage {
	t.Helper()

	builder := NewMikroFileGenerationBuilder()
	pkg, decision, err := builder.BuildDryRunPackage(validMikroFileGenerationRequest(ERPObjectSalesInvoice))
	if err != nil {
		t.Fatalf("failed to build prerequisite dry-run package: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("prerequisite dry-run package decision was not allowed")
	}
	return pkg
}

func validMikroValidationRequest(t *testing.T) MikroValidationRequest {
	t.Helper()

	return MikroValidationRequest{
		TenantID:      "tenant_7",
		ActorUserID:   "user_ops_1",
		CorrelationID: "corr-7-8m-4-validation",
		ValidationID:  "validation-7-8m-4-001",
		RequestedMode: MikroValidationRetryDLQMode,
		Attempt:       1,
		Package:       validMikroValidationPackage(t),
	}
}

func TestMikroValidationRetryDLQContractMetadata(t *testing.T) {
	runtime := NewMikroValidationRetryDLQRuntime()
	contract := runtime.Contract

	if err := contract.Validate(); err != nil {
		t.Fatalf("validation retry dlq contract validation failed: %v", err)
	}

	logMikroValidationOK(t, "7-8M.4", "Mikro Validation / Error Mapping / Retry-DLQ root validation")
	logMikroValidationOK(t, "7-8M.4.1", "metadata validation")
	logMikroValidationOK(t, "7-8M.4.1.1", "phase is FAZ_7_8M_4")
	logMikroValidationOK(t, "7-8M.4.1.2", "provider identity is mikro")
	logMikroValidationOK(t, "7-8M.4.1.3", "validation mode is VALIDATION_RETRY_DLQ_DRY_RUN_ONLY")
	logMikroValidationOK(t, "7-8M.4.1.4", "retry strategy is EXPONENTIAL_BACKOFF_DRY_RUN")
	logMikroValidationOK(t, "7-8M.4.1.5", "max attempts is 3")
	logMikroValidationOK(t, "7-8M.4.1.6", "real queue write policy is closed")

	if contract.Phase != MikroValidationRetryDLQPhase {
		t.Fatalf("phase mismatch")
	}
	if contract.ProviderID != ProviderID {
		t.Fatalf("provider id mismatch")
	}
	if contract.ValidationMode != MikroValidationRetryDLQMode {
		t.Fatalf("validation mode mismatch")
	}
	if contract.RetryPolicy.Strategy != MikroRetryStrategyDryRun {
		t.Fatalf("retry strategy mismatch")
	}
	if contract.RetryPolicy.MaxAttempts != 3 {
		t.Fatalf("max attempts mismatch")
	}
	if contract.RealQueueWritePolicy != MikroValidationRealQueueWritePolicy {
		t.Fatalf("real queue write policy mismatch")
	}
}

func TestMikroValidationAcceptsValidDryRunPackage(t *testing.T) {
	runtime := NewMikroValidationRetryDLQRuntime()

	decision, err := runtime.Evaluate(validMikroValidationRequest(t))
	if err != nil {
		t.Fatalf("valid dry-run package validation failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("valid dry-run package must be accepted")
	}
	if decision.Reason != MikroValidationDecisionReady {
		t.Fatalf("unexpected decision reason")
	}
	if decision.Action != MikroValidationActionAccept {
		t.Fatalf("valid package action must be ACCEPT")
	}
	if decision.SendToDLQ || decision.ManualReview || decision.RetryAllowed {
		t.Fatalf("valid package must not require DLQ/manual/retry")
	}

	logMikroValidationOK(t, "7-8M.4.2", "dry-run package validation decision")
	logMikroValidationOK(t, "7-8M.4.2.1", "valid dry-run package is accepted")
	logMikroValidationOK(t, "7-8M.4.2.2", "decision action is ACCEPT")
	logMikroValidationOK(t, "7-8M.4.2.3", "DLQ is not required")
	logMikroValidationOK(t, "7-8M.4.2.4", "manual review is not required")
	logMikroValidationOK(t, "7-8M.4.2.5", "retry is not required")
}

func TestMikroValidationProviderErrorMappingRetryDLQManualReview(t *testing.T) {
	runtime := NewMikroValidationRetryDLQRuntime()

	timeoutReq := validMikroValidationRequest(t)
	timeoutReq.ProviderErrorCode = MikroProviderErrorTimeout
	timeoutReq.Attempt = 1
	timeoutDecision, err := runtime.Evaluate(timeoutReq)
	if err != nil {
		t.Fatalf("timeout mapping should not error: %v", err)
	}
	if !timeoutDecision.Allowed || timeoutDecision.Action != MikroValidationActionRetry || !timeoutDecision.RetryAllowed {
		t.Fatalf("timeout at attempt 1 must be retry")
	}
	logMikroValidationOK(t, "7-8M.4.3", "provider error mapping validation")
	logMikroValidationOK(t, "7-8M.4.3.1", "MIKRO_TIMEOUT maps to retry decision")

	limitReq := validMikroValidationRequest(t)
	limitReq.ProviderErrorCode = MikroProviderErrorRateLimit
	limitReq.Attempt = 2
	limitDecision, err := runtime.Evaluate(limitReq)
	if err != nil {
		t.Fatalf("rate limit mapping should not error: %v", err)
	}
	if !limitDecision.Allowed || limitDecision.Action != MikroValidationActionRetry || limitDecision.BackoffSeconds == 0 {
		t.Fatalf("rate limit at attempt 2 must be retry with backoff")
	}
	logMikroValidationOK(t, "7-8M.4.3.2", "MIKRO_RATE_LIMIT maps to retry decision with backoff")

	exhaustedReq := validMikroValidationRequest(t)
	exhaustedReq.ProviderErrorCode = MikroProviderErrorTimeout
	exhaustedReq.Attempt = 3
	exhaustedDecision, err := runtime.Evaluate(exhaustedReq)
	if err != nil {
		t.Fatalf("retry exhausted mapping should not error: %v", err)
	}
	if !exhaustedDecision.Allowed || exhaustedDecision.Action != MikroValidationActionDLQ || !exhaustedDecision.SendToDLQ {
		t.Fatalf("timeout at max attempt must be DLQ")
	}
	logMikroValidationOK(t, "7-8M.4.3.3", "retry exhausted timeout maps to DLQ")

	formatReq := validMikroValidationRequest(t)
	formatReq.ProviderErrorCode = MikroProviderErrorFormat
	formatDecision, err := runtime.Evaluate(formatReq)
	if err != nil {
		t.Fatalf("format mapping should not error: %v", err)
	}
	if !formatDecision.Allowed || formatDecision.Action != MikroValidationActionDLQ || !formatDecision.SendToDLQ {
		t.Fatalf("format error must be DLQ")
	}
	logMikroValidationOK(t, "7-8M.4.3.4", "MIKRO_FORMAT_ERROR maps to DLQ")

	authReq := validMikroValidationRequest(t)
	authReq.ProviderErrorCode = MikroProviderErrorAuthFailed
	authDecision, err := runtime.Evaluate(authReq)
	if err != nil {
		t.Fatalf("auth mapping should not error: %v", err)
	}
	if !authDecision.Allowed || authDecision.Action != MikroValidationActionManualReview || !authDecision.ManualReview {
		t.Fatalf("auth error must be manual review")
	}
	logMikroValidationOK(t, "7-8M.4.3.5", "MIKRO_AUTH_FAILED maps to manual review")

	unknownReq := validMikroValidationRequest(t)
	unknownReq.ProviderErrorCode = "MIKRO_VENDOR_SPECIFIC_UNKNOWN"
	unknownDecision, err := runtime.Evaluate(unknownReq)
	if err != nil {
		t.Fatalf("unknown provider error should not error: %v", err)
	}
	if !unknownDecision.Allowed || unknownDecision.Action != MikroValidationActionManualReview || !unknownDecision.ManualReview {
		t.Fatalf("unknown provider error must be manual review")
	}
	logMikroValidationOK(t, "7-8M.4.3.6", "unknown provider error maps to manual review")
}

func TestMikroValidationClosedRealOperations(t *testing.T) {
	runtime := NewMikroValidationRetryDLQRuntime()
	contract := runtime.Contract

	if contract.RealProviderAPIStatus != MikroRealProviderAPIStatus {
		t.Fatalf("real provider API must stay closed")
	}
	if contract.RealFileDeliveryStatus != MikroRealFileDeliveryStatus {
		t.Fatalf("real file delivery must stay closed")
	}
	if contract.RealERPWriteStatus != MikroRealERPWriteStatus {
		t.Fatalf("real ERP write must stay closed")
	}
	if contract.RealDeliveryChannelStatus != MikroRealDeliveryChannelStatus {
		t.Fatalf("real delivery channel must stay closed")
	}

	logMikroValidationOK(t, "7-8M.4.4", "closed real operation gates validation")
	logMikroValidationOK(t, "7-8M.4.4.1", "real Mikro provider API is closed")
	logMikroValidationOK(t, "7-8M.4.4.2", "real Mikro file delivery is closed")
	logMikroValidationOK(t, "7-8M.4.4.3", "real ERP write is closed")
	logMikroValidationOK(t, "7-8M.4.4.4", "real delivery channel is closed")

	apiReq := validMikroValidationRequest(t)
	apiReq.RealProviderAPIEnabled = true
	apiDecision, err := runtime.Evaluate(apiReq)
	if err != nil {
		t.Fatalf("real api decision should deny without runtime error: %v", err)
	}
	if apiDecision.Allowed || apiDecision.Reason != MikroValidationDecisionRealAPI {
		t.Fatalf("real provider API must be denied")
	}
	logMikroValidationOK(t, "7-8M.4.4.5", "real Mikro API request is denied")

	fileReq := validMikroValidationRequest(t)
	fileReq.RealFileDeliveryEnabled = true
	fileDecision, err := runtime.Evaluate(fileReq)
	if err != nil {
		t.Fatalf("real file delivery decision should deny without runtime error: %v", err)
	}
	if fileDecision.Allowed || fileDecision.Reason != MikroValidationDecisionRealFile {
		t.Fatalf("real file delivery must be denied")
	}
	logMikroValidationOK(t, "7-8M.4.4.6", "real Mikro file delivery request is denied")

	erpReq := validMikroValidationRequest(t)
	erpReq.RealERPWriteEnabled = true
	erpDecision, err := runtime.Evaluate(erpReq)
	if err != nil {
		t.Fatalf("real ERP write decision should deny without runtime error: %v", err)
	}
	if erpDecision.Allowed || erpDecision.Reason != MikroValidationDecisionRealERP {
		t.Fatalf("real ERP write must be denied")
	}
	logMikroValidationOK(t, "7-8M.4.4.7", "real ERP write request is denied")

	deliveryReq := validMikroValidationRequest(t)
	deliveryReq.RealDeliveryEnabled = true
	deliveryDecision, err := runtime.Evaluate(deliveryReq)
	if err != nil {
		t.Fatalf("real delivery decision should deny without runtime error: %v", err)
	}
	if deliveryDecision.Allowed || deliveryDecision.Reason != MikroValidationDecisionRealDelivery {
		t.Fatalf("real delivery channel must be denied")
	}
	logMikroValidationOK(t, "7-8M.4.4.8", "real delivery channel request is denied")
}

func TestMikroValidationRequestPackageAndSecretGuards(t *testing.T) {
	runtime := NewMikroValidationRetryDLQRuntime()

	missingValidation := validMikroValidationRequest(t)
	missingValidation.ValidationID = ""
	_, err := runtime.Evaluate(missingValidation)
	if err == nil {
		t.Fatalf("missing validation id must fail")
	}
	logMikroValidationOK(t, "7-8M.4.5", "request package and secret guard validation")
	logMikroValidationOK(t, "7-8M.4.5.1", "missing validation id is rejected")

	badChecksum := validMikroValidationRequest(t)
	badChecksum.Package.Manifest.Checksum = "bad-checksum"
	badDecision, err := runtime.Evaluate(badChecksum)
	if err == nil {
		t.Fatalf("bad checksum must fail")
	}
	if badDecision.Action != MikroValidationActionDLQ || !badDecision.SendToDLQ {
		t.Fatalf("bad checksum must be classified for DLQ")
	}
	logMikroValidationOK(t, "7-8M.4.5.2", "checksum mismatch is classified for DLQ")

	emptyContent := validMikroValidationRequest(t)
	emptyContent.Package.VirtualContent = ""
	emptyDecision, err := runtime.Evaluate(emptyContent)
	if err == nil {
		t.Fatalf("empty virtual content must fail")
	}
	if emptyDecision.Action != MikroValidationActionDLQ || !emptyDecision.SendToDLQ {
		t.Fatalf("empty virtual content must be classified for DLQ")
	}
	logMikroValidationOK(t, "7-8M.4.5.3", "empty virtual content is classified for DLQ")

	liveMode := validMikroValidationRequest(t)
	liveMode.RequestedMode = "PROVIDER_LIVE"
	liveDecision, err := runtime.Evaluate(liveMode)
	if err != nil {
		t.Fatalf("provider live mode should deny without runtime error: %v", err)
	}
	if liveDecision.Allowed || liveDecision.Reason != MikroValidationDecisionLiveMode {
		t.Fatalf("provider live mode must be denied")
	}
	logMikroValidationOK(t, "7-8M.4.5.4", "provider live mode is denied")

	secretReq := validMikroValidationRequest(t)
	secretReq.InjectedFieldName = "client_secret"
	_, err = runtime.Evaluate(secretReq)
	if !errors.Is(err, ErrMikroValidationSecretForbidden) {
		t.Fatalf("client_secret field must be forbidden")
	}
	logMikroValidationOK(t, "7-8M.4.5.5", "client_secret field is rejected")
}
