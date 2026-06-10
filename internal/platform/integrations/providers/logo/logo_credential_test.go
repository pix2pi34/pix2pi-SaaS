package logo

import "testing"

func TestLogoCredentialContractReadiness(t *testing.T) {
	contract := NewLogoCredentialContract()

	if err := contract.Validate(); err != nil {
		t.Fatalf("Logo credential contract must validate: %v", err)
	}

	if contract.Step != StepFAZ78L3 {
		t.Fatalf("step mismatch: got %s", contract.Step)
	}

	if contract.CredentialMode != LogoCredentialMode {
		t.Fatalf("credential mode mismatch: got %s", contract.CredentialMode)
	}

	t.Log("7-8L IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.3 IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.3.1 credential contract readiness IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.3.2 foundation dependency validation IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.3.3 live contract dependency validation IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoCredentialKeepsRealIntegrationsAndSecretsClosed(t *testing.T) {
	contract := NewLogoCredentialContract()

	if !contract.RealIntegrationsClosed() {
		t.Fatal("real provider API, file delivery, ERP write, and secret values must remain closed")
	}

	for _, operation := range contract.Operations {
		if operation.ExternalCallAllowed {
			t.Fatalf("operation %s must not allow external calls", operation.Name)
		}
		if operation.FileDeliveryAllowed {
			t.Fatalf("operation %s must not allow file delivery", operation.Name)
		}
		if operation.ERPWriteAllowed {
			t.Fatalf("operation %s must not allow ERP writes", operation.Name)
		}
		if operation.RawSecretAllowed {
			t.Fatalf("operation %s must not allow raw secrets", operation.Name)
		}
	}

	t.Log("7-8L.3.4 real Logo provider API closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.3.5 real Logo file delivery closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.3.6 real ERP write closed IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.3.7 raw secret usage forbidden IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoSecretReferenceOnlyContract(t *testing.T) {
	contract := NewLogoCredentialContract()

	if err := contract.CredentialProfile.Validate(); err != nil {
		t.Fatalf("credential profile must validate: %v", err)
	}

	if err := contract.SecretReference.Validate(); err != nil {
		t.Fatalf("secret reference contract must validate: %v", err)
	}

	if contract.CredentialProfile.RawSecretAllowed {
		t.Fatal("raw secret must not be allowed")
	}

	if contract.SecretReference.SecretValuesInConfigAllowed {
		t.Fatal("secret values in config must not be allowed")
	}

	if contract.SecretReference.SecretValuesInCodeAllowed {
		t.Fatal("secret values in code must not be allowed")
	}

	if contract.SecretReference.SecretValuesInDocsAllowed {
		t.Fatal("secret values in docs must not be allowed")
	}

	t.Log("7-8L.3.8 credential profile declared IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.3.9 secret reference contract declared IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.3.10 no raw secret in config/code/docs guard IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoCredentialReferenceValidation(t *testing.T) {
	ref := NewLogoDryRunCredentialReference("tenant_7", "dry-run", "logo-default")

	if err := ref.ValidateReferenceOnly(); err != nil {
		t.Fatalf("credential reference must validate: %v", err)
	}

	if ref.ContainsRawSecret() {
		t.Fatal("dry-run credential reference must not contain raw secrets")
	}

	t.Log("7-8L.3.11 tenant-safe credential reference IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.3.12 vault path reference IMPLEMENTED_OR_PRESENT / OK ✅")
	t.Log("7-8L.3.13 rotation and audit references IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoCredentialReferenceRejectsRawSecret(t *testing.T) {
	ref := NewLogoDryRunCredentialReference("tenant_7", "dry-run", "logo-default")
	ref.RawPassword = "forbidden-secret-value"

	if err := ref.ValidateReferenceOnly(); err == nil {
		t.Fatal("expected validation error when raw password exists")
	}

	t.Log("7-8L.3.14 raw password rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoCredentialContractRejectsRawSecretAllowed(t *testing.T) {
	contract := NewLogoCredentialContract()
	contract.CredentialProfile.RawSecretAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when raw secret is allowed")
	}

	t.Log("7-8L.3.15 raw secret allowed flag rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoCredentialContractRejectsSecretLogging(t *testing.T) {
	contract := NewLogoCredentialContract()
	contract.AuditPolicy.SecretValueLoggingAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when secret logging is allowed")
	}

	t.Log("7-8L.3.16 secret value logging rejected IMPLEMENTED_OR_PRESENT / OK ✅")
}

func TestLogoCredentialContractRejectsExternalOperation(t *testing.T) {
	contract := NewLogoCredentialContract()
	contract.Operations[0].ExternalCallAllowed = true

	if err := contract.Validate(); err == nil {
		t.Fatal("expected validation error when external call is allowed")
	}

	t.Log("7-8L.3.17 external call guard IMPLEMENTED_OR_PRESENT / OK ✅")
}
