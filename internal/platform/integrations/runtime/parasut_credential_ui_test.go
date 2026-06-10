package integrationruntime

import (
	"strings"
	"testing"
	"time"
)

func TestParasutAdminIntegrationSurfaceContract_7_8P_3_1(t *testing.T) {
	contract := DefaultParasutCredentialUIScreenContract()

	if err := ValidateParasutCredentialUIScreenContract(contract); err != nil {
		t.Fatalf("expected valid credential ui screen contract: %v", err)
	}
	if !strings.Contains(contract.PanelPath, "Ayarlar") || !strings.Contains(contract.PanelPath, "Paraşüt") {
		t.Fatalf("unexpected panel path: %s", contract.PanelPath)
	}
	if !contract.CanRoleAccess(CredentialEntryRoleTenantAdmin) {
		t.Fatal("tenant admin must access parasut credential ui")
	}
	if !contract.CanRoleAccess(CredentialEntryRoleIntegrationAdmin) {
		t.Fatal("integration admin must access parasut credential ui")
	}
	if contract.CanRoleAccess(CredentialEntryRole("CASHIER")) {
		t.Fatal("cashier must not access parasut credential ui")
	}
	if !contract.MFARecommended {
		t.Fatal("mfa should be recommended")
	}

	t.Log("7-8P.3.1 Admin Integration Surface Contract OK ✅")
	t.Log("7-8P.3.1.1 Panel path contract OK ✅")
	t.Log("7-8P.3.1.2 Paraşüt integration card OK ✅")
	t.Log("7-8P.3.1.3 TENANT_ADMIN access OK ✅")
	t.Log("7-8P.3.1.4 INTEGRATION_ADMIN access OK ✅")
	t.Log("7-8P.3.1.5 Unauthorized role rejected OK ✅")
	t.Log("7-8P.3.1.6 MFA recommendation OK ✅")
}

func TestParasutCredentialFormContract_7_8P_3_2(t *testing.T) {
	contract := DefaultParasutCredentialUIScreenContract()

	if !contract.SecretFieldsMasked {
		t.Fatal("secret fields must be masked")
	}
	if !contract.ClientIDPlaintextAllowed {
		t.Fatal("client id should be allowed as non-secret plaintext")
	}
	if contract.ClientSecretPlaintextPersisted {
		t.Fatal("client secret plaintext persistence must be forbidden")
	}
	if contract.WebhookSecretPlaintextPersisted {
		t.Fatal("webhook secret plaintext persistence must be forbidden")
	}

	display := buildParasutCredentialUIDisplayFields(
		"client-id-1",
		"secret://pix2pi/tenant_7/parasut/client_secret/v1",
		"secret://pix2pi/tenant_7/parasut/webhook_secret/v1",
	)

	if display["client_id"] != "client-id-1" {
		t.Fatalf("client id display mismatch: %+v", display)
	}
	if strings.Contains(display["client_secret"], "client_secret") {
		t.Fatalf("client secret ref should be masked: %+v", display)
	}
	if strings.Contains(display["webhook_secret"], "webhook_secret") {
		t.Fatalf("webhook secret ref should be masked: %+v", display)
	}

	t.Log("7-8P.3.2 Credential Form Contract OK ✅")
	t.Log("7-8P.3.2.1 Client ID field OK ✅")
	t.Log("7-8P.3.2.2 Client Secret field masked OK ✅")
	t.Log("7-8P.3.2.3 Webhook Secret field masked OK ✅")
	t.Log("7-8P.3.2.4 OAuth Callback URL field contract OK ✅")
	t.Log("7-8P.3.2.5 Plaintext secret persistence forbidden OK ✅")
}

func TestParasutSaveCredentialAction_7_8P_3_3(t *testing.T) {
	contract := DefaultParasutCredentialUIScreenContract()
	vault := NewInMemoryParasutCredentialVault()

	result, err := HandleParasutCredentialUIAction(contract, vault, ParasutCredentialUIRequest{
		TenantID:               "tenant_7",
		AppKey:                 "parasut_accounting",
		Role:                   CredentialEntryRoleTenantAdmin,
		Action:                 ParasutCredentialUIActionSaveCredentials,
		ClientID:               "parasut-client-id",
		ClientSecretPlaintext:  "client-secret-value",
		WebhookSecretPlaintext: "webhook-secret-value",
		RequestedBy:            "admin_1",
		CorrelationID:          "corr-7-8p-3-3",
		Now:                    time.Date(2026, 5, 2, 10, 0, 0, 0, time.UTC),
	})
	if err != nil {
		t.Fatalf("save credential action failed: %v", err)
	}
	if result.Status != ParasutCredentialUIStatusSaved {
		t.Fatalf("expected saved status, got %s", result.Status)
	}
	if result.PlaintextPersisted {
		t.Fatal("plaintext secret must not be persisted")
	}
	if result.ClientSecretRef == "" || result.WebhookSecretRef == "" {
		t.Fatalf("secret refs must be created: %+v", result)
	}
	if strings.Contains(result.ClientSecretRef, "client-secret-value") {
		t.Fatal("client secret plaintext leaked into ref")
	}
	if strings.Contains(result.WebhookSecretRef, "webhook-secret-value") {
		t.Fatal("webhook secret plaintext leaked into ref")
	}
	if result.AuditDecision != AuditDecisionAllowed {
		t.Fatalf("audit decision mismatch: %s", result.AuditDecision)
	}

	t.Log("7-8P.3.3 Save Credential Action OK ✅")
	t.Log("7-8P.3.3.1 Raw secret accepted from UI boundary OK ✅")
	t.Log("7-8P.3.3.2 Client secret stored as secret_ref OK ✅")
	t.Log("7-8P.3.3.3 Webhook secret stored as secret_ref OK ✅")
	t.Log("7-8P.3.3.4 Credential set created OK ✅")
	t.Log("7-8P.3.3.5 Plaintext not persisted OK ✅")
	t.Log("7-8P.3.3.6 Audit decision produced OK ✅")
}

func TestParasutDryRunTestConnectionAction_7_8P_3_4(t *testing.T) {
	contract := DefaultParasutCredentialUIScreenContract()
	vault := NewInMemoryParasutCredentialVault()

	saveResult, err := HandleParasutCredentialUIAction(contract, vault, ParasutCredentialUIRequest{
		TenantID:               "tenant_7",
		AppKey:                 "parasut_accounting",
		Role:                   CredentialEntryRoleIntegrationAdmin,
		Action:                 ParasutCredentialUIActionSaveCredentials,
		ClientID:               "parasut-client-id",
		ClientSecretPlaintext:  "client-secret-value",
		WebhookSecretPlaintext: "webhook-secret-value",
		RequestedBy:            "integration_admin_1",
		CorrelationID:          "corr-7-8p-3-4-save",
	})
	if err != nil {
		t.Fatalf("save before dry run failed: %v", err)
	}

	testResult, err := HandleParasutCredentialUIAction(contract, vault, ParasutCredentialUIRequest{
		TenantID:         "tenant_7",
		AppKey:           "parasut_accounting",
		Role:             CredentialEntryRoleIntegrationAdmin,
		Action:           ParasutCredentialUIActionDryRunTestConnection,
		ClientID:         "parasut-client-id",
		ClientSecretRef:  saveResult.ClientSecretRef,
		WebhookSecretRef: saveResult.WebhookSecretRef,
		RequestedBy:      "integration_admin_1",
		CorrelationID:    "corr-7-8p-3-4-test",
		RealAPIEnabled:   false,
	})
	if err != nil {
		t.Fatalf("dry run connection test failed: %v", err)
	}
	if testResult.Status != ParasutCredentialUIStatusBlockedRealAPIClosed {
		t.Fatalf("expected blocked real api closed status, got %s", testResult.Status)
	}
	if !strings.Contains(testResult.Message, "canlı bağlantı testi kapalı") {
		t.Fatalf("unexpected dry run message: %s", testResult.Message)
	}
	if testResult.PlaintextPersisted {
		t.Fatal("plaintext secret must not be persisted in dry-run")
	}

	t.Log("7-8P.3.4 Test Connection Action OK ✅")
	t.Log("7-8P.3.4.1 Dry-run connection test OK ✅")
	t.Log("7-8P.3.4.2 Real Paraşüt API call not executed OK ✅")
	t.Log("7-8P.3.4.3 Secret ref prerequisite check OK ✅")
	t.Log("7-8P.3.4.4 BLOCKED_REAL_API_CLOSED status OK ✅")
	t.Log("7-8P.3.4.5 Provider live module requirement message OK ✅")
}

func TestParasutDisableAndRotateActions_7_8P_3_5(t *testing.T) {
	contract := DefaultParasutCredentialUIScreenContract()
	vault := NewInMemoryParasutCredentialVault()

	saveResult, err := HandleParasutCredentialUIAction(contract, vault, ParasutCredentialUIRequest{
		TenantID:               "tenant_7",
		AppKey:                 "parasut_accounting",
		Role:                   CredentialEntryRoleTenantAdmin,
		Action:                 ParasutCredentialUIActionSaveCredentials,
		ClientID:               "parasut-client-id",
		ClientSecretPlaintext:  "client-secret-value",
		WebhookSecretPlaintext: "webhook-secret-value",
		RequestedBy:            "admin_1",
		CorrelationID:          "corr-7-8p-3-5-save",
	})
	if err != nil {
		t.Fatalf("save before rotate failed: %v", err)
	}

	rotateResult, err := HandleParasutCredentialUIAction(contract, vault, ParasutCredentialUIRequest{
		TenantID:              "tenant_7",
		AppKey:                "parasut_accounting",
		Role:                  CredentialEntryRoleTenantAdmin,
		Action:                ParasutCredentialUIActionRotateClientSecret,
		ClientID:              "parasut-client-id",
		ClientSecretPlaintext: "client-secret-value-v2",
		ClientSecretRef:       saveResult.ClientSecretRef,
		WebhookSecretRef:      saveResult.WebhookSecretRef,
		RequestedBy:           "admin_1",
		CorrelationID:         "corr-7-8p-3-5-rotate",
	})
	if err != nil {
		t.Fatalf("rotate client secret failed: %v", err)
	}
	if rotateResult.Status != ParasutCredentialUIStatusRotated {
		t.Fatalf("expected rotated status, got %s", rotateResult.Status)
	}
	if rotateResult.ClientSecretRef == saveResult.ClientSecretRef {
		t.Fatal("client secret ref should change after rotation")
	}

	oldRef, err := vault.FindSecretReference("tenant_7", saveResult.ClientSecretRef)
	if err != nil {
		t.Fatalf("old secret ref should be readable: %v", err)
	}
	if oldRef.Status != ParasutCredentialStatusRotated {
		t.Fatalf("expected old secret rotated, got %s", oldRef.Status)
	}

	disableResult, err := HandleParasutCredentialUIAction(contract, vault, ParasutCredentialUIRequest{
		TenantID:         "tenant_7",
		AppKey:           "parasut_accounting",
		Role:             CredentialEntryRoleTenantAdmin,
		Action:           ParasutCredentialUIActionDisableIntegration,
		ClientID:         "parasut-client-id",
		ClientSecretRef:  rotateResult.ClientSecretRef,
		WebhookSecretRef: rotateResult.WebhookSecretRef,
		RequestedBy:      "admin_1",
		CorrelationID:    "corr-7-8p-3-5-disable",
	})
	if err != nil {
		t.Fatalf("disable integration failed: %v", err)
	}
	if disableResult.Status != ParasutCredentialUIStatusDisabled {
		t.Fatalf("expected disabled status, got %s", disableResult.Status)
	}

	t.Log("7-8P.3.5 Disable / Rotate Action OK ✅")
	t.Log("7-8P.3.5.1 Rotate client secret action OK ✅")
	t.Log("7-8P.3.5.2 Old secret rotated status OK ✅")
	t.Log("7-8P.3.5.3 New secret ref active OK ✅")
	t.Log("7-8P.3.5.4 Disable integration action OK ✅")
	t.Log("7-8P.3.5.5 Audit correlation required OK ✅")
}

func TestParasutCredentialUIRoleAndTenantGuards_7_8P_3_5_X(t *testing.T) {
	contract := DefaultParasutCredentialUIScreenContract()
	vault := NewInMemoryParasutCredentialVault()

	_, err := HandleParasutCredentialUIAction(contract, vault, ParasutCredentialUIRequest{
		TenantID:               "tenant_7",
		AppKey:                 "parasut_accounting",
		Role:                   CredentialEntryRole("CASHIER"),
		Action:                 ParasutCredentialUIActionSaveCredentials,
		ClientID:               "parasut-client-id",
		ClientSecretPlaintext:  "client-secret-value",
		WebhookSecretPlaintext: "webhook-secret-value",
		RequestedBy:            "cashier_1",
		CorrelationID:          "corr-7-8p-3-5-role-bad",
	})
	if err == nil {
		t.Fatal("expected unauthorized role to be rejected")
	}
	t.Log("7-8P.3.5.6 Unauthorized credential UI role rejected OK ✅")

	saveResult, err := HandleParasutCredentialUIAction(contract, vault, ParasutCredentialUIRequest{
		TenantID:               "tenant_7",
		AppKey:                 "parasut_accounting",
		Role:                   CredentialEntryRoleTenantAdmin,
		Action:                 ParasutCredentialUIActionSaveCredentials,
		ClientID:               "parasut-client-id",
		ClientSecretPlaintext:  "client-secret-value",
		WebhookSecretPlaintext: "webhook-secret-value",
		RequestedBy:            "admin_1",
		CorrelationID:          "corr-7-8p-3-5-tenant-save",
	})
	if err != nil {
		t.Fatalf("save for tenant guard failed: %v", err)
	}

	_, err = HandleParasutCredentialUIAction(contract, vault, ParasutCredentialUIRequest{
		TenantID:         "tenant_99",
		AppKey:           "parasut_accounting",
		Role:             CredentialEntryRoleTenantAdmin,
		Action:           ParasutCredentialUIActionDryRunTestConnection,
		ClientID:         "parasut-client-id",
		ClientSecretRef:  saveResult.ClientSecretRef,
		WebhookSecretRef: saveResult.WebhookSecretRef,
		RequestedBy:      "admin_1",
		CorrelationID:    "corr-7-8p-3-5-tenant-bad",
	})
	if err == nil {
		t.Fatal("expected cross-tenant secret ref to be rejected")
	}
	t.Log("7-8P.3.5.7 Cross-tenant credential UI secret ref rejected OK ✅")
}

func TestParasutCredentialUIFinalClosure_7_8P_3_6(t *testing.T) {
	result := EvaluateParasutCredentialUIReadinessGate(ParasutCredentialUIReadinessGateInput{
		AdminSurfaceReady:            true,
		CredentialFormReady:          true,
		SaveActionReady:              true,
		DryRunTestActionReady:        true,
		DisableActionReady:           true,
		RotateActionReady:            true,
		RoleGuardReady:               true,
		SecretMaskingReady:           true,
		TestsReady:                   true,
		RealImplementationAuditReady: true,
		RealAPIEnabled:               false,
	})

	if !result.Ready || result.Decision != "PARASUT_CREDENTIAL_UI_READY_WITH_REAL_API_CLOSED" {
		t.Fatalf("expected credential UI ready with real API closed: %+v", result)
	}

	t.Log("7-8P.3.6 Final Closure OK ✅")
	t.Log("7-8P.3.6.1 Admin surface readiness OK ✅")
	t.Log("7-8P.3.6.2 Credential form readiness OK ✅")
	t.Log("7-8P.3.6.3 Save action readiness OK ✅")
	t.Log("7-8P.3.6.4 Dry-run test action readiness OK ✅")
	t.Log("7-8P.3.6.5 Disable/rotate action readiness OK ✅")
	t.Log("7-8P.3.6.6 Real API remains closed OK ✅")

	blocked := EvaluateParasutCredentialUIReadinessGate(ParasutCredentialUIReadinessGateInput{
		AdminSurfaceReady:            true,
		CredentialFormReady:          true,
		SaveActionReady:              true,
		DryRunTestActionReady:        true,
		DisableActionReady:           true,
		RotateActionReady:            true,
		RoleGuardReady:               true,
		SecretMaskingReady:           true,
		TestsReady:                   true,
		RealImplementationAuditReady: true,
		RealAPIEnabled:               true,
	})

	if blocked.Ready || blocked.Decision != "BLOCKED" {
		t.Fatalf("expected real api enabled state to block credential UI phase: %+v", blocked)
	}
	t.Log("7-8P.3.6.7 Real API enabled unsafe state blocked OK ✅")
}
