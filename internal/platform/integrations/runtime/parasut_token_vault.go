package integrationruntime

import (
	"fmt"
	"strings"
	"sync"
	"time"
)

type CredentialEntryRole string

const (
	CredentialEntryRoleTenantAdmin      CredentialEntryRole = "TENANT_ADMIN"
	CredentialEntryRoleIntegrationAdmin CredentialEntryRole = "INTEGRATION_ADMIN"
)

type ParasutCredentialEntrySurface struct {
	PanelPath                     string
	AllowedRoles                  []CredentialEntryRole
	MFARecommended                bool
	SecretPlaintextNeverPersisted bool
	Fields                        []string
}

func DefaultParasutCredentialEntrySurface() ParasutCredentialEntrySurface {
	return ParasutCredentialEntrySurface{
		PanelPath: "Panel > Ayarlar > Entegrasyonlar > Paraşüt > Bağlan / API Bilgileri",
		AllowedRoles: []CredentialEntryRole{
			CredentialEntryRoleTenantAdmin,
			CredentialEntryRoleIntegrationAdmin,
		},
		MFARecommended:                true,
		SecretPlaintextNeverPersisted: true,
		Fields: []string{
			"client_id",
			"client_secret",
			"webhook_secret",
			"oauth_connect",
			"connection_test",
			"rotate_secret",
			"disable_integration",
		},
	}
}

func (surface ParasutCredentialEntrySurface) CanRoleManage(role CredentialEntryRole) bool {
	for _, allowed := range surface.AllowedRoles {
		if allowed == role {
			return true
		}
	}
	return false
}

type ParasutSecretKind string

const (
	ParasutSecretKindClientSecret  ParasutSecretKind = "CLIENT_SECRET"
	ParasutSecretKindWebhookSecret ParasutSecretKind = "WEBHOOK_SECRET"
	ParasutSecretKindAccessToken   ParasutSecretKind = "ACCESS_TOKEN"
	ParasutSecretKindRefreshToken  ParasutSecretKind = "REFRESH_TOKEN"
)

type ParasutCredentialStatus string

const (
	ParasutCredentialStatusActive  ParasutCredentialStatus = "ACTIVE"
	ParasutCredentialStatusRotated ParasutCredentialStatus = "ROTATED"
	ParasutCredentialStatusRevoked ParasutCredentialStatus = "REVOKED"
	ParasutCredentialStatusExpired ParasutCredentialStatus = "EXPIRED"
)

type ParasutSecretReference struct {
	TenantID      string
	ProviderKey   string
	AppKey        string
	SecretKind    ParasutSecretKind
	SecretRef     string
	Version       int
	Status        ParasutCredentialStatus
	CreatedBy     string
	CorrelationID string
	CreatedAt     time.Time
	RotatedAt     time.Time
	RevokedAt     time.Time
	AuditDecision AuditDecision
}

type ParasutStoreSecretRequest struct {
	TenantID      string
	AppKey        string
	SecretKind    ParasutSecretKind
	RawSecret     string
	CreatedBy     string
	CorrelationID string
	Now           time.Time
}

type ParasutRotateSecretRequest struct {
	TenantID      string
	AppKey        string
	SecretKind    ParasutSecretKind
	OldSecretRef  string
	NewRawSecret  string
	RotatedBy     string
	CorrelationID string
	Now           time.Time
}

type ParasutRevokeSecretRequest struct {
	TenantID      string
	SecretRef     string
	RevokedBy     string
	CorrelationID string
	Now           time.Time
}

type ParasutResolveSecretRequest struct {
	TenantID                 string
	SecretRef                string
	Purpose                  string
	ProviderLiveModuleOpened bool
	RealAPIEnabled           bool
	CorrelationID            string
}

type parasutVaultRecord struct {
	Reference ParasutSecretReference
	RawSecret string
}

type InMemoryParasutCredentialVault struct {
	mu      sync.RWMutex
	records map[string]parasutVaultRecord
	latest  map[string]string
}

func NewInMemoryParasutCredentialVault() *InMemoryParasutCredentialVault {
	return &InMemoryParasutCredentialVault{
		records: map[string]parasutVaultRecord{},
		latest:  map[string]string{},
	}
}

func (vault *InMemoryParasutCredentialVault) StoreSecret(req ParasutStoreSecretRequest) (ParasutSecretReference, error) {
	if err := validateParasutStoreSecretRequest(req); err != nil {
		return ParasutSecretReference{AuditDecision: AuditDecisionDenied}, err
	}

	now := req.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}

	vault.mu.Lock()
	defer vault.mu.Unlock()

	key := vault.latestKey(req.TenantID, req.AppKey, req.SecretKind)
	version := 1
	if latestRef, ok := vault.latest[key]; ok {
		if latest, exists := vault.records[latestRef]; exists {
			version = latest.Reference.Version + 1
		}
	}

	ref := buildParasutSecretRef(req.TenantID, req.SecretKind, version)

	reference := ParasutSecretReference{
		TenantID:      normalize(req.TenantID),
		ProviderKey:   ParasutProviderKey,
		AppKey:        normalize(req.AppKey),
		SecretKind:    req.SecretKind,
		SecretRef:     ref,
		Version:       version,
		Status:        ParasutCredentialStatusActive,
		CreatedBy:     normalize(req.CreatedBy),
		CorrelationID: normalize(req.CorrelationID),
		CreatedAt:     now,
		AuditDecision: AuditDecisionAllowed,
	}

	vault.records[ref] = parasutVaultRecord{
		Reference: reference,
		RawSecret: req.RawSecret,
	}
	vault.latest[key] = ref

	return reference, nil
}

func (vault *InMemoryParasutCredentialVault) RotateSecret(req ParasutRotateSecretRequest) (ParasutSecretReference, error) {
	if err := validateParasutRotateSecretRequest(req); err != nil {
		return ParasutSecretReference{AuditDecision: AuditDecisionDenied}, err
	}

	now := req.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}

	vault.mu.Lock()
	oldRecord, exists := vault.records[normalize(req.OldSecretRef)]
	if !exists {
		vault.mu.Unlock()
		return ParasutSecretReference{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: old secret reference not found", ErrInvalidIntegrationRequest)
	}
	if oldRecord.Reference.TenantID != normalize(req.TenantID) {
		vault.mu.Unlock()
		return ParasutSecretReference{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: tenant mismatch for secret rotation", ErrInvalidIntegrationRequest)
	}
	if oldRecord.Reference.SecretKind != req.SecretKind {
		vault.mu.Unlock()
		return ParasutSecretReference{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: secret kind mismatch for rotation", ErrInvalidIntegrationRequest)
	}

	oldRecord.Reference.Status = ParasutCredentialStatusRotated
	oldRecord.Reference.RotatedAt = now
	vault.records[oldRecord.Reference.SecretRef] = oldRecord

	version := oldRecord.Reference.Version + 1
	ref := buildParasutSecretRef(req.TenantID, req.SecretKind, version)

	newReference := ParasutSecretReference{
		TenantID:      normalize(req.TenantID),
		ProviderKey:   ParasutProviderKey,
		AppKey:        normalize(req.AppKey),
		SecretKind:    req.SecretKind,
		SecretRef:     ref,
		Version:       version,
		Status:        ParasutCredentialStatusActive,
		CreatedBy:     normalize(req.RotatedBy),
		CorrelationID: normalize(req.CorrelationID),
		CreatedAt:     now,
		AuditDecision: AuditDecisionAllowed,
	}

	vault.records[ref] = parasutVaultRecord{
		Reference: newReference,
		RawSecret: req.NewRawSecret,
	}
	vault.latest[vault.latestKey(req.TenantID, req.AppKey, req.SecretKind)] = ref
	vault.mu.Unlock()

	return newReference, nil
}

func (vault *InMemoryParasutCredentialVault) RevokeSecret(req ParasutRevokeSecretRequest) (ParasutSecretReference, error) {
	if err := validateParasutRevokeSecretRequest(req); err != nil {
		return ParasutSecretReference{AuditDecision: AuditDecisionDenied}, err
	}

	now := req.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}

	vault.mu.Lock()
	defer vault.mu.Unlock()

	record, exists := vault.records[normalize(req.SecretRef)]
	if !exists {
		return ParasutSecretReference{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: secret reference not found", ErrInvalidIntegrationRequest)
	}
	if record.Reference.TenantID != normalize(req.TenantID) {
		return ParasutSecretReference{AuditDecision: AuditDecisionDenied}, fmt.Errorf("%w: tenant mismatch for secret revoke", ErrInvalidIntegrationRequest)
	}

	record.Reference.Status = ParasutCredentialStatusRevoked
	record.Reference.RevokedAt = now
	record.Reference.CorrelationID = normalize(req.CorrelationID)
	vault.records[record.Reference.SecretRef] = record

	return record.Reference, nil
}

func (vault *InMemoryParasutCredentialVault) FindSecretReference(tenantID string, secretRef string) (ParasutSecretReference, error) {
	if err := requireNonEmpty(tenantID, "tenant_id"); err != nil {
		return ParasutSecretReference{}, err
	}
	if err := requireNonEmpty(secretRef, "secret_ref"); err != nil {
		return ParasutSecretReference{}, err
	}

	vault.mu.RLock()
	defer vault.mu.RUnlock()

	record, exists := vault.records[normalize(secretRef)]
	if !exists {
		return ParasutSecretReference{}, fmt.Errorf("%w: secret reference not found", ErrInvalidIntegrationRequest)
	}
	if record.Reference.TenantID != normalize(tenantID) {
		return ParasutSecretReference{}, fmt.Errorf("%w: tenant mismatch for secret lookup", ErrInvalidIntegrationRequest)
	}

	return record.Reference, nil
}

func (vault *InMemoryParasutCredentialVault) ResolveRawSecret(req ParasutResolveSecretRequest) (string, error) {
	if err := validateParasutResolveSecretRequest(req); err != nil {
		return "", err
	}
	if !req.ProviderLiveModuleOpened || !req.RealAPIEnabled {
		return "", fmt.Errorf("%w: raw secret resolve blocked until provider live module and real api approval", ErrInvalidIntegrationRequest)
	}

	vault.mu.RLock()
	defer vault.mu.RUnlock()

	record, exists := vault.records[normalize(req.SecretRef)]
	if !exists {
		return "", fmt.Errorf("%w: secret reference not found", ErrInvalidIntegrationRequest)
	}
	if record.Reference.TenantID != normalize(req.TenantID) {
		return "", fmt.Errorf("%w: tenant mismatch for secret resolve", ErrInvalidIntegrationRequest)
	}
	if record.Reference.Status != ParasutCredentialStatusActive {
		return "", fmt.Errorf("%w: secret reference is not active", ErrInvalidIntegrationRequest)
	}

	return record.RawSecret, nil
}

func (vault *InMemoryParasutCredentialVault) latestKey(tenantID string, appKey string, kind ParasutSecretKind) string {
	return fmt.Sprintf("%s:%s:%s:%s", normalize(tenantID), ParasutProviderKey, normalize(appKey), kind)
}

func buildParasutSecretRef(tenantID string, kind ParasutSecretKind, version int) string {
	return fmt.Sprintf("secret://pix2pi/%s/%s/%s/v%d", normalize(tenantID), ParasutProviderKey, strings.ToLower(string(kind)), version)
}

func validateParasutStoreSecretRequest(req ParasutStoreSecretRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.AppKey, "app_key"); err != nil {
		return err
	}
	if req.SecretKind == "" {
		return fmt.Errorf("%w: secret_kind required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.RawSecret, "raw_secret"); err != nil {
		return err
	}
	if len(req.RawSecret) < 8 {
		return fmt.Errorf("%w: raw_secret too short", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.CreatedBy, "created_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	return validateParasutSecretKind(req.SecretKind)
}

func validateParasutRotateSecretRequest(req ParasutRotateSecretRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.AppKey, "app_key"); err != nil {
		return err
	}
	if req.SecretKind == "" {
		return fmt.Errorf("%w: secret_kind required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.OldSecretRef, "old_secret_ref"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.NewRawSecret, "new_raw_secret"); err != nil {
		return err
	}
	if len(req.NewRawSecret) < 8 {
		return fmt.Errorf("%w: new_raw_secret too short", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(req.RotatedBy, "rotated_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	return validateParasutSecretKind(req.SecretKind)
}

func validateParasutRevokeSecretRequest(req ParasutRevokeSecretRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.SecretRef, "secret_ref"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.RevokedBy, "revoked_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	return nil
}

func validateParasutResolveSecretRequest(req ParasutResolveSecretRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.SecretRef, "secret_ref"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.Purpose, "purpose"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	return nil
}

func validateParasutSecretKind(kind ParasutSecretKind) error {
	switch kind {
	case ParasutSecretKindClientSecret,
		ParasutSecretKindWebhookSecret,
		ParasutSecretKindAccessToken,
		ParasutSecretKindRefreshToken:
		return nil
	default:
		return fmt.Errorf("%w: unsupported parasut secret kind", ErrInvalidIntegrationRequest)
	}
}

type ParasutCredentialSet struct {
	TenantID         string
	ProviderKey      string
	AppKey           string
	ClientID         string
	ClientSecretRef  string
	WebhookSecretRef string
	AccessTokenRef   string
	RefreshTokenRef  string
	Status           ParasutCredentialStatus
	CreatedBy        string
	CorrelationID    string
	CreatedAt        time.Time
}

type BuildParasutCredentialSetRequest struct {
	TenantID         string
	AppKey           string
	ClientID         string
	ClientSecretRef  string
	WebhookSecretRef string
	AccessTokenRef   string
	RefreshTokenRef  string
	CreatedBy        string
	CorrelationID    string
	Now              time.Time
}

func BuildParasutCredentialSet(req BuildParasutCredentialSetRequest) (ParasutCredentialSet, error) {
	if err := validateParasutCredentialSetRequest(req); err != nil {
		return ParasutCredentialSet{}, err
	}

	now := req.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}

	return ParasutCredentialSet{
		TenantID:         normalize(req.TenantID),
		ProviderKey:      ParasutProviderKey,
		AppKey:           normalize(req.AppKey),
		ClientID:         normalize(req.ClientID),
		ClientSecretRef:  normalize(req.ClientSecretRef),
		WebhookSecretRef: normalize(req.WebhookSecretRef),
		AccessTokenRef:   normalize(req.AccessTokenRef),
		RefreshTokenRef:  normalize(req.RefreshTokenRef),
		Status:           ParasutCredentialStatusActive,
		CreatedBy:        normalize(req.CreatedBy),
		CorrelationID:    normalize(req.CorrelationID),
		CreatedAt:        now,
	}, nil
}

func validateParasutCredentialSetRequest(req BuildParasutCredentialSetRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.ClientID, "client_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.ClientSecretRef, "client_secret_ref"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.WebhookSecretRef, "webhook_secret_ref"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CreatedBy, "created_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if !isParasutSecretRefForTenant(req.TenantID, req.ClientSecretRef) {
		return fmt.Errorf("%w: client_secret_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	if !isParasutSecretRefForTenant(req.TenantID, req.WebhookSecretRef) {
		return fmt.Errorf("%w: webhook_secret_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	if normalize(req.AccessTokenRef) != "" && !isParasutSecretRefForTenant(req.TenantID, req.AccessTokenRef) {
		return fmt.Errorf("%w: access_token_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	if normalize(req.RefreshTokenRef) != "" && !isParasutSecretRefForTenant(req.TenantID, req.RefreshTokenRef) {
		return fmt.Errorf("%w: refresh_token_ref must be tenant-safe parasut secret reference", ErrInvalidIntegrationRequest)
	}
	return nil
}

func isParasutSecretRefForTenant(tenantID string, secretRef string) bool {
	expectedPrefix := fmt.Sprintf("secret://pix2pi/%s/%s/", normalize(tenantID), ParasutProviderKey)
	return strings.HasPrefix(normalize(secretRef), expectedPrefix)
}

type ParasutTokenVaultReadinessGateInput struct {
	CredentialEntrySurfaceReady  bool
	SecretReferenceModelReady    bool
	VaultContractReady           bool
	CredentialStorageReady       bool
	RotationReady                bool
	RevocationReady              bool
	TestsReady                   bool
	RealImplementationAuditReady bool
	RealAPIEnabled               bool
}

type ParasutTokenVaultReadinessGateResult struct {
	Ready    bool
	Decision string
	Blockers []string
}

func EvaluateParasutTokenVaultReadinessGate(input ParasutTokenVaultReadinessGateInput) ParasutTokenVaultReadinessGateResult {
	blockers := []string{}

	if !input.CredentialEntrySurfaceReady {
		blockers = append(blockers, "credential_entry_surface_not_ready")
	}
	if !input.SecretReferenceModelReady {
		blockers = append(blockers, "secret_reference_model_not_ready")
	}
	if !input.VaultContractReady {
		blockers = append(blockers, "vault_contract_not_ready")
	}
	if !input.CredentialStorageReady {
		blockers = append(blockers, "credential_storage_not_ready")
	}
	if !input.RotationReady {
		blockers = append(blockers, "rotation_not_ready")
	}
	if !input.RevocationReady {
		blockers = append(blockers, "revocation_not_ready")
	}
	if !input.TestsReady {
		blockers = append(blockers, "tests_not_ready")
	}
	if !input.RealImplementationAuditReady {
		blockers = append(blockers, "real_implementation_audit_not_ready")
	}
	if input.RealAPIEnabled {
		blockers = append(blockers, "real_api_enabled_must_remain_false_in_token_vault_phase")
	}

	if len(blockers) > 0 {
		return ParasutTokenVaultReadinessGateResult{
			Ready:    false,
			Decision: "BLOCKED",
			Blockers: blockers,
		}
	}

	return ParasutTokenVaultReadinessGateResult{
		Ready:    true,
		Decision: "PARASUT_TOKEN_VAULT_READY_WITH_REAL_API_CLOSED",
		Blockers: []string{},
	}
}
