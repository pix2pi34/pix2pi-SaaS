package logo

import "testing"

func buildLogoValidDeliveryEnvelopeForValidation(t *testing.T) LogoImportDeliveryEnvelope {
	t.Helper()

	fileContract := NewLogoFileGenerationContract()
	input := NewLogoSampleDryRunExportInput()

	pkg, err := fileContract.GenerateDryRunImportPackage(input)
	if err != nil {
		t.Fatalf("dry-run import package must be generated: %v", err)
	}

	deliveryContract := NewLogoImportDeliveryContract()
	envelope, err := deliveryContract.PrepareDryRunDeliveryEnvelope(LogoDeliveryChannelManualUpload, pkg)
	if err != nil {
		t.Fatalf("delivery envelope must be prepared: %v", err)
	}

	return envelope
}

func TestLogoValidationRetryDLQContractReadiness(t *testing.T) {
	contract := NewLogoValidationRetryDLQContract()

	if err := contract.Validate(); err != nil {
		t.Fatalf("Logo validation retry-DLQ contract must validate: %v", err)
	}

	if contract.Step != StepFAZ78L7 {
		t.Fatalf("step mismatch: got %s", contract.Step)
	}

	if contract.ValidationMode != LogoValidationRetryDLQMode {
		t.Fatalf("validation mode mismatch: got %s", contract.ValidationMode)
	}

	t.Log("7-8L IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.7 IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.7.1 validation retry-DLQ contract readiness IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.7.2 import delivery dependency validation IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoValidationRetryDLQKeepsRealIntegrationsClosed(t *testing.T) {
	contract := NewLogoValidationRetryDLQContract()

	if !contract.RealIntegrationsClosed() {
		t.Fatal("real provider API, file delivery, and ERP write must remain closed")
	}

	for _, operation := range contract.Operations {
		if !operation.DryRunValidationAllowed {
			t.Fatalf("operation %s must allow dry-run validation", operation.Name)
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

	t.Log("7-8L.7.3 dry-run validation allowed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.7.4 real Logo provider API closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.7.5 real Logo file delivery closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.7.6 real ERP write closed IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoValidationEnvelopePasses(t *testing.T) {
	contract := NewLogoValidationRetryDLQContract()
	envelope := buildLogoValidDeliveryEnvelopeForValidation(t)

	result := contract.ValidateEnvelope(envelope, "tenant_7")
	if !result.Valid {
		t.Fatalf("expected valid envelope, got errors: %+v", result.Errors)
	}

	t.Log("7-8L.7.7 delivery envelope validation IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.7.8 checksum validation IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.7.9 manifest validation IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.7.10 tenant/correlation/idempotency validation IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoValidationRejectsMissingTenantAsDLQ(t *testing.T) {
	contract := NewLogoValidationRetryDLQContract()
	envelope := buildLogoValidDeliveryEnvelopeForValidation(t)
	envelope.TenantID = ""

	result := contract.ValidateEnvelope(envelope, "tenant_7")
	if result.Valid {
		t.Fatal("expected invalid envelope when tenant_id is missing")
	}

	decision := contract.Decide(result.Errors[0].Code, 0)
	if decision.Action != LogoDecisionDLQ || !decision.DLQ {
		t.Fatalf("expected DLQ decision, got %+v", decision)
	}

	t.Log("7-8L.7.11 missing tenant validation error IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.7.12 validation error DLQ decision IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoValidationTenantBoundaryManualReview(t *testing.T) {
	contract := NewLogoValidationRetryDLQContract()
	envelope := buildLogoValidDeliveryEnvelopeForValidation(t)
	envelope.TenantID = "tenant_99"

	result := contract.ValidateEnvelope(envelope, "tenant_7")
	if result.Valid {
		t.Fatal("expected tenant boundary validation failure")
	}

	found := false
	for _, validationError := range result.Errors {
		if validationError.Code == LogoErrorTenantBoundaryViolation {
			found = true
			decision := contract.Decide(validationError.Code, 0)
			if decision.Action != LogoDecisionManualReview || !decision.ManualReview {
				t.Fatalf("expected manual review decision, got %+v", decision)
			}
		}
	}
	if !found {
		t.Fatal("expected tenant boundary violation error")
	}

	t.Log("7-8L.7.13 tenant boundary violation detected IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.7.14 tenant boundary manual review decision IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoValidationChecksumManualReview(t *testing.T) {
	contract := NewLogoValidationRetryDLQContract()
	envelope := buildLogoValidDeliveryEnvelopeForValidation(t)
	envelope.ChecksumSHA256 = ""

	result := contract.ValidateEnvelope(envelope, "tenant_7")
	if result.Valid {
		t.Fatal("expected checksum validation failure")
	}

	decision := contract.Decide(LogoErrorChecksumMismatch, 0)
	if decision.Action != LogoDecisionManualReview || !decision.ManualReview {
		t.Fatalf("expected manual review decision, got %+v", decision)
	}

	t.Log("7-8L.7.15 checksum mismatch detected IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.7.16 checksum manual review decision IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoValidationInvalidManifestDLQ(t *testing.T) {
	contract := NewLogoValidationRetryDLQContract()
	envelope := buildLogoValidDeliveryEnvelopeForValidation(t)
	envelope.Manifest = nil

	result := contract.ValidateEnvelope(envelope, "tenant_7")
	if result.Valid {
		t.Fatal("expected invalid manifest validation failure")
	}

	decision := contract.Decide(LogoErrorInvalidManifest, 0)
	if decision.Action != LogoDecisionDLQ || !decision.DLQ {
		t.Fatalf("expected DLQ decision, got %+v", decision)
	}

	t.Log("7-8L.7.17 invalid manifest detected IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.7.18 manifest error DLQ decision IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoRetryDecisionForTransientProviderError(t *testing.T) {
	contract := NewLogoValidationRetryDLQContract()

	decision := contract.Decide(LogoErrorProviderTimeout, 0)
	if decision.Action != LogoDecisionRetry || !decision.RetryAllowed {
		t.Fatalf("expected retry decision, got %+v", decision)
	}
	if decision.NextAttempt != 1 {
		t.Fatalf("expected next attempt 1, got %d", decision.NextAttempt)
	}
	if decision.BackoffSeconds != 10 {
		t.Fatalf("expected backoff 10, got %d", decision.BackoffSeconds)
	}

	t.Log("7-8L.7.19 provider timeout retry decision IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.7.20 retry backoff policy IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoRetryLimitExceededGoesToDLQ(t *testing.T) {
	contract := NewLogoValidationRetryDLQContract()

	decision := contract.Decide(LogoErrorProviderRateLimit, 3)
	if decision.Action != LogoDecisionDLQ || !decision.DLQ {
		t.Fatalf("expected DLQ after retry limit exceeded, got %+v", decision)
	}

	t.Log("7-8L.7.21 retry limit guard IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.7.22 retry limit DLQ decision IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoPermanentProviderRejectedPackageGoesToDLQ(t *testing.T) {
	contract := NewLogoValidationRetryDLQContract()

	decision := contract.Decide(LogoErrorProviderRejectedPackage, 0)
	if decision.Action != LogoDecisionDLQ || !decision.DLQ {
		t.Fatalf("expected DLQ for permanent provider rejection, got %+v", decision)
	}

	t.Log("7-8L.7.23 permanent provider rejection mapping IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.7.24 permanent provider rejection DLQ IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoUnknownProviderErrorManualReview(t *testing.T) {
	contract := NewLogoValidationRetryDLQContract()

	decision := contract.Decide(LogoErrorUnknownProvider, 0)
	if decision.Action != LogoDecisionManualReview || !decision.ManualReview {
		t.Fatalf("expected manual review for unknown provider error, got %+v", decision)
	}

	t.Log("7-8L.7.25 unknown provider error mapping IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.7.26 unknown provider manual review IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoValidationRejectsExternalOperation(t *testing.T) {
	contract := NewLogoValidationRetryDLQContract()
	contract.Operations[0].ExternalCallAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when external call is allowed")
	}

	t.Log("7-8L.7.27 external call guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoValidationRejectsRealFileDeliveryOperation(t *testing.T) {
	contract := NewLogoValidationRetryDLQContract()
	contract.Operations[0].RealFileDeliveryAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when real file delivery is allowed")
	}

	t.Log("7-8L.7.28 real file delivery guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoValidationRejectsERPWriteOperation(t *testing.T) {
	contract := NewLogoValidationRetryDLQContract()
	contract.Operations[0].ERPWriteAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when ERP write is allowed")
	}

	t.Log("7-8L.7.29 ERP write guard IMPLEMENTED_OR_PRESENT / OK ✅")
}
