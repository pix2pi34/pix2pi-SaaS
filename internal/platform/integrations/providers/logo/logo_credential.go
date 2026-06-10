package logo

import (
	"errors"
	"fmt"
	"strings"
)

const (
	StepFAZ78L3 = "FAZ_7_8L.3"

	LogoCredentialMode          = "SECRET_REFERENCE_ONLY"
	LogoCredentialProfileStatus = "DECLARED_SECRET_REFERENCE_ONLY"
	LogoSecretReferenceStatus   = "REFERENCE_ONLY"
	LogoRealSecretValueStatus   = "FORBIDDEN_IN_CODE_CONFIG_DOCS"
)

type LogoCredentialOperationName string

const (
	LogoOperationDeclareCredentialProfile         LogoCredentialOperationName = "DECLARE_LOGO_CREDENTIAL_PROFILE"
	LogoOperationDeclareSecretReference           LogoCredentialOperationName = "DECLARE_LOGO_SECRET_REFERENCE"
	LogoOperationValidateNoRawSecret              LogoCredentialOperationName = "VALIDATE_LOGO_NO_RAW_SECRET"
	LogoOperationValidateTenantCredentialBoundary LogoCredentialOperationName = "VALIDATE_LOGO_TENANT_CREDENTIAL_BOUNDARY"
	LogoOperationPrepareCredentialRotationPolicy  LogoCredentialOperationName = "PREPARE_LOGO_CREDENTIAL_ROTATION_POLICY"
	LogoOperationPrepareCredentialAuditPolicy     LogoCredentialOperationName = "PREPARE_LOGO_CREDENTIAL_AUDIT_POLICY"
	LogoOperationPrepareLiveSecretHandoff         LogoCredentialOperationName = "PREPARE_LOGO_PROVIDER_LIVE_SECRET_HANDOFF"
)

type LogoCredentialProfile struct {
	Declared                    bool   `json:"declared"`
	Status                      string `json:"status"`
	TenantScopeRequired         bool   `json:"tenant_scope_required"`
	EnvironmentScopeRequired    bool   `json:"environment_scope_required"`
	CredentialProfileIDRequired bool   `json:"credential_profile_id_required"`
	SecretReferenceRequired     bool   `json:"secret_reference_required"`
	VaultPathReferenceRequired  bool   `json:"vault_path_reference_required"`
	RotationPolicyRequired      bool   `json:"rotation_policy_required"`
	AuditPolicyRequired         bool   `json:"audit_policy_required"`
	RawSecretAllowed            bool   `json:"raw_secret_allowed"`
	LiveUsageAllowed            bool   `json:"live_usage_allowed"`
}

type LogoSecretReferenceContract struct {
	Declared                    bool     `json:"declared"`
	Status                      string   `json:"status"`
	AllowedReferenceFields      []string `json:"allowed_reference_fields"`
	ForbiddenRawSecretFields    []string `json:"forbidden_raw_secret_fields"`
	SecretValuesInConfigAllowed bool     `json:"secret_values_in_config_allowed"`
	SecretValuesInCodeAllowed   bool     `json:"secret_values_in_code_allowed"`
	SecretValuesInDocsAllowed   bool     `json:"secret_values_in_docs_allowed"`
}

type LogoCredentialRotationPolicy struct {
	Declared                  bool `json:"declared"`
	RotationRequired          bool `json:"rotation_required"`
	RevocationRequired        bool `json:"revocation_required"`
	BreakGlassRequired        bool `json:"break_glass_required"`
	LiveRotationAllowedInStep bool `json:"live_rotation_allowed_in_this_step"`
}

type LogoCredentialAuditPolicy struct {
	Declared                    bool `json:"declared"`
	TenantIDRequired            bool `json:"tenant_id_required"`
	CredentialProfileIDRequired bool `json:"credential_profile_id_required"`
	CorrelationIDRequired       bool `json:"correlation_id_required"`
	SecretValueLoggingAllowed   bool `json:"secret_value_logging_allowed"`
}

type LogoCredentialOperationContract struct {
	Name                LogoCredentialOperationName `json:"name"`
	Mode                string                      `json:"mode"`
	ExternalCallAllowed bool                        `json:"external_call_allowed"`
	FileDeliveryAllowed bool                        `json:"file_delivery_allowed"`
	ERPWriteAllowed     bool                        `json:"erp_write_allowed"`
	RawSecretAllowed    bool                        `json:"raw_secret_allowed"`
}

type LogoCredentialContract struct {
	Module                 string                            `json:"module"`
	Step                   string                            `json:"step"`
	ProviderCode           string                            `json:"provider_code"`
	ProviderName           string                            `json:"provider_name"`
	ConnectorCode          string                            `json:"connector_code"`
	ConnectorFamily        string                            `json:"connector_family"`
	RuntimeMode            string                            `json:"runtime_mode"`
	CredentialMode         string                            `json:"credential_mode"`
	RealProviderAPIStatus  string                            `json:"real_provider_api_status"`
	RealFileDeliveryStatus string                            `json:"real_file_delivery_status"`
	RealERPWriteStatus     string                            `json:"real_erp_write_status"`
	RealSecretValueStatus  string                            `json:"real_secret_value_status"`
	CredentialProfile      LogoCredentialProfile             `json:"credential_profile"`
	SecretReference        LogoSecretReferenceContract       `json:"secret_reference_contract"`
	RotationPolicy         LogoCredentialRotationPolicy      `json:"rotation_policy"`
	AuditPolicy            LogoCredentialAuditPolicy         `json:"audit_policy"`
	Operations             []LogoCredentialOperationContract `json:"operations"`
}

type LogoCredentialReference struct {
	TenantID            string `json:"tenant_id"`
	Environment         string `json:"environment"`
	CredentialProfileID string `json:"credential_profile_id"`
	SecretRef           string `json:"secret_ref"`
	VaultPathRef        string `json:"vault_path_ref"`
	RotationPolicyRef   string `json:"rotation_policy_ref"`
	AuditPolicyRef      string `json:"audit_policy_ref"`
	RawAPIKey           string `json:"raw_api_key,omitempty"`
	RawPassword         string `json:"raw_password,omitempty"`
	RawToken            string `json:"raw_token,omitempty"`
	RawRefreshToken     string `json:"raw_refresh_token,omitempty"`
	RawCertificate      string `json:"raw_certificate,omitempty"`
	RawPrivateKey       string `json:"raw_private_key,omitempty"`
	RawClientSecret     string `json:"raw_client_secret,omitempty"`
}

func NewLogoCredentialContract() LogoCredentialContract {
	return LogoCredentialContract{
		Module:                 ModuleFAZ78L,
		Step:                   StepFAZ78L3,
		ProviderCode:           ProviderCode,
		ProviderName:           ProviderName,
		ConnectorCode:          ConnectorCode,
		ConnectorFamily:        ConnectorFamily,
		RuntimeMode:            RuntimeModeDryRun,
		CredentialMode:         LogoCredentialMode,
		RealProviderAPIStatus:  RealProviderAPIClosedStatus,
		RealFileDeliveryStatus: RealFileDeliveryClosedStatus,
		RealERPWriteStatus:     RealERPWriteClosedStatus,
		RealSecretValueStatus:  LogoRealSecretValueStatus,
		CredentialProfile: LogoCredentialProfile{
			Declared:                    true,
			Status:                      LogoCredentialProfileStatus,
			TenantScopeRequired:         true,
			EnvironmentScopeRequired:    true,
			CredentialProfileIDRequired: true,
			SecretReferenceRequired:     true,
			VaultPathReferenceRequired:  true,
			RotationPolicyRequired:      true,
			AuditPolicyRequired:         true,
			RawSecretAllowed:            false,
			LiveUsageAllowed:            false,
		},
		SecretReference: LogoSecretReferenceContract{
			Declared: true,
			Status:   LogoSecretReferenceStatus,
			AllowedReferenceFields: []string{
				"tenant_id",
				"environment",
				"credential_profile_id",
				"secret_ref",
				"vault_path_ref",
				"rotation_policy_ref",
				"audit_policy_ref",
			},
			ForbiddenRawSecretFields: []string{
				"raw_api_key",
				"raw_password",
				"raw_token",
				"raw_refresh_token",
				"raw_certificate",
				"raw_private_key",
				"raw_client_secret",
			},
			SecretValuesInConfigAllowed: false,
			SecretValuesInCodeAllowed:   false,
			SecretValuesInDocsAllowed:   false,
		},
		RotationPolicy: LogoCredentialRotationPolicy{
			Declared:                  true,
			RotationRequired:          true,
			RevocationRequired:        true,
			BreakGlassRequired:        true,
			LiveRotationAllowedInStep: false,
		},
		AuditPolicy: LogoCredentialAuditPolicy{
			Declared:                    true,
			TenantIDRequired:            true,
			CredentialProfileIDRequired: true,
			CorrelationIDRequired:       true,
			SecretValueLoggingAllowed:   false,
		},
		Operations: []LogoCredentialOperationContract{
			{Name: LogoOperationDeclareCredentialProfile, Mode: LogoCredentialMode, ExternalCallAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false, RawSecretAllowed: false},
			{Name: LogoOperationDeclareSecretReference, Mode: LogoCredentialMode, ExternalCallAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false, RawSecretAllowed: false},
			{Name: LogoOperationValidateNoRawSecret, Mode: LogoCredentialMode, ExternalCallAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false, RawSecretAllowed: false},
			{Name: LogoOperationValidateTenantCredentialBoundary, Mode: LogoCredentialMode, ExternalCallAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false, RawSecretAllowed: false},
			{Name: LogoOperationPrepareCredentialRotationPolicy, Mode: LogoCredentialMode, ExternalCallAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false, RawSecretAllowed: false},
			{Name: LogoOperationPrepareCredentialAuditPolicy, Mode: LogoCredentialMode, ExternalCallAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false, RawSecretAllowed: false},
			{Name: LogoOperationPrepareLiveSecretHandoff, Mode: LogoCredentialMode, ExternalCallAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false, RawSecretAllowed: false},
		},
	}
}

func NewLogoDryRunCredentialReference(tenantID string, environment string, credentialProfileID string) LogoCredentialReference {
	safeTenantID := credentialTrim(tenantID)
	safeEnvironment := credentialTrim(environment)
	safeProfileID := credentialTrim(credentialProfileID)

	return LogoCredentialReference{
		TenantID:            safeTenantID,
		Environment:         safeEnvironment,
		CredentialProfileID: safeProfileID,
		SecretRef:           fmt.Sprintf("secret-ref://logo/%s/%s/%s", safeEnvironment, safeTenantID, safeProfileID),
		VaultPathRef:        fmt.Sprintf("vault-ref://pix2pi/integrations/logo/%s/%s/%s", safeEnvironment, safeTenantID, safeProfileID),
		RotationPolicyRef:   "rotation-policy://logo/default-rotation-readiness",
		AuditPolicyRef:      "audit-policy://logo/credential-access-readiness",
	}
}

func (c LogoCredentialContract) Validate() error {
	foundation := NewProviderIdentity()
	if err := foundation.Validate(); err != nil {
		return fmt.Errorf("logo foundation must be valid before credential readiness: %w", err)
	}

	liveContract := NewLogoLiveContract()
	if err := liveContract.Validate(); err != nil {
		return fmt.Errorf("logo live contract must be valid before credential readiness: %w", err)
	}

	if credentialTrim(c.Module) != ModuleFAZ78L {
		return fmt.Errorf("invalid module: %s", c.Module)
	}
	if credentialTrim(c.Step) != StepFAZ78L3 {
		return fmt.Errorf("invalid step: %s", c.Step)
	}
	if credentialTrim(c.ProviderCode) != ProviderCode {
		return fmt.Errorf("invalid provider code: %s", c.ProviderCode)
	}
	if strings.TrimSpace(c.ProviderName) != ProviderName {
		return fmt.Errorf("invalid provider name: %s", c.ProviderName)
	}
	if credentialTrim(c.ConnectorCode) != ConnectorCode {
		return fmt.Errorf("invalid connector code: %s", c.ConnectorCode)
	}
	if credentialTrim(c.ConnectorFamily) != ConnectorFamily {
		return fmt.Errorf("invalid connector family: %s", c.ConnectorFamily)
	}
	if credentialTrim(c.RuntimeMode) != RuntimeModeDryRun {
		return fmt.Errorf("invalid runtime mode: %s", c.RuntimeMode)
	}
	if credentialTrim(c.CredentialMode) != LogoCredentialMode {
		return fmt.Errorf("invalid credential mode: %s", c.CredentialMode)
	}
	if !c.RealIntegrationsClosed() {
		return errors.New("real Logo provider API, file delivery, ERP write, and secret values must remain closed")
	}
	if err := c.CredentialProfile.Validate(); err != nil {
		return fmt.Errorf("invalid credential profile: %w", err)
	}
	if err := c.SecretReference.Validate(); err != nil {
		return fmt.Errorf("invalid secret reference contract: %w", err)
	}
	if err := c.RotationPolicy.Validate(); err != nil {
		return fmt.Errorf("invalid rotation policy: %w", err)
	}
	if err := c.AuditPolicy.Validate(); err != nil {
		return fmt.Errorf("invalid audit policy: %w", err)
	}

	requiredOperations := []LogoCredentialOperationName{
		LogoOperationDeclareCredentialProfile,
		LogoOperationDeclareSecretReference,
		LogoOperationValidateNoRawSecret,
		LogoOperationValidateTenantCredentialBoundary,
		LogoOperationPrepareCredentialRotationPolicy,
		LogoOperationPrepareCredentialAuditPolicy,
		LogoOperationPrepareLiveSecretHandoff,
	}

	for _, operationName := range requiredOperations {
		operation, ok := c.Operation(operationName)
		if !ok {
			return fmt.Errorf("missing required operation: %s", operationName)
		}
		if operation.Mode != LogoCredentialMode {
			return fmt.Errorf("operation %s must use secret-reference-only mode", operationName)
		}
		if operation.ExternalCallAllowed {
			return fmt.Errorf("operation %s must not allow external calls", operationName)
		}
		if operation.FileDeliveryAllowed {
			return fmt.Errorf("operation %s must not allow file delivery", operationName)
		}
		if operation.ERPWriteAllowed {
			return fmt.Errorf("operation %s must not allow ERP writes", operationName)
		}
		if operation.RawSecretAllowed {
			return fmt.Errorf("operation %s must not allow raw secrets", operationName)
		}
	}

	return nil
}

func (c LogoCredentialContract) RealIntegrationsClosed() bool {
	return credentialTrim(c.RealProviderAPIStatus) == RealProviderAPIClosedStatus &&
		credentialTrim(c.RealFileDeliveryStatus) == RealFileDeliveryClosedStatus &&
		credentialTrim(c.RealERPWriteStatus) == RealERPWriteClosedStatus &&
		credentialTrim(c.RealSecretValueStatus) == LogoRealSecretValueStatus
}

func (c LogoCredentialContract) Operation(name LogoCredentialOperationName) (LogoCredentialOperationContract, bool) {
	for _, operation := range c.Operations {
		if operation.Name == name {
			return operation, true
		}
	}
	return LogoCredentialOperationContract{}, false
}

func (p LogoCredentialProfile) Validate() error {
	if !p.Declared {
		return errors.New("credential profile must be declared")
	}
	if credentialTrim(p.Status) != LogoCredentialProfileStatus {
		return fmt.Errorf("invalid credential profile status: %s", p.Status)
	}
	if !p.TenantScopeRequired {
		return errors.New("tenant scope must be required")
	}
	if !p.EnvironmentScopeRequired {
		return errors.New("environment scope must be required")
	}
	if !p.CredentialProfileIDRequired {
		return errors.New("credential profile id must be required")
	}
	if !p.SecretReferenceRequired {
		return errors.New("secret reference must be required")
	}
	if !p.VaultPathReferenceRequired {
		return errors.New("vault path reference must be required")
	}
	if !p.RotationPolicyRequired {
		return errors.New("rotation policy must be required")
	}
	if !p.AuditPolicyRequired {
		return errors.New("audit policy must be required")
	}
	if p.RawSecretAllowed {
		return errors.New("raw secret must not be allowed")
	}
	if p.LiveUsageAllowed {
		return errors.New("live usage must not be allowed in this step")
	}
	return nil
}

func (s LogoSecretReferenceContract) Validate() error {
	if !s.Declared {
		return errors.New("secret reference contract must be declared")
	}
	if credentialTrim(s.Status) != LogoSecretReferenceStatus {
		return fmt.Errorf("invalid secret reference status: %s", s.Status)
	}
	if len(s.AllowedReferenceFields) == 0 {
		return errors.New("allowed reference fields must be declared")
	}
	if len(s.ForbiddenRawSecretFields) == 0 {
		return errors.New("forbidden raw secret fields must be declared")
	}
	if s.SecretValuesInConfigAllowed {
		return errors.New("secret values in config must not be allowed")
	}
	if s.SecretValuesInCodeAllowed {
		return errors.New("secret values in code must not be allowed")
	}
	if s.SecretValuesInDocsAllowed {
		return errors.New("secret values in docs must not be allowed")
	}
	return nil
}

func (r LogoCredentialRotationPolicy) Validate() error {
	if !r.Declared {
		return errors.New("rotation policy must be declared")
	}
	if !r.RotationRequired {
		return errors.New("rotation must be required")
	}
	if !r.RevocationRequired {
		return errors.New("revocation must be required")
	}
	if !r.BreakGlassRequired {
		return errors.New("break-glass must be required")
	}
	if r.LiveRotationAllowedInStep {
		return errors.New("live rotation must not be allowed in this step")
	}
	return nil
}

func (a LogoCredentialAuditPolicy) Validate() error {
	if !a.Declared {
		return errors.New("audit policy must be declared")
	}
	if !a.TenantIDRequired {
		return errors.New("tenant id must be required")
	}
	if !a.CredentialProfileIDRequired {
		return errors.New("credential profile id must be required")
	}
	if !a.CorrelationIDRequired {
		return errors.New("correlation id must be required")
	}
	if a.SecretValueLoggingAllowed {
		return errors.New("secret value logging must not be allowed")
	}
	return nil
}

func (r LogoCredentialReference) ValidateReferenceOnly() error {
	if credentialTrim(r.TenantID) == "" {
		return errors.New("tenant id is required")
	}
	if credentialTrim(r.Environment) == "" {
		return errors.New("environment is required")
	}
	if credentialTrim(r.CredentialProfileID) == "" {
		return errors.New("credential profile id is required")
	}
	if credentialTrim(r.SecretRef) == "" {
		return errors.New("secret ref is required")
	}
	if credentialTrim(r.VaultPathRef) == "" {
		return errors.New("vault path ref is required")
	}
	if credentialTrim(r.RotationPolicyRef) == "" {
		return errors.New("rotation policy ref is required")
	}
	if credentialTrim(r.AuditPolicyRef) == "" {
		return errors.New("audit policy ref is required")
	}
	if r.ContainsRawSecret() {
		return errors.New("raw secret value is forbidden")
	}
	return nil
}

func (r LogoCredentialReference) ContainsRawSecret() bool {
	return credentialTrim(r.RawAPIKey) != "" ||
		credentialTrim(r.RawPassword) != "" ||
		credentialTrim(r.RawToken) != "" ||
		credentialTrim(r.RawRefreshToken) != "" ||
		credentialTrim(r.RawCertificate) != "" ||
		credentialTrim(r.RawPrivateKey) != "" ||
		credentialTrim(r.RawClientSecret) != ""
}

func credentialTrim(value string) string {
	return strings.TrimSpace(value)
}
