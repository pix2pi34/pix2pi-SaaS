package logo

import (
	"errors"
	"fmt"
)

const (
	StepFAZ78L7 = "FAZ_7_8L.7"

	LogoValidationRetryDLQMode   = "VALIDATION_RETRY_DLQ_DRY_RUN_ONLY"
	LogoValidationRetryDLQStatus = "READY"
	LogoValidationContractStatus = "READY"

	LogoDecisionPass         = "PASS"
	LogoDecisionRetry        = "RETRY"
	LogoDecisionDLQ          = "DLQ"
	LogoDecisionManualReview = "MANUAL_REVIEW"
)

type LogoErrorClass string

const (
	LogoErrorClassValidation        LogoErrorClass = "VALIDATION_ERROR"
	LogoErrorClassTenantBoundary    LogoErrorClass = "TENANT_BOUNDARY_ERROR"
	LogoErrorClassChecksum          LogoErrorClass = "CHECKSUM_ERROR"
	LogoErrorClassManifest          LogoErrorClass = "MANIFEST_ERROR"
	LogoErrorClassTransientProvider LogoErrorClass = "TRANSIENT_PROVIDER_ERROR"
	LogoErrorClassPermanentProvider LogoErrorClass = "PERMANENT_PROVIDER_ERROR"
	LogoErrorClassUnknownProvider   LogoErrorClass = "UNKNOWN_PROVIDER_ERROR"
)

type LogoErrorCode string

const (
	LogoErrorMissingTenantID         LogoErrorCode = "MISSING_TENANT_ID"
	LogoErrorMissingCorrelationID    LogoErrorCode = "MISSING_CORRELATION_ID"
	LogoErrorMissingIdempotencyKey   LogoErrorCode = "MISSING_IDEMPOTENCY_KEY"
	LogoErrorChecksumMismatch        LogoErrorCode = "CHECKSUM_MISMATCH"
	LogoErrorInvalidManifest         LogoErrorCode = "INVALID_MANIFEST"
	LogoErrorTenantBoundaryViolation LogoErrorCode = "TENANT_BOUNDARY_VIOLATION"
	LogoErrorProviderTimeout         LogoErrorCode = "PROVIDER_TIMEOUT"
	LogoErrorProviderRateLimit       LogoErrorCode = "PROVIDER_RATE_LIMIT"
	LogoErrorProviderRejectedPackage LogoErrorCode = "PROVIDER_REJECTED_PACKAGE"
	LogoErrorUnknownProvider         LogoErrorCode = "UNKNOWN_PROVIDER_ERROR"
)

type LogoValidationRetryDLQOperationName string

const (
	LogoOperationDeclareValidationRetryDLQContract LogoValidationRetryDLQOperationName = "DECLARE_LOGO_VALIDATION_RETRY_DLQ_CONTRACT"
	LogoOperationValidateDeliveryEnvelope          LogoValidationRetryDLQOperationName = "VALIDATE_LOGO_DELIVERY_ENVELOPE"
	LogoOperationValidateChecksum                  LogoValidationRetryDLQOperationName = "VALIDATE_LOGO_CHECKSUM"
	LogoOperationValidateManifest                  LogoValidationRetryDLQOperationName = "VALIDATE_LOGO_MANIFEST"
	LogoOperationMapErrorCode                      LogoValidationRetryDLQOperationName = "MAP_LOGO_ERROR_CODE"
	LogoOperationDecideRetryOrDLQ                  LogoValidationRetryDLQOperationName = "DECIDE_LOGO_RETRY_OR_DLQ"
	LogoOperationDecideManualReview                LogoValidationRetryDLQOperationName = "DECIDE_LOGO_MANUAL_REVIEW"
	LogoOperationValidateNoRealDeliveryRetryDLQ    LogoValidationRetryDLQOperationName = "VALIDATE_LOGO_NO_REAL_DELIVERY"
	LogoOperationPrepareAdminOpsHandoff            LogoValidationRetryDLQOperationName = "PREPARE_LOGO_ADMIN_OPS_HANDOFF"
)

type LogoValidationContract struct {
	Declared                bool   `json:"declared"`
	Status                  string `json:"status"`
	DryRunOnly              bool   `json:"dry_run_only"`
	ExternalCallAllowed     bool   `json:"external_call_allowed"`
	RealFileDeliveryAllowed bool   `json:"real_file_delivery_allowed"`
	ERPWriteAllowed         bool   `json:"erp_write_allowed"`
	TenantRequired          bool   `json:"tenant_required"`
	CorrelationIDRequired   bool   `json:"correlation_id_required"`
	IdempotencyKeyRequired  bool   `json:"idempotency_key_required"`
	ChecksumRequired        bool   `json:"checksum_required"`
	ManifestRequired        bool   `json:"manifest_required"`
}

type LogoErrorMapping struct {
	Code         LogoErrorCode  `json:"code"`
	Class        LogoErrorClass `json:"class"`
	Retryable    bool           `json:"retryable"`
	DLQ          bool           `json:"dlq"`
	ManualReview bool           `json:"manual_review"`
}

type LogoRetryPolicy struct {
	Declared                 bool             `json:"declared"`
	MaxAttempts              int              `json:"max_attempts"`
	BackoffSeconds           []int            `json:"backoff_seconds"`
	RetryableClasses         []LogoErrorClass `json:"retryable_classes"`
	RetryLimitExceededAction string           `json:"retry_limit_exceeded_action"`
}

type LogoValidationRetryDLQOperationContract struct {
	Name                    LogoValidationRetryDLQOperationName `json:"name"`
	Mode                    string                              `json:"mode"`
	DryRunValidationAllowed bool                                `json:"dry_run_validation_allowed"`
	ExternalCallAllowed     bool                                `json:"external_call_allowed"`
	RealFileDeliveryAllowed bool                                `json:"real_file_delivery_allowed"`
	ERPWriteAllowed         bool                                `json:"erp_write_allowed"`
}

type LogoValidationRetryDLQContract struct {
	Module                 string                                    `json:"module"`
	Step                   string                                    `json:"step"`
	ProviderCode           string                                    `json:"provider_code"`
	ProviderName           string                                    `json:"provider_name"`
	ConnectorCode          string                                    `json:"connector_code"`
	ConnectorFamily        string                                    `json:"connector_family"`
	RuntimeMode            string                                    `json:"runtime_mode"`
	ValidationMode         string                                    `json:"validation_mode"`
	TargetSystem           string                                    `json:"target_system"`
	ValidationStatus       string                                    `json:"validation_retry_dlq_status"`
	RealProviderAPIStatus  string                                    `json:"real_provider_api_status"`
	RealFileDeliveryStatus string                                    `json:"real_file_delivery_status"`
	RealERPWriteStatus     string                                    `json:"real_erp_write_status"`
	ValidationContract     LogoValidationContract                    `json:"validation_contract"`
	ErrorMappings          []LogoErrorMapping                        `json:"error_mappings"`
	RetryPolicy            LogoRetryPolicy                           `json:"retry_policy"`
	Operations             []LogoValidationRetryDLQOperationContract `json:"operations"`
}

type LogoValidationResult struct {
	Valid  bool                  `json:"valid"`
	Errors []LogoValidationError `json:"errors"`
}

type LogoValidationError struct {
	Code    LogoErrorCode  `json:"code"`
	Class   LogoErrorClass `json:"class"`
	Message string         `json:"message"`
}

type LogoRetryDecision struct {
	Action         string         `json:"action"`
	ErrorCode      LogoErrorCode  `json:"error_code"`
	ErrorClass     LogoErrorClass `json:"error_class"`
	RetryAllowed   bool           `json:"retry_allowed"`
	DLQ            bool           `json:"dlq"`
	ManualReview   bool           `json:"manual_review"`
	NextAttempt    int            `json:"next_attempt"`
	BackoffSeconds int            `json:"backoff_seconds"`
	Reason         string         `json:"reason"`
}

func NewLogoValidationRetryDLQContract() LogoValidationRetryDLQContract {
	return LogoValidationRetryDLQContract{
		Module:                 ModuleFAZ78L,
		Step:                   StepFAZ78L7,
		ProviderCode:           ProviderCode,
		ProviderName:           ProviderName,
		ConnectorCode:          ConnectorCode,
		ConnectorFamily:        ConnectorFamily,
		RuntimeMode:            RuntimeModeDryRun,
		ValidationMode:         LogoValidationRetryDLQMode,
		TargetSystem:           LogoTargetSystem,
		ValidationStatus:       LogoValidationRetryDLQStatus,
		RealProviderAPIStatus:  RealProviderAPIClosedStatus,
		RealFileDeliveryStatus: RealFileDeliveryClosedStatus,
		RealERPWriteStatus:     RealERPWriteClosedStatus,
		ValidationContract: LogoValidationContract{
			Declared:                true,
			Status:                  LogoValidationContractStatus,
			DryRunOnly:              true,
			ExternalCallAllowed:     false,
			RealFileDeliveryAllowed: false,
			ERPWriteAllowed:         false,
			TenantRequired:          true,
			CorrelationIDRequired:   true,
			IdempotencyKeyRequired:  true,
			ChecksumRequired:        true,
			ManifestRequired:        true,
		},
		ErrorMappings: []LogoErrorMapping{
			{Code: LogoErrorMissingTenantID, Class: LogoErrorClassValidation, Retryable: false, DLQ: true, ManualReview: false},
			{Code: LogoErrorMissingCorrelationID, Class: LogoErrorClassValidation, Retryable: false, DLQ: true, ManualReview: false},
			{Code: LogoErrorMissingIdempotencyKey, Class: LogoErrorClassValidation, Retryable: false, DLQ: true, ManualReview: false},
			{Code: LogoErrorChecksumMismatch, Class: LogoErrorClassChecksum, Retryable: false, DLQ: false, ManualReview: true},
			{Code: LogoErrorInvalidManifest, Class: LogoErrorClassManifest, Retryable: false, DLQ: true, ManualReview: false},
			{Code: LogoErrorTenantBoundaryViolation, Class: LogoErrorClassTenantBoundary, Retryable: false, DLQ: false, ManualReview: true},
			{Code: LogoErrorProviderTimeout, Class: LogoErrorClassTransientProvider, Retryable: true, DLQ: false, ManualReview: false},
			{Code: LogoErrorProviderRateLimit, Class: LogoErrorClassTransientProvider, Retryable: true, DLQ: false, ManualReview: false},
			{Code: LogoErrorProviderRejectedPackage, Class: LogoErrorClassPermanentProvider, Retryable: false, DLQ: true, ManualReview: false},
			{Code: LogoErrorUnknownProvider, Class: LogoErrorClassUnknownProvider, Retryable: false, DLQ: false, ManualReview: true},
		},
		RetryPolicy: LogoRetryPolicy{
			Declared:                 true,
			MaxAttempts:              3,
			BackoffSeconds:           []int{10, 30, 90},
			RetryableClasses:         []LogoErrorClass{LogoErrorClassTransientProvider},
			RetryLimitExceededAction: LogoDecisionDLQ,
		},
		Operations: []LogoValidationRetryDLQOperationContract{
			{Name: LogoOperationDeclareValidationRetryDLQContract, Mode: LogoValidationRetryDLQMode, DryRunValidationAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateDeliveryEnvelope, Mode: LogoValidationRetryDLQMode, DryRunValidationAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateChecksum, Mode: LogoValidationRetryDLQMode, DryRunValidationAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateManifest, Mode: LogoValidationRetryDLQMode, DryRunValidationAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationMapErrorCode, Mode: LogoValidationRetryDLQMode, DryRunValidationAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationDecideRetryOrDLQ, Mode: LogoValidationRetryDLQMode, DryRunValidationAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationDecideManualReview, Mode: LogoValidationRetryDLQMode, DryRunValidationAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateNoRealDeliveryRetryDLQ, Mode: LogoValidationRetryDLQMode, DryRunValidationAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationPrepareAdminOpsHandoff, Mode: LogoValidationRetryDLQMode, DryRunValidationAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
		},
	}
}

func (c LogoValidationRetryDLQContract) Validate() error {
	importDelivery := NewLogoImportDeliveryContract()
	if err := importDelivery.Validate(); err != nil {
		return fmt.Errorf("logo import delivery contract must be valid before validation retry-DLQ: %w", err)
	}

	if validationTrim(c.Module) != ModuleFAZ78L {
		return fmt.Errorf("invalid module: %s", c.Module)
	}
	if validationTrim(c.Step) != StepFAZ78L7 {
		return fmt.Errorf("invalid step: %s", c.Step)
	}
	if validationTrim(c.ProviderCode) != ProviderCode {
		return fmt.Errorf("invalid provider code: %s", c.ProviderCode)
	}
	if validationTrim(c.RuntimeMode) != RuntimeModeDryRun {
		return fmt.Errorf("invalid runtime mode: %s", c.RuntimeMode)
	}
	if validationTrim(c.ValidationMode) != LogoValidationRetryDLQMode {
		return fmt.Errorf("invalid validation mode: %s", c.ValidationMode)
	}
	if validationTrim(c.TargetSystem) != LogoTargetSystem {
		return fmt.Errorf("invalid target system: %s", c.TargetSystem)
	}
	if validationTrim(c.ValidationStatus) != LogoValidationRetryDLQStatus {
		return fmt.Errorf("invalid validation status: %s", c.ValidationStatus)
	}
	if !c.RealIntegrationsClosed() {
		return errors.New("real Logo provider API, file delivery, and ERP write must remain closed")
	}
	if err := c.ValidationContract.Validate(); err != nil {
		return err
	}
	if err := c.RetryPolicy.Validate(); err != nil {
		return err
	}
	if err := c.ValidateErrorMappings(); err != nil {
		return err
	}
	if err := c.ValidateOperations(); err != nil {
		return err
	}
	return nil
}

func (c LogoValidationRetryDLQContract) RealIntegrationsClosed() bool {
	return validationTrim(c.RealProviderAPIStatus) == RealProviderAPIClosedStatus &&
		validationTrim(c.RealFileDeliveryStatus) == RealFileDeliveryClosedStatus &&
		validationTrim(c.RealERPWriteStatus) == RealERPWriteClosedStatus
}

func (c LogoValidationRetryDLQContract) ValidateErrorMappings() error {
	required := []LogoErrorCode{
		LogoErrorMissingTenantID,
		LogoErrorMissingCorrelationID,
		LogoErrorMissingIdempotencyKey,
		LogoErrorChecksumMismatch,
		LogoErrorInvalidManifest,
		LogoErrorTenantBoundaryViolation,
		LogoErrorProviderTimeout,
		LogoErrorProviderRateLimit,
		LogoErrorProviderRejectedPackage,
		LogoErrorUnknownProvider,
	}

	for _, code := range required {
		mapping, ok := c.ErrorMapping(code)
		if !ok {
			return fmt.Errorf("missing error mapping: %s", code)
		}
		if err := mapping.Validate(); err != nil {
			return fmt.Errorf("invalid error mapping %s: %w", code, err)
		}
	}
	return nil
}

func (c LogoValidationRetryDLQContract) ValidateOperations() error {
	requiredOperations := []LogoValidationRetryDLQOperationName{
		LogoOperationDeclareValidationRetryDLQContract,
		LogoOperationValidateDeliveryEnvelope,
		LogoOperationValidateChecksum,
		LogoOperationValidateManifest,
		LogoOperationMapErrorCode,
		LogoOperationDecideRetryOrDLQ,
		LogoOperationDecideManualReview,
		LogoOperationValidateNoRealDeliveryRetryDLQ,
		LogoOperationPrepareAdminOpsHandoff,
	}

	for _, operationName := range requiredOperations {
		operation, ok := c.Operation(operationName)
		if !ok {
			return fmt.Errorf("missing required operation: %s", operationName)
		}
		if operation.Mode != LogoValidationRetryDLQMode {
			return fmt.Errorf("operation %s must use validation retry-DLQ mode", operationName)
		}
		if !operation.DryRunValidationAllowed {
			return fmt.Errorf("operation %s must allow dry-run validation", operationName)
		}
		if operation.ExternalCallAllowed {
			return fmt.Errorf("operation %s must not allow external calls", operationName)
		}
		if operation.RealFileDeliveryAllowed {
			return fmt.Errorf("operation %s must not allow real file delivery", operationName)
		}
		if operation.ERPWriteAllowed {
			return fmt.Errorf("operation %s must not allow ERP writes", operationName)
		}
	}
	return nil
}

func (c LogoValidationRetryDLQContract) Operation(name LogoValidationRetryDLQOperationName) (LogoValidationRetryDLQOperationContract, bool) {
	for _, operation := range c.Operations {
		if operation.Name == name {
			return operation, true
		}
	}
	return LogoValidationRetryDLQOperationContract{}, false
}

func (c LogoValidationRetryDLQContract) ErrorMapping(code LogoErrorCode) (LogoErrorMapping, bool) {
	for _, mapping := range c.ErrorMappings {
		if mapping.Code == code {
			return mapping, true
		}
	}
	return LogoErrorMapping{}, false
}

func (c LogoValidationRetryDLQContract) ValidateEnvelope(envelope LogoImportDeliveryEnvelope, expectedTenantID string) LogoValidationResult {
	result := LogoValidationResult{Valid: true}

	if validationTrim(envelope.TenantID) == "" {
		result.AddError(LogoErrorMissingTenantID, LogoErrorClassValidation, "tenant_id is required")
	}
	if validationTrim(envelope.CorrelationID) == "" {
		result.AddError(LogoErrorMissingCorrelationID, LogoErrorClassValidation, "correlation_id is required")
	}
	if validationTrim(envelope.IdempotencyKey) == "" {
		result.AddError(LogoErrorMissingIdempotencyKey, LogoErrorClassValidation, "idempotency_key is required")
	}
	if validationTrim(expectedTenantID) != "" && envelope.TenantID != expectedTenantID {
		result.AddError(LogoErrorTenantBoundaryViolation, LogoErrorClassTenantBoundary, "tenant boundary violation")
	}
	if validationTrim(envelope.ChecksumSHA256) == "" {
		result.AddError(LogoErrorChecksumMismatch, LogoErrorClassChecksum, "checksum is required")
	}
	if len(envelope.Manifest) == 0 {
		result.AddError(LogoErrorInvalidManifest, LogoErrorClassManifest, "manifest is required")
	}
	if envelope.DeliveryAllowed {
		result.AddError(LogoErrorTenantBoundaryViolation, LogoErrorClassTenantBoundary, "delivery must remain disabled")
	}
	if envelope.ExternalCallAllowed {
		result.AddError(LogoErrorTenantBoundaryViolation, LogoErrorClassTenantBoundary, "external call must remain disabled")
	}
	if envelope.ERPWriteAllowed {
		result.AddError(LogoErrorTenantBoundaryViolation, LogoErrorClassTenantBoundary, "ERP write must remain disabled")
	}

	if len(result.Errors) > 0 {
		result.Valid = false
	}
	return result
}

func (c LogoValidationRetryDLQContract) Decide(code LogoErrorCode, currentAttempt int) LogoRetryDecision {
	mapping, ok := c.ErrorMapping(code)
	if !ok {
		mapping = LogoErrorMapping{Code: LogoErrorUnknownProvider, Class: LogoErrorClassUnknownProvider, Retryable: false, DLQ: false, ManualReview: true}
	}

	if mapping.ManualReview {
		return LogoRetryDecision{
			Action:       LogoDecisionManualReview,
			ErrorCode:    mapping.Code,
			ErrorClass:   mapping.Class,
			ManualReview: true,
			Reason:       "manual review required",
		}
	}

	if mapping.DLQ {
		return LogoRetryDecision{
			Action:     LogoDecisionDLQ,
			ErrorCode:  mapping.Code,
			ErrorClass: mapping.Class,
			DLQ:        true,
			Reason:     "non-retryable error mapped to DLQ",
		}
	}

	if mapping.Retryable {
		if currentAttempt < c.RetryPolicy.MaxAttempts {
			nextAttempt := currentAttempt + 1
			return LogoRetryDecision{
				Action:         LogoDecisionRetry,
				ErrorCode:      mapping.Code,
				ErrorClass:     mapping.Class,
				RetryAllowed:   true,
				NextAttempt:    nextAttempt,
				BackoffSeconds: c.RetryPolicy.BackoffForAttempt(nextAttempt),
				Reason:         "retryable transient provider error",
			}
		}

		return LogoRetryDecision{
			Action:     LogoDecisionDLQ,
			ErrorCode:  mapping.Code,
			ErrorClass: mapping.Class,
			DLQ:        true,
			Reason:     "retry limit exceeded",
		}
	}

	return LogoRetryDecision{
		Action:     LogoDecisionDLQ,
		ErrorCode:  mapping.Code,
		ErrorClass: mapping.Class,
		DLQ:        true,
		Reason:     "fallback DLQ decision",
	}
}

func (r *LogoValidationResult) AddError(code LogoErrorCode, class LogoErrorClass, message string) {
	r.Errors = append(r.Errors, LogoValidationError{Code: code, Class: class, Message: message})
	r.Valid = false
}

func (v LogoValidationContract) Validate() error {
	if !v.Declared {
		return errors.New("validation contract must be declared")
	}
	if validationTrim(v.Status) != LogoValidationContractStatus {
		return fmt.Errorf("invalid validation contract status: %s", v.Status)
	}
	if !v.DryRunOnly {
		return errors.New("validation contract must be dry-run only")
	}
	if v.ExternalCallAllowed {
		return errors.New("external call must not be allowed")
	}
	if v.RealFileDeliveryAllowed {
		return errors.New("real file delivery must not be allowed")
	}
	if v.ERPWriteAllowed {
		return errors.New("ERP write must not be allowed")
	}
	if !v.TenantRequired {
		return errors.New("tenant validation must be required")
	}
	if !v.CorrelationIDRequired {
		return errors.New("correlation id validation must be required")
	}
	if !v.IdempotencyKeyRequired {
		return errors.New("idempotency key validation must be required")
	}
	if !v.ChecksumRequired {
		return errors.New("checksum validation must be required")
	}
	if !v.ManifestRequired {
		return errors.New("manifest validation must be required")
	}
	return nil
}

func (m LogoErrorMapping) Validate() error {
	if validationTrim(string(m.Code)) == "" {
		return errors.New("error code is required")
	}
	if validationTrim(string(m.Class)) == "" {
		return errors.New("error class is required")
	}
	if m.Retryable && m.DLQ {
		return errors.New("retryable error cannot be direct DLQ")
	}
	if m.Retryable && m.ManualReview {
		return errors.New("retryable error cannot be direct manual review")
	}
	if m.DLQ && m.ManualReview {
		return errors.New("error cannot be both DLQ and manual review")
	}
	return nil
}

func (p LogoRetryPolicy) Validate() error {
	if !p.Declared {
		return errors.New("retry policy must be declared")
	}
	if p.MaxAttempts <= 0 {
		return errors.New("max attempts must be positive")
	}
	if len(p.BackoffSeconds) == 0 {
		return errors.New("backoff seconds must be declared")
	}
	if len(p.RetryableClasses) == 0 {
		return errors.New("retryable classes must be declared")
	}
	if p.RetryLimitExceededAction != LogoDecisionDLQ {
		return errors.New("retry limit exceeded action must be DLQ")
	}
	return nil
}

func (p LogoRetryPolicy) BackoffForAttempt(attempt int) int {
	if attempt <= 0 {
		return p.BackoffSeconds[0]
	}
	index := attempt - 1
	if index >= len(p.BackoffSeconds) {
		return p.BackoffSeconds[len(p.BackoffSeconds)-1]
	}
	return p.BackoffSeconds[index]
}

func validationTrim(value string) string {
	return importDeliveryTrim(value)
}
