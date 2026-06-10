package mikro

import (
	"errors"
	"fmt"
	"strings"
)

const (
	MikroValidationRetryDLQPhase        = "FAZ_7_8M_4"
	MikroValidationRetryDLQModule       = "MIKRO_VALIDATION_ERROR_MAPPING_RETRY_DLQ"
	MikroValidationRetryDLQModuleName   = "Mikro Validation / Error Mapping / Retry-DLQ Readiness"
	MikroValidationRetryDLQMode         = "VALIDATION_RETRY_DLQ_DRY_RUN_ONLY"
	MikroValidationRetryDLQDirection    = "PIX2PI_TO_MIKRO"
	MikroValidationRetryDLQSourceSystem = "PIX2PI_ERP"
	MikroValidationRetryDLQTargetSystem = "MIKRO_ACCOUNTING_IMPORT_DRY_RUN"
	MikroValidationRetryDLQGate         = "READY_AFTER_TEST_AND_AUDIT_PASS"

	MikroValidationRealQueueWritePolicy = "NO_REAL_QUEUE_WRITE_IN_THIS_PHASE"
	MikroRetryStrategyDryRun            = "EXPONENTIAL_BACKOFF_DRY_RUN"

	MikroProviderErrorTimeout         = "MIKRO_TIMEOUT"
	MikroProviderErrorRateLimit       = "MIKRO_RATE_LIMIT"
	MikroProviderErrorFormat          = "MIKRO_FORMAT_ERROR"
	MikroProviderErrorAuthFailed      = "MIKRO_AUTH_FAILED"
	MikroProviderErrorDuplicateRecord = "MIKRO_DUPLICATE_RECORD"
	MikroProviderErrorUnknown         = "MIKRO_UNKNOWN_ERROR"

	MikroErrorClassRetryableTemporary     = "RETRYABLE_TEMPORARY"
	MikroErrorClassRetryableRateLimit     = "RETRYABLE_RATE_LIMIT"
	MikroErrorClassNonRetryableValidation = "NON_RETRYABLE_VALIDATION"
	MikroErrorClassNonRetryableAuth       = "NON_RETRYABLE_AUTH"
	MikroErrorClassNonRetryableDuplicate  = "NON_RETRYABLE_DUPLICATE"
	MikroErrorClassUnknownProvider        = "UNKNOWN_PROVIDER_ERROR"

	MikroValidationActionAccept       = "ACCEPT"
	MikroValidationActionRetry        = "RETRY"
	MikroValidationActionDLQ          = "DLQ"
	MikroValidationActionManualReview = "MANUAL_REVIEW"
	MikroValidationActionReject       = "REJECT"

	MikroValidationDecisionReady          = "MIKRO_VALIDATION_DRY_RUN_PACKAGE_ACCEPTED"
	MikroValidationDecisionRetry          = "MIKRO_VALIDATION_RETRY_DECISION_READY"
	MikroValidationDecisionDLQ            = "MIKRO_VALIDATION_DLQ_DECISION_READY"
	MikroValidationDecisionManualReview   = "MIKRO_VALIDATION_MANUAL_REVIEW_DECISION_READY"
	MikroValidationDecisionInvalidPackage = "MIKRO_VALIDATION_PACKAGE_INVALID"
	MikroValidationDecisionSecretDenied   = "MIKRO_VALIDATION_SECRET_FIELD_FORBIDDEN"
	MikroValidationDecisionRealAPI        = "MIKRO_VALIDATION_REAL_PROVIDER_API_CLOSED"
	MikroValidationDecisionRealFile       = "MIKRO_VALIDATION_REAL_FILE_DELIVERY_CLOSED"
	MikroValidationDecisionRealERP        = "MIKRO_VALIDATION_REAL_ERP_WRITE_CLOSED"
	MikroValidationDecisionRealDelivery   = "MIKRO_VALIDATION_REAL_DELIVERY_CHANNEL_CLOSED"
	MikroValidationDecisionLiveMode       = "MIKRO_VALIDATION_PROVIDER_LIVE_MODE_CLOSED"
)

var (
	ErrInvalidMikroValidationContract = errors.New("invalid mikro validation retry dlq contract")
	ErrInvalidMikroValidationRequest  = errors.New("invalid mikro validation request")
	ErrMikroValidationSecretForbidden = errors.New("mikro validation secret field is forbidden")
)

type MikroRetryPolicy struct {
	Strategy              string
	MaxAttempts           int
	InitialBackoffSeconds int
	MaxBackoffSeconds     int
	RetryableClasses      []string
}

type MikroProviderErrorMapping struct {
	ProviderErrorCode      string
	Classification         string
	Retryable              bool
	ManualReview           bool
	DLQAfterRetryExhausted bool
}

type MikroValidationRetryDLQContract struct {
	Phase                     string
	Module                    string
	ModuleName                string
	ProviderID                string
	ProviderName              string
	ProviderCategory          string
	ValidationMode            string
	Direction                 string
	SourceSystem              string
	TargetSystem              string
	ValidationGate            string
	RealQueueWritePolicy      string
	RealProviderAPIStatus     string
	RealFileDeliveryStatus    string
	RealERPWriteStatus        string
	RealDeliveryChannelStatus string
	RetryPolicy               MikroRetryPolicy
	ProviderErrorMappings     []MikroProviderErrorMapping
	RequiredContextFields     []string
	ForbiddenFieldLabels      []string
}

type MikroValidationRequest struct {
	TenantID                string
	ActorUserID             string
	CorrelationID           string
	ValidationID            string
	RequestedMode           string
	Attempt                 int
	ProviderErrorCode       string
	InjectedFieldName       string
	Package                 MikroDryRunPackage
	RealProviderAPIEnabled  bool
	RealFileDeliveryEnabled bool
	RealERPWriteEnabled     bool
	RealDeliveryEnabled     bool
}

type MikroValidationDecision struct {
	Allowed                   bool
	Phase                     string
	Module                    string
	ProviderID                string
	ProviderName              string
	ValidationID              string
	PackageID                 string
	ERPObjectType             string
	MikroObjectType           string
	ValidationMode            string
	Direction                 string
	TargetSystem              string
	Reason                    string
	Action                    string
	ProviderErrorCode         string
	ProviderErrorClass        string
	Retryable                 bool
	RetryAllowed              bool
	NextAttempt               int
	BackoffSeconds            int
	SendToDLQ                 bool
	ManualReview              bool
	RealQueueWritePolicy      string
	RealProviderAPIStatus     string
	RealFileDeliveryStatus    string
	RealERPWriteStatus        string
	RealDeliveryChannelStatus string
	ValidationGate            string
	AuditFields               map[string]string
}

type MikroValidationRetryDLQRuntime struct {
	Contract MikroValidationRetryDLQContract
}

func NewMikroValidationRetryDLQContract() MikroValidationRetryDLQContract {
	return MikroValidationRetryDLQContract{
		Phase:                     MikroValidationRetryDLQPhase,
		Module:                    MikroValidationRetryDLQModule,
		ModuleName:                MikroValidationRetryDLQModuleName,
		ProviderID:                ProviderID,
		ProviderName:              ProviderName,
		ProviderCategory:          ProviderCategory,
		ValidationMode:            MikroValidationRetryDLQMode,
		Direction:                 MikroValidationRetryDLQDirection,
		SourceSystem:              MikroValidationRetryDLQSourceSystem,
		TargetSystem:              MikroValidationRetryDLQTargetSystem,
		ValidationGate:            MikroValidationRetryDLQGate,
		RealQueueWritePolicy:      MikroValidationRealQueueWritePolicy,
		RealProviderAPIStatus:     MikroRealProviderAPIStatus,
		RealFileDeliveryStatus:    MikroRealFileDeliveryStatus,
		RealERPWriteStatus:        MikroRealERPWriteStatus,
		RealDeliveryChannelStatus: MikroRealDeliveryChannelStatus,
		RetryPolicy: MikroRetryPolicy{
			Strategy:              MikroRetryStrategyDryRun,
			MaxAttempts:           3,
			InitialBackoffSeconds: 30,
			MaxBackoffSeconds:     300,
			RetryableClasses: []string{
				MikroErrorClassRetryableTemporary,
				MikroErrorClassRetryableRateLimit,
			},
		},
		ProviderErrorMappings: []MikroProviderErrorMapping{
			{ProviderErrorCode: MikroProviderErrorTimeout, Classification: MikroErrorClassRetryableTemporary, Retryable: true, ManualReview: false, DLQAfterRetryExhausted: true},
			{ProviderErrorCode: MikroProviderErrorRateLimit, Classification: MikroErrorClassRetryableRateLimit, Retryable: true, ManualReview: false, DLQAfterRetryExhausted: true},
			{ProviderErrorCode: MikroProviderErrorFormat, Classification: MikroErrorClassNonRetryableValidation, Retryable: false, ManualReview: false, DLQAfterRetryExhausted: true},
			{ProviderErrorCode: MikroProviderErrorAuthFailed, Classification: MikroErrorClassNonRetryableAuth, Retryable: false, ManualReview: true, DLQAfterRetryExhausted: false},
			{ProviderErrorCode: MikroProviderErrorDuplicateRecord, Classification: MikroErrorClassNonRetryableDuplicate, Retryable: false, ManualReview: false, DLQAfterRetryExhausted: true},
			{ProviderErrorCode: MikroProviderErrorUnknown, Classification: MikroErrorClassUnknownProvider, Retryable: false, ManualReview: true, DLQAfterRetryExhausted: false},
		},
		RequiredContextFields: []string{
			"tenant_id",
			"actor_user_id",
			"correlation_id",
			"validation_id",
			"package_id",
		},
		ForbiddenFieldLabels: []string{
			"client_secret",
			"access_token",
			"refresh_token",
			"password",
			"real_provider_endpoint",
			"real_delivery_endpoint",
			"secret",
			"token",
		},
	}
}

func NewMikroValidationRetryDLQRuntime() MikroValidationRetryDLQRuntime {
	return MikroValidationRetryDLQRuntime{
		Contract: NewMikroValidationRetryDLQContract(),
	}
}

func (c MikroValidationRetryDLQContract) Validate() error {
	if strings.TrimSpace(c.Phase) != MikroValidationRetryDLQPhase {
		return fmt.Errorf("%w: phase must be %s", ErrInvalidMikroValidationContract, MikroValidationRetryDLQPhase)
	}
	if strings.TrimSpace(c.Module) != MikroValidationRetryDLQModule {
		return fmt.Errorf("%w: module must be %s", ErrInvalidMikroValidationContract, MikroValidationRetryDLQModule)
	}
	if strings.TrimSpace(c.ProviderID) != ProviderID {
		return fmt.Errorf("%w: provider_id must be %s", ErrInvalidMikroValidationContract, ProviderID)
	}
	if strings.TrimSpace(c.ValidationMode) != MikroValidationRetryDLQMode {
		return fmt.Errorf("%w: validation mode mismatch", ErrInvalidMikroValidationContract)
	}
	if strings.TrimSpace(c.Direction) != MikroValidationRetryDLQDirection {
		return fmt.Errorf("%w: direction must be PIX2PI_TO_MIKRO", ErrInvalidMikroValidationContract)
	}
	if strings.TrimSpace(c.TargetSystem) != MikroValidationRetryDLQTargetSystem {
		return fmt.Errorf("%w: target system must be Mikro dry-run import", ErrInvalidMikroValidationContract)
	}
	if c.RealProviderAPIStatus != MikroRealProviderAPIStatus {
		return fmt.Errorf("%w: real provider API must stay closed", ErrInvalidMikroValidationContract)
	}
	if c.RealFileDeliveryStatus != MikroRealFileDeliveryStatus {
		return fmt.Errorf("%w: real file delivery must stay closed", ErrInvalidMikroValidationContract)
	}
	if c.RealERPWriteStatus != MikroRealERPWriteStatus {
		return fmt.Errorf("%w: real ERP write must stay closed", ErrInvalidMikroValidationContract)
	}
	if c.RealDeliveryChannelStatus != MikroRealDeliveryChannelStatus {
		return fmt.Errorf("%w: real delivery channel must stay closed", ErrInvalidMikroValidationContract)
	}
	if c.RealQueueWritePolicy != MikroValidationRealQueueWritePolicy {
		return fmt.Errorf("%w: real queue write policy must stay closed", ErrInvalidMikroValidationContract)
	}
	if c.RetryPolicy.MaxAttempts != 3 {
		return fmt.Errorf("%w: max attempts must be 3", ErrInvalidMikroValidationContract)
	}
	if c.RetryPolicy.Strategy != MikroRetryStrategyDryRun {
		return fmt.Errorf("%w: retry strategy mismatch", ErrInvalidMikroValidationContract)
	}
	if len(c.ProviderErrorMappings) < 6 {
		return fmt.Errorf("%w: provider error mappings are incomplete", ErrInvalidMikroValidationContract)
	}
	if len(c.RequiredContextFields) < 5 {
		return fmt.Errorf("%w: required context fields are incomplete", ErrInvalidMikroValidationContract)
	}
	if len(c.ForbiddenFieldLabels) == 0 {
		return fmt.Errorf("%w: forbidden field labels are required", ErrInvalidMikroValidationContract)
	}
	return nil
}

func (c MikroValidationRetryDLQContract) MappingForProviderError(providerErrorCode string) (MikroProviderErrorMapping, bool) {
	normalized := normalizeExportMappingValue(providerErrorCode)
	for _, mapping := range c.ProviderErrorMappings {
		if mapping.ProviderErrorCode == normalized {
			return mapping, true
		}
	}
	return MikroProviderErrorMapping{}, false
}

func (r MikroValidationRetryDLQRuntime) Evaluate(req MikroValidationRequest) (MikroValidationDecision, error) {
	packageID := strings.TrimSpace(req.Package.Manifest.PackageID)
	decision := MikroValidationDecision{
		Allowed:                   false,
		Phase:                     r.Contract.Phase,
		Module:                    r.Contract.Module,
		ProviderID:                r.Contract.ProviderID,
		ProviderName:              r.Contract.ProviderName,
		ValidationID:              strings.TrimSpace(req.ValidationID),
		PackageID:                 packageID,
		ERPObjectType:             normalizeExportMappingValue(req.Package.Manifest.ERPObjectType),
		MikroObjectType:           req.Package.Manifest.MikroObjectType,
		ValidationMode:            r.Contract.ValidationMode,
		Direction:                 r.Contract.Direction,
		TargetSystem:              r.Contract.TargetSystem,
		RealQueueWritePolicy:      r.Contract.RealQueueWritePolicy,
		RealProviderAPIStatus:     r.Contract.RealProviderAPIStatus,
		RealFileDeliveryStatus:    r.Contract.RealFileDeliveryStatus,
		RealERPWriteStatus:        r.Contract.RealERPWriteStatus,
		RealDeliveryChannelStatus: r.Contract.RealDeliveryChannelStatus,
		ValidationGate:            r.Contract.ValidationGate,
		AuditFields: map[string]string{
			"tenant_id":            strings.TrimSpace(req.TenantID),
			"actor_user_id":        strings.TrimSpace(req.ActorUserID),
			"correlation_id":       strings.TrimSpace(req.CorrelationID),
			"validation_id":        strings.TrimSpace(req.ValidationID),
			"package_id":           packageID,
			"provider_id":          r.Contract.ProviderID,
			"phase":                r.Contract.Phase,
			"validation_mode":      r.Contract.ValidationMode,
			"target_system":        r.Contract.TargetSystem,
			"real_queue_write":     r.Contract.RealQueueWritePolicy,
			"provider_error_code":  normalizeExportMappingValue(req.ProviderErrorCode),
			"real_provider_status": r.Contract.RealProviderAPIStatus,
		},
	}

	if err := r.Contract.Validate(); err != nil {
		return decision, err
	}
	if err := validateMikroValidationRequest(req); err != nil {
		decision.Reason = MikroValidationDecisionInvalidPackage
		decision.Action = MikroValidationActionReject
		return decision, err
	}
	if containsForbiddenMappingField(req.InjectedFieldName) {
		decision.Reason = MikroValidationDecisionSecretDenied
		decision.Action = MikroValidationActionReject
		return decision, ErrMikroValidationSecretForbidden
	}
	if normalizeExportMappingValue(req.RequestedMode) == "PROVIDER_LIVE" {
		decision.Reason = MikroValidationDecisionLiveMode
		decision.Action = MikroValidationActionReject
		return decision, nil
	}
	if req.RealProviderAPIEnabled {
		decision.Reason = MikroValidationDecisionRealAPI
		decision.Action = MikroValidationActionReject
		return decision, nil
	}
	if req.RealFileDeliveryEnabled {
		decision.Reason = MikroValidationDecisionRealFile
		decision.Action = MikroValidationActionReject
		return decision, nil
	}
	if req.RealERPWriteEnabled {
		decision.Reason = MikroValidationDecisionRealERP
		decision.Action = MikroValidationActionReject
		return decision, nil
	}
	if req.RealDeliveryEnabled {
		decision.Reason = MikroValidationDecisionRealDelivery
		decision.Action = MikroValidationActionReject
		return decision, nil
	}
	if err := verifyMikroDryRunPackage(req.Package); err != nil {
		decision.Reason = MikroValidationDecisionInvalidPackage
		decision.Action = MikroValidationActionDLQ
		decision.SendToDLQ = true
		return decision, err
	}

	providerErrorCode := normalizeExportMappingValue(req.ProviderErrorCode)
	if providerErrorCode != "" {
		return r.evaluateProviderError(req, decision, providerErrorCode), nil
	}

	decision.Allowed = true
	decision.Reason = MikroValidationDecisionReady
	decision.Action = MikroValidationActionAccept
	decision.NextAttempt = normalizeAttempt(req.Attempt)
	return decision, nil
}

func (r MikroValidationRetryDLQRuntime) evaluateProviderError(req MikroValidationRequest, decision MikroValidationDecision, providerErrorCode string) MikroValidationDecision {
	mapping, ok := r.Contract.MappingForProviderError(providerErrorCode)
	if !ok {
		mapping = MikroProviderErrorMapping{
			ProviderErrorCode: providerErrorCode,
			Classification:    MikroErrorClassUnknownProvider,
			Retryable:         false,
			ManualReview:      true,
		}
	}

	currentAttempt := normalizeAttempt(req.Attempt)
	decision.ProviderErrorCode = providerErrorCode
	decision.ProviderErrorClass = mapping.Classification
	decision.Retryable = mapping.Retryable
	decision.NextAttempt = currentAttempt + 1

	if mapping.Retryable && currentAttempt < r.Contract.RetryPolicy.MaxAttempts {
		decision.Allowed = true
		decision.Reason = MikroValidationDecisionRetry
		decision.Action = MikroValidationActionRetry
		decision.RetryAllowed = true
		decision.BackoffSeconds = calculateMikroRetryBackoffSeconds(r.Contract.RetryPolicy, currentAttempt)
		return decision
	}

	if mapping.Retryable && currentAttempt >= r.Contract.RetryPolicy.MaxAttempts {
		decision.Allowed = true
		decision.Reason = MikroValidationDecisionDLQ
		decision.Action = MikroValidationActionDLQ
		decision.RetryAllowed = false
		decision.SendToDLQ = true
		return decision
	}

	if mapping.ManualReview {
		decision.Allowed = true
		decision.Reason = MikroValidationDecisionManualReview
		decision.Action = MikroValidationActionManualReview
		decision.ManualReview = true
		decision.RetryAllowed = false
		return decision
	}

	if mapping.DLQAfterRetryExhausted {
		decision.Allowed = true
		decision.Reason = MikroValidationDecisionDLQ
		decision.Action = MikroValidationActionDLQ
		decision.SendToDLQ = true
		decision.RetryAllowed = false
		return decision
	}

	decision.Allowed = true
	decision.Reason = MikroValidationDecisionManualReview
	decision.Action = MikroValidationActionManualReview
	decision.ManualReview = true
	return decision
}

func validateMikroValidationRequest(req MikroValidationRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return fmt.Errorf("%w: tenant_id is required", ErrInvalidMikroValidationRequest)
	}
	if strings.TrimSpace(req.ActorUserID) == "" {
		return fmt.Errorf("%w: actor_user_id is required", ErrInvalidMikroValidationRequest)
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return fmt.Errorf("%w: correlation_id is required", ErrInvalidMikroValidationRequest)
	}
	if strings.TrimSpace(req.ValidationID) == "" {
		return fmt.Errorf("%w: validation_id is required", ErrInvalidMikroValidationRequest)
	}
	if strings.TrimSpace(req.Package.Manifest.PackageID) == "" {
		return fmt.Errorf("%w: package_id is required", ErrInvalidMikroValidationRequest)
	}
	return nil
}

func normalizeAttempt(attempt int) int {
	if attempt <= 0 {
		return 1
	}
	return attempt
}

func calculateMikroRetryBackoffSeconds(policy MikroRetryPolicy, attempt int) int {
	normalizedAttempt := normalizeAttempt(attempt)
	backoff := policy.InitialBackoffSeconds
	for i := 1; i < normalizedAttempt; i++ {
		backoff *= 2
	}
	if backoff > policy.MaxBackoffSeconds {
		return policy.MaxBackoffSeconds
	}
	return backoff
}
