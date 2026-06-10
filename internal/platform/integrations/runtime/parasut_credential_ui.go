package integrationruntime

import (
	"fmt"
	"strings"
	"time"
)

type ParasutCredentialUIAction string

const (
	ParasutCredentialUIActionSaveCredentials      ParasutCredentialUIAction = "SAVE_CREDENTIALS"
	ParasutCredentialUIActionDryRunTestConnection ParasutCredentialUIAction = "DRY_RUN_TEST_CONNECTION"
	ParasutCredentialUIActionDisableIntegration   ParasutCredentialUIAction = "DISABLE_INTEGRATION"
	ParasutCredentialUIActionRotateClientSecret   ParasutCredentialUIAction = "ROTATE_CLIENT_SECRET"
	ParasutCredentialUIActionRotateWebhookSecret  ParasutCredentialUIAction = "ROTATE_WEBHOOK_SECRET"
)

type ParasutCredentialUIStatus string

const (
	ParasutCredentialUIStatusDraft                ParasutCredentialUIStatus = "DRAFT"
	ParasutCredentialUIStatusSaved                ParasutCredentialUIStatus = "SAVED"
	ParasutCredentialUIStatusDryRunOK             ParasutCredentialUIStatus = "DRY_RUN_OK"
	ParasutCredentialUIStatusBlockedRealAPIClosed ParasutCredentialUIStatus = "BLOCKED_REAL_API_CLOSED"
	ParasutCredentialUIStatusDisabled             ParasutCredentialUIStatus = "DISABLED"
	ParasutCredentialUIStatusRotated              ParasutCredentialUIStatus = "ROTATED"
)

type ParasutCredentialUIScreenContract struct {
	PanelPath                       string
	IntegrationCard                 string
	AllowedRoles                    []CredentialEntryRole
	MFARecommended                  bool
	SecretFieldsMasked              bool
	ClientIDPlaintextAllowed        bool
	ClientSecretPlaintextPersisted  bool
	WebhookSecretPlaintextPersisted bool
	Actions                         []ParasutCredentialUIAction
	Fields                          []string
}

func DefaultParasutCredentialUIScreenContract() ParasutCredentialUIScreenContract {
	return ParasutCredentialUIScreenContract{
		PanelPath:       "Panel > Ayarlar > Entegrasyonlar > Paraşüt > Bağlan / API Bilgileri",
		IntegrationCard: "Paraşüt",
		AllowedRoles: []CredentialEntryRole{
			CredentialEntryRoleTenantAdmin,
			CredentialEntryRoleIntegrationAdmin,
		},
		MFARecommended:                  true,
		SecretFieldsMasked:              true,
		ClientIDPlaintextAllowed:        true,
		ClientSecretPlaintextPersisted:  false,
		WebhookSecretPlaintextPersisted: false,
		Actions: []ParasutCredentialUIAction{
			ParasutCredentialUIActionSaveCredentials,
			ParasutCredentialUIActionDryRunTestConnection,
			ParasutCredentialUIActionDisableIntegration,
			ParasutCredentialUIActionRotateClientSecret,
			ParasutCredentialUIActionRotateWebhookSecret,
		},
		Fields: []string{
			"client_id",
			"client_secret",
			"webhook_secret",
			"oauth_callback_url",
			"integration_status",
		},
	}
}

func (contract ParasutCredentialUIScreenContract) CanRoleAccess(role CredentialEntryRole) bool {
	for _, allowed := range contract.AllowedRoles {
		if allowed == role {
			return true
		}
	}
	return false
}

func ValidateParasutCredentialUIScreenContract(contract ParasutCredentialUIScreenContract) error {
	if err := requireNonEmpty(contract.PanelPath, "panel_path"); err != nil {
		return err
	}
	if err := requireNonEmpty(contract.IntegrationCard, "integration_card"); err != nil {
		return err
	}
	if !strings.Contains(contract.PanelPath, "Ayarlar") || !strings.Contains(contract.PanelPath, "Paraşüt") {
		return fmt.Errorf("%w: panel path must point to Paraşüt integration settings", ErrInvalidIntegrationRequest)
	}
	if len(contract.AllowedRoles) == 0 {
		return fmt.Errorf("%w: allowed roles required", ErrInvalidIntegrationRequest)
	}
	if len(contract.Actions) == 0 {
		return fmt.Errorf("%w: ui actions required", ErrInvalidIntegrationRequest)
	}
	if len(contract.Fields) == 0 {
		return fmt.Errorf("%w: ui fields required", ErrInvalidIntegrationRequest)
	}
	if !contract.SecretFieldsMasked {
		return fmt.Errorf("%w: secret fields must be masked", ErrInvalidIntegrationRequest)
	}
	if contract.ClientSecretPlaintextPersisted {
		return fmt.Errorf("%w: client secret plaintext persistence is forbidden", ErrInvalidIntegrationRequest)
	}
	if contract.WebhookSecretPlaintextPersisted {
		return fmt.Errorf("%w: webhook secret plaintext persistence is forbidden", ErrInvalidIntegrationRequest)
	}
	return nil
}

type ParasutCredentialUIRequest struct {
	TenantID                 string
	AppKey                   string
	Role                     CredentialEntryRole
	Action                   ParasutCredentialUIAction
	ClientID                 string
	ClientSecretPlaintext    string
	WebhookSecretPlaintext   string
	ClientSecretRef          string
	WebhookSecretRef         string
	RequestedBy              string
	CorrelationID            string
	RealAPIEnabled           bool
	ProviderLiveModuleOpened bool
	Now                      time.Time
}

type ParasutCredentialUIResult struct {
	TenantID           string
	ProviderKey        string
	AppKey             string
	Action             ParasutCredentialUIAction
	Status             ParasutCredentialUIStatus
	ClientID           string
	ClientSecretRef    string
	WebhookSecretRef   string
	DisplayFields      map[string]string
	Message            string
	PlaintextPersisted bool
	AuditDecision      AuditDecision
	CorrelationID      string
	CreatedAt          time.Time
}

func HandleParasutCredentialUIAction(
	contract ParasutCredentialUIScreenContract,
	vault *InMemoryParasutCredentialVault,
	req ParasutCredentialUIRequest,
) (ParasutCredentialUIResult, error) {
	if err := ValidateParasutCredentialUIScreenContract(contract); err != nil {
		return ParasutCredentialUIResult{AuditDecision: AuditDecisionDenied}, err
	}
	if err := validateParasutCredentialUIRequest(contract, req); err != nil {
		return ParasutCredentialUIResult{AuditDecision: AuditDecisionDenied}, err
	}

	now := req.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}

	switch req.Action {
	case ParasutCredentialUIActionSaveCredentials:
		return saveParasutCredentials(vault, req, now)
	case ParasutCredentialUIActionDryRunTestConnection:
		return dryRunParasutConnectionTest(req, now)
	case ParasutCredentialUIActionDisableIntegration:
		return disableParasutIntegration(req, now)
	case ParasutCredentialUIActionRotateClientSecret:
		return rotateParasutSecret(vault, req, ParasutSecretKindClientSecret, now)
	case ParasutCredentialUIActionRotateWebhookSecret:
		return rotateParasutSecret(vault, req, ParasutSecretKindWebhookSecret, now)
	default:
		return ParasutCredentialUIResult{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: unsupported parasut credential ui action", ErrInvalidIntegrationRequest)
	}
}

func saveParasutCredentials(vault *InMemoryParasutCredentialVault, req ParasutCredentialUIRequest, now time.Time) (ParasutCredentialUIResult, error) {
	if vault == nil {
		return ParasutCredentialUIResult{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: credential vault required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.ClientID, "client_id"); err != nil {
		return ParasutCredentialUIResult{AuditDecision: AuditDecisionDenied}, err
	}
	if err := requireNonEmpty(req.ClientSecretPlaintext, "client_secret"); err != nil {
		return ParasutCredentialUIResult{AuditDecision: AuditDecisionDenied}, err
	}
	if err := requireNonEmpty(req.WebhookSecretPlaintext, "webhook_secret"); err != nil {
		return ParasutCredentialUIResult{AuditDecision: AuditDecisionDenied}, err
	}

	clientRef, err := vault.StoreSecret(ParasutStoreSecretRequest{
		TenantID:      req.TenantID,
		AppKey:        req.AppKey,
		SecretKind:    ParasutSecretKindClientSecret,
		RawSecret:     req.ClientSecretPlaintext,
		CreatedBy:     req.RequestedBy,
		CorrelationID: req.CorrelationID,
		Now:           now,
	})
	if err != nil {
		return ParasutCredentialUIResult{AuditDecision: AuditDecisionDenied}, err
	}

	webhookRef, err := vault.StoreSecret(ParasutStoreSecretRequest{
		TenantID:      req.TenantID,
		AppKey:        req.AppKey,
		SecretKind:    ParasutSecretKindWebhookSecret,
		RawSecret:     req.WebhookSecretPlaintext,
		CreatedBy:     req.RequestedBy,
		CorrelationID: req.CorrelationID,
		Now:           now,
	})
	if err != nil {
		return ParasutCredentialUIResult{AuditDecision: AuditDecisionDenied}, err
	}

	credentialSet, err := BuildParasutCredentialSet(BuildParasutCredentialSetRequest{
		TenantID:         req.TenantID,
		AppKey:           req.AppKey,
		ClientID:         req.ClientID,
		ClientSecretRef:  clientRef.SecretRef,
		WebhookSecretRef: webhookRef.SecretRef,
		CreatedBy:        req.RequestedBy,
		CorrelationID:    req.CorrelationID,
		Now:              now,
	})
	if err != nil {
		return ParasutCredentialUIResult{AuditDecision: AuditDecisionDenied}, err
	}

	return ParasutCredentialUIResult{
		TenantID:           credentialSet.TenantID,
		ProviderKey:        ParasutProviderKey,
		AppKey:             credentialSet.AppKey,
		Action:             req.Action,
		Status:             ParasutCredentialUIStatusSaved,
		ClientID:           credentialSet.ClientID,
		ClientSecretRef:    credentialSet.ClientSecretRef,
		WebhookSecretRef:   credentialSet.WebhookSecretRef,
		DisplayFields:      buildParasutCredentialUIDisplayFields(credentialSet.ClientID, credentialSet.ClientSecretRef, credentialSet.WebhookSecretRef),
		Message:            "Paraşüt credential bilgileri secret_ref olarak kaydedildi; gerçek API kapalı.",
		PlaintextPersisted: false,
		AuditDecision:      AuditDecisionAllowed,
		CorrelationID:      req.CorrelationID,
		CreatedAt:          now,
	}, nil
}

func dryRunParasutConnectionTest(req ParasutCredentialUIRequest, now time.Time) (ParasutCredentialUIResult, error) {
	if err := requireNonEmpty(req.ClientSecretRef, "client_secret_ref"); err != nil {
		return ParasutCredentialUIResult{AuditDecision: AuditDecisionDenied}, err
	}
	if err := requireNonEmpty(req.WebhookSecretRef, "webhook_secret_ref"); err != nil {
		return ParasutCredentialUIResult{AuditDecision: AuditDecisionDenied}, err
	}
	if !isParasutSecretRefForTenant(req.TenantID, req.ClientSecretRef) {
		return ParasutCredentialUIResult{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: client_secret_ref must be tenant-safe parasut ref", ErrInvalidIntegrationRequest)
	}
	if !isParasutSecretRefForTenant(req.TenantID, req.WebhookSecretRef) {
		return ParasutCredentialUIResult{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: webhook_secret_ref must be tenant-safe parasut ref", ErrInvalidIntegrationRequest)
	}

	status := ParasutCredentialUIStatusDryRunOK
	message := "Paraşüt bağlantı dry-run kontrolü geçti; canlı API çağrısı yapılmadı."

	if !req.RealAPIEnabled || !req.ProviderLiveModuleOpened {
		status = ParasutCredentialUIStatusBlockedRealAPIClosed
		message = "Paraşüt canlı bağlantı testi kapalı; provider live module ve real API approval gerekir."
	}

	return ParasutCredentialUIResult{
		TenantID:           normalize(req.TenantID),
		ProviderKey:        ParasutProviderKey,
		AppKey:             normalize(req.AppKey),
		Action:             req.Action,
		Status:             status,
		ClientID:           normalize(req.ClientID),
		ClientSecretRef:    normalize(req.ClientSecretRef),
		WebhookSecretRef:   normalize(req.WebhookSecretRef),
		DisplayFields:      buildParasutCredentialUIDisplayFields(req.ClientID, req.ClientSecretRef, req.WebhookSecretRef),
		Message:            message,
		PlaintextPersisted: false,
		AuditDecision:      AuditDecisionAllowed,
		CorrelationID:      normalize(req.CorrelationID),
		CreatedAt:          now,
	}, nil
}

func disableParasutIntegration(req ParasutCredentialUIRequest, now time.Time) (ParasutCredentialUIResult, error) {
	return ParasutCredentialUIResult{
		TenantID:           normalize(req.TenantID),
		ProviderKey:        ParasutProviderKey,
		AppKey:             normalize(req.AppKey),
		Action:             req.Action,
		Status:             ParasutCredentialUIStatusDisabled,
		ClientID:           normalize(req.ClientID),
		ClientSecretRef:    normalize(req.ClientSecretRef),
		WebhookSecretRef:   normalize(req.WebhookSecretRef),
		DisplayFields:      buildParasutCredentialUIDisplayFields(req.ClientID, req.ClientSecretRef, req.WebhookSecretRef),
		Message:            "Paraşüt entegrasyonu tenant için devre dışı bırakıldı.",
		PlaintextPersisted: false,
		AuditDecision:      AuditDecisionAllowed,
		CorrelationID:      normalize(req.CorrelationID),
		CreatedAt:          now,
	}, nil
}

func rotateParasutSecret(vault *InMemoryParasutCredentialVault, req ParasutCredentialUIRequest, kind ParasutSecretKind, now time.Time) (ParasutCredentialUIResult, error) {
	if vault == nil {
		return ParasutCredentialUIResult{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: credential vault required", ErrInvalidIntegrationRequest)
	}

	oldRef := req.ClientSecretRef
	newSecret := req.ClientSecretPlaintext
	if kind == ParasutSecretKindWebhookSecret {
		oldRef = req.WebhookSecretRef
		newSecret = req.WebhookSecretPlaintext
	}

	rotated, err := vault.RotateSecret(ParasutRotateSecretRequest{
		TenantID:      req.TenantID,
		AppKey:        req.AppKey,
		SecretKind:    kind,
		OldSecretRef:  oldRef,
		NewRawSecret:  newSecret,
		RotatedBy:     req.RequestedBy,
		CorrelationID: req.CorrelationID,
		Now:           now,
	})
	if err != nil {
		return ParasutCredentialUIResult{AuditDecision: AuditDecisionDenied}, err
	}

	clientSecretRef := req.ClientSecretRef
	webhookSecretRef := req.WebhookSecretRef

	if kind == ParasutSecretKindClientSecret {
		clientSecretRef = rotated.SecretRef
	}
	if kind == ParasutSecretKindWebhookSecret {
		webhookSecretRef = rotated.SecretRef
	}

	return ParasutCredentialUIResult{
		TenantID:           normalize(req.TenantID),
		ProviderKey:        ParasutProviderKey,
		AppKey:             normalize(req.AppKey),
		Action:             req.Action,
		Status:             ParasutCredentialUIStatusRotated,
		ClientID:           normalize(req.ClientID),
		ClientSecretRef:    normalize(clientSecretRef),
		WebhookSecretRef:   normalize(webhookSecretRef),
		DisplayFields:      buildParasutCredentialUIDisplayFields(req.ClientID, clientSecretRef, webhookSecretRef),
		Message:            "Paraşüt secret rotate edildi; yeni secret_ref aktif.",
		PlaintextPersisted: false,
		AuditDecision:      AuditDecisionAllowed,
		CorrelationID:      normalize(req.CorrelationID),
		CreatedAt:          now,
	}, nil
}

func validateParasutCredentialUIRequest(contract ParasutCredentialUIScreenContract, req ParasutCredentialUIRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.AppKey, "app_key"); err != nil {
		return err
	}
	if req.Role == "" {
		return fmt.Errorf("%w: credential ui role required", ErrInvalidIntegrationRequest)
	}
	if !contract.CanRoleAccess(req.Role) {
		return fmt.Errorf("%w: credential ui role not allowed", ErrInvalidIntegrationRequest)
	}
	if req.Action == "" {
		return fmt.Errorf("%w: credential ui action required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.RequestedBy, "requested_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if req.RealAPIEnabled && !req.ProviderLiveModuleOpened {
		return fmt.Errorf("%w: real api cannot be enabled before provider live module", ErrInvalidIntegrationRequest)
	}
	return nil
}

func buildParasutCredentialUIDisplayFields(clientID string, clientSecretRef string, webhookSecretRef string) map[string]string {
	return map[string]string{
		"client_id":        normalize(clientID),
		"client_secret":    maskParasutSecretRef(clientSecretRef),
		"webhook_secret":   maskParasutSecretRef(webhookSecretRef),
		"provider_key":     ParasutProviderKey,
		"real_api_status":  "CLOSED",
		"credential_store": "SECRET_REF_ONLY",
	}
}

func maskParasutSecretRef(secretRef string) string {
	if normalize(secretRef) == "" {
		return ""
	}
	parts := strings.Split(secretRef, "/")
	if len(parts) == 0 {
		return "****"
	}
	last := parts[len(parts)-1]
	return "****/" + last
}

type ParasutCredentialUIReadinessGateInput struct {
	AdminSurfaceReady            bool
	CredentialFormReady          bool
	SaveActionReady              bool
	DryRunTestActionReady        bool
	DisableActionReady           bool
	RotateActionReady            bool
	RoleGuardReady               bool
	SecretMaskingReady           bool
	TestsReady                   bool
	RealImplementationAuditReady bool
	RealAPIEnabled               bool
}

type ParasutCredentialUIReadinessGateResult struct {
	Ready    bool
	Decision string
	Blockers []string
}

func EvaluateParasutCredentialUIReadinessGate(input ParasutCredentialUIReadinessGateInput) ParasutCredentialUIReadinessGateResult {
	blockers := []string{}

	if !input.AdminSurfaceReady {
		blockers = append(blockers, "admin_surface_not_ready")
	}
	if !input.CredentialFormReady {
		blockers = append(blockers, "credential_form_not_ready")
	}
	if !input.SaveActionReady {
		blockers = append(blockers, "save_action_not_ready")
	}
	if !input.DryRunTestActionReady {
		blockers = append(blockers, "dry_run_test_action_not_ready")
	}
	if !input.DisableActionReady {
		blockers = append(blockers, "disable_action_not_ready")
	}
	if !input.RotateActionReady {
		blockers = append(blockers, "rotate_action_not_ready")
	}
	if !input.RoleGuardReady {
		blockers = append(blockers, "role_guard_not_ready")
	}
	if !input.SecretMaskingReady {
		blockers = append(blockers, "secret_masking_not_ready")
	}
	if !input.TestsReady {
		blockers = append(blockers, "tests_not_ready")
	}
	if !input.RealImplementationAuditReady {
		blockers = append(blockers, "real_implementation_audit_not_ready")
	}
	if input.RealAPIEnabled {
		blockers = append(blockers, "real_api_enabled_must_remain_false_in_credential_ui_phase")
	}

	if len(blockers) > 0 {
		return ParasutCredentialUIReadinessGateResult{
			Ready:    false,
			Decision: "BLOCKED",
			Blockers: blockers,
		}
	}

	return ParasutCredentialUIReadinessGateResult{
		Ready:    true,
		Decision: "PARASUT_CREDENTIAL_UI_READY_WITH_REAL_API_CLOSED",
		Blockers: []string{},
	}
}
