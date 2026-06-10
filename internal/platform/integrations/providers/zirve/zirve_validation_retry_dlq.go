package zirve

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

const (
	ZirveValidationRetryDLQModuleCode = "FAZ_7_8Z_4"
	ZirveValidationRetryDLQMode       = "VALIDATION_RETRY_DLQ_DRY_RUN_ONLY"
	ZirveValidationRetryDLQStatus     = "READY_DRY_RUN_ONLY"
	ZirveValidationPolicy             = "VALIDATE_BEFORE_DELIVERY_AND_ROUTE_FAILURES"
	ZirveRetryPolicy                  = "MAX_ATTEMPT_THEN_DLQ"
	ZirveDLQPolicy                    = "DLQ_FOR_EXHAUSTED_RETRY_OR_BLOCKER"
	ZirveManualReviewPolicy           = "MANUAL_REVIEW_FOR_BUSINESS_OR_SCHEMA_FAILURE"
)

type ZirveValidationSeverity string

const (
	ZirveSeverityInfo    ZirveValidationSeverity = "INFO"
	ZirveSeverityWarn    ZirveValidationSeverity = "WARN"
	ZirveSeverityError   ZirveValidationSeverity = "ERROR"
	ZirveSeverityBlocker ZirveValidationSeverity = "BLOCKER"
)

type ZirveValidationErrorCode string

const (
	ZirveErrNone                   ZirveValidationErrorCode = ""
	ZirveErrTenantRequired         ZirveValidationErrorCode = "ZIRVE_ERR_TENANT_REQUIRED"
	ZirveErrCorrelationRequired    ZirveValidationErrorCode = "ZIRVE_ERR_CORRELATION_REQUIRED"
	ZirveErrPackageMissing         ZirveValidationErrorCode = "ZIRVE_ERR_PACKAGE_MISSING"
	ZirveErrPackageArtifactMissing ZirveValidationErrorCode = "ZIRVE_ERR_PACKAGE_ARTIFACT_MISSING"
	ZirveErrObjectUnsupported      ZirveValidationErrorCode = "ZIRVE_ERR_OBJECT_UNSUPPORTED"
	ZirveErrSchemaMismatch         ZirveValidationErrorCode = "ZIRVE_ERR_SCHEMA_MISMATCH"
	ZirveErrProviderTemporary      ZirveValidationErrorCode = "ZIRVE_ERR_PROVIDER_TEMPORARY"
	ZirveErrProviderRateLimit      ZirveValidationErrorCode = "ZIRVE_ERR_PROVIDER_RATE_LIMIT"
	ZirveErrProviderAuth           ZirveValidationErrorCode = "ZIRVE_ERR_PROVIDER_AUTH"
	ZirveErrRealDeliveryAttempted  ZirveValidationErrorCode = "ZIRVE_ERR_REAL_DELIVERY_ATTEMPTED"
	ZirveErrUnknown                ZirveValidationErrorCode = "ZIRVE_ERR_UNKNOWN"
)

type ZirveValidationOutcome string

const (
	ZirveValidationOutcomePass         ZirveValidationOutcome = "PASS"
	ZirveValidationOutcomeRetry        ZirveValidationOutcome = "RETRY"
	ZirveValidationOutcomeDLQ          ZirveValidationOutcome = "DLQ"
	ZirveValidationOutcomeManualReview ZirveValidationOutcome = "MANUAL_REVIEW"
	ZirveValidationOutcomeDeny         ZirveValidationOutcome = "DENY"
)

type ZirveRetryCategory string

const (
	ZirveRetryCategoryNone          ZirveRetryCategory = "NONE"
	ZirveRetryCategoryRetryable     ZirveRetryCategory = "RETRYABLE"
	ZirveRetryCategoryNonRetryable  ZirveRetryCategory = "NON_RETRYABLE"
	ZirveRetryCategoryManualReview  ZirveRetryCategory = "MANUAL_REVIEW"
	ZirveRetryCategorySecurityBlock ZirveRetryCategory = "SECURITY_BLOCK"
)

type ZirveValidationIssue struct {
	Code           ZirveValidationErrorCode
	Severity       ZirveValidationSeverity
	Message        string
	RetryCategory  ZirveRetryCategory
	Retryable      bool
	SendToDLQ      bool
	ManualReview   bool
	RequiredAction string
}

type ZirveValidationRetryDLQRequest struct {
	TenantID             string
	ExportRunID          string
	DeliveryRunID        string
	ValidationRunID      string
	CorrelationID        string
	RequestedBy          string
	DeliveryContract     ZirveImportDeliveryContract
	ObservedErrorCode    ZirveValidationErrorCode
	ObservedErrorMessage string
	Attempt              int
	MaxAttempts          int
	DryRun               bool
	RequestedAt          time.Time
}

type ZirveValidationRetryDLQDecision struct {
	ProviderID                        string
	ModuleCode                        string
	Mode                              string
	Status                            string
	ValidationPolicy                  string
	RetryPolicy                       string
	DLQPolicy                         string
	ManualReviewPolicy                string
	TenantID                          string
	ExportRunID                       string
	DeliveryRunID                     string
	ValidationRunID                   string
	CorrelationID                     string
	Attempt                           int
	MaxAttempts                       int
	Outcome                           ZirveValidationOutcome
	ErrorCode                         ZirveValidationErrorCode
	ErrorMessage                      string
	Retryable                         bool
	SendToDLQ                         bool
	ManualReview                      bool
	RequiredAction                    string
	Issues                            []ZirveValidationIssue
	AuditDecision                     OperationDecision
	RealProviderAPIAllowed            bool
	RealFileDeliveryAllowed           bool
	RealDeliveryChannelAllowed        bool
	RealERPWriteAllowed               bool
	RealOperatorProviderActionAllowed bool
	CreatedAtUTC                      time.Time
}

type ZirveValidationRetryDLQRuntime struct {
	Identity ZirveProviderIdentity
}

func NewZirveValidationRetryDLQRuntime(identity ZirveProviderIdentity) ZirveValidationRetryDLQRuntime {
	if strings.TrimSpace(identity.ProviderID) == "" {
		identity = NewZirveProviderIdentity(time.Now().UTC())
	}

	return ZirveValidationRetryDLQRuntime{
		Identity: identity,
	}
}

func (r ZirveValidationRetryDLQRuntime) BuildDryRunValidationRetryDLQDecision(request ZirveValidationRetryDLQRequest) (ZirveValidationRetryDLQDecision, error) {
	if err := r.Identity.Validate(); err != nil {
		return ZirveValidationRetryDLQDecision{}, fmt.Errorf("zirve identity validation failed: %w", err)
	}

	normalized, err := normalizeZirveValidationRetryDLQRequest(request)
	if err != nil {
		return ZirveValidationRetryDLQDecision{}, err
	}

	if err := validateZirveImportDeliveryContractForValidation(normalized); err != nil {
		return ZirveValidationRetryDLQDecision{}, err
	}

	auditDecision := decideZirveValidationRetryDLQOperation("DRY_RUN_VALIDATION_RETRY_DLQ_DECISION")
	if !auditDecision.Allowed {
		return ZirveValidationRetryDLQDecision{}, fmt.Errorf("zirve validation retry-dlq operation denied: %s", auditDecision.Reason)
	}

	if r.Identity.CanUseRealProviderAPI() {
		return ZirveValidationRetryDLQDecision{}, errors.New("real Zirve provider API must remain closed in FAZ 7-8Z.4")
	}
	if r.Identity.CanDeliverRealFile() {
		return ZirveValidationRetryDLQDecision{}, errors.New("real Zirve file delivery must remain closed in FAZ 7-8Z.4")
	}
	if r.Identity.CanWriteERP() {
		return ZirveValidationRetryDLQDecision{}, errors.New("real ERP write must remain closed in FAZ 7-8Z.4")
	}

	issue := mapZirveValidationIssue(normalized)
	outcome := decideZirveValidationOutcome(normalized, issue)

	issues := []ZirveValidationIssue{}
	if issue.Code != ZirveErrNone {
		issues = append(issues, issue)
	}

	return ZirveValidationRetryDLQDecision{
		ProviderID:                        ProviderID,
		ModuleCode:                        ZirveValidationRetryDLQModuleCode,
		Mode:                              ZirveValidationRetryDLQMode,
		Status:                            ZirveValidationRetryDLQStatus,
		ValidationPolicy:                  ZirveValidationPolicy,
		RetryPolicy:                       ZirveRetryPolicy,
		DLQPolicy:                         ZirveDLQPolicy,
		ManualReviewPolicy:                ZirveManualReviewPolicy,
		TenantID:                          normalized.TenantID,
		ExportRunID:                       normalized.ExportRunID,
		DeliveryRunID:                     normalized.DeliveryRunID,
		ValidationRunID:                   normalized.ValidationRunID,
		CorrelationID:                     normalized.CorrelationID,
		Attempt:                           normalized.Attempt,
		MaxAttempts:                       normalized.MaxAttempts,
		Outcome:                           outcome,
		ErrorCode:                         issue.Code,
		ErrorMessage:                      issue.Message,
		Retryable:                         issue.Retryable && outcome == ZirveValidationOutcomeRetry,
		SendToDLQ:                         outcome == ZirveValidationOutcomeDLQ || issue.SendToDLQ,
		ManualReview:                      outcome == ZirveValidationOutcomeManualReview || issue.ManualReview,
		RequiredAction:                    issue.RequiredAction,
		Issues:                            issues,
		AuditDecision:                     auditDecision,
		RealProviderAPIAllowed:            false,
		RealFileDeliveryAllowed:           false,
		RealDeliveryChannelAllowed:        false,
		RealERPWriteAllowed:               false,
		RealOperatorProviderActionAllowed: false,
		CreatedAtUTC:                      normalized.RequestedAt.UTC(),
	}, nil
}

func normalizeZirveValidationRetryDLQRequest(request ZirveValidationRetryDLQRequest) (ZirveValidationRetryDLQRequest, error) {
	request.TenantID = strings.TrimSpace(request.TenantID)
	request.ExportRunID = strings.TrimSpace(request.ExportRunID)
	request.DeliveryRunID = strings.TrimSpace(request.DeliveryRunID)
	request.ValidationRunID = strings.TrimSpace(request.ValidationRunID)
	request.CorrelationID = strings.TrimSpace(request.CorrelationID)
	request.RequestedBy = strings.TrimSpace(request.RequestedBy)
	request.ObservedErrorMessage = strings.TrimSpace(request.ObservedErrorMessage)

	if request.TenantID == "" {
		return request, errors.New("tenant id is required for Zirve validation retry-dlq")
	}
	if request.ExportRunID == "" {
		return request, errors.New("export run id is required for Zirve validation retry-dlq")
	}
	if request.DeliveryRunID == "" {
		return request, errors.New("delivery run id is required for Zirve validation retry-dlq")
	}
	if request.ValidationRunID == "" {
		return request, errors.New("validation run id is required for Zirve validation retry-dlq")
	}
	if request.CorrelationID == "" {
		return request, errors.New("correlation id is required for Zirve validation retry-dlq")
	}
	if request.RequestedBy == "" {
		return request, errors.New("requested by is required for Zirve validation retry-dlq")
	}
	if !request.DryRun {
		return request, errors.New("Zirve validation retry-dlq is dry-run only in FAZ 7-8Z.4")
	}

	if request.Attempt <= 0 {
		request.Attempt = 1
	}
	if request.MaxAttempts <= 0 {
		request.MaxAttempts = 3
	}
	if request.Attempt > request.MaxAttempts {
		return request, errors.New("attempt cannot be greater than max attempts")
	}
	if request.RequestedAt.IsZero() {
		request.RequestedAt = time.Now().UTC()
	}

	return request, nil
}

func validateZirveImportDeliveryContractForValidation(request ZirveValidationRetryDLQRequest) error {
	contract := request.DeliveryContract

	if strings.TrimSpace(contract.ProviderID) != ProviderID {
		return fmt.Errorf("delivery contract provider id must be %s", ProviderID)
	}
	if strings.TrimSpace(contract.ModuleCode) != ZirveImportDeliveryModuleCode {
		return fmt.Errorf("delivery contract module code must be %s", ZirveImportDeliveryModuleCode)
	}
	if strings.TrimSpace(contract.ContractMode) != ZirveImportDeliveryContractMode {
		return fmt.Errorf("delivery contract mode must be %s", ZirveImportDeliveryContractMode)
	}
	if strings.TrimSpace(contract.ContractStatus) != ZirveImportDeliveryContractStatus {
		return fmt.Errorf("delivery contract status must be %s", ZirveImportDeliveryContractStatus)
	}
	if strings.TrimSpace(contract.TargetSystem) != ZirveImportDeliveryTargetSystem {
		return fmt.Errorf("delivery contract target system must be %s", ZirveImportDeliveryTargetSystem)
	}
	if strings.TrimSpace(contract.TenantID) != request.TenantID {
		return errors.New("validation tenant id must match delivery contract tenant id")
	}
	if strings.TrimSpace(contract.ExportRunID) != request.ExportRunID {
		return errors.New("validation export run id must match delivery contract export run id")
	}
	if strings.TrimSpace(contract.DeliveryRunID) != request.DeliveryRunID {
		return errors.New("validation delivery run id must match delivery contract delivery run id")
	}
	if !contract.DryRun {
		return errors.New("only dry-run import delivery contracts can be validated in FAZ 7-8Z.4")
	}
	if contract.RealProviderAPIAllowed {
		return errors.New("delivery contract real provider API must be closed")
	}
	if contract.RealFileDeliveryAllowed {
		return errors.New("delivery contract real file delivery must be closed")
	}
	if contract.RealDeliveryChannelAllowed {
		return errors.New("delivery contract real delivery channel must be closed")
	}
	if contract.RealERPWriteAllowed {
		return errors.New("delivery contract real ERP write must be closed")
	}
	if contract.RealOperatorProviderActionAllowed {
		return errors.New("delivery contract real operator provider action must be closed")
	}
	if contract.PackageArtifactCount <= 0 {
		return errors.New("delivery contract package artifact count is required")
	}
	if len(contract.PackageFingerprintSHA256) != 64 {
		return errors.New("delivery contract package fingerprint sha256 is required")
	}
	if len(contract.Artifacts) == 0 {
		return errors.New("delivery contract artifacts are required")
	}

	return nil
}

func mapZirveValidationIssue(request ZirveValidationRetryDLQRequest) ZirveValidationIssue {
	code := request.ObservedErrorCode

	if code == ZirveErrNone {
		return ZirveValidationIssue{
			Code:           ZirveErrNone,
			Severity:       ZirveSeverityInfo,
			Message:        "validation passed",
			RetryCategory:  ZirveRetryCategoryNone,
			Retryable:      false,
			SendToDLQ:      false,
			ManualReview:   false,
			RequiredAction: "none",
		}
	}

	message := request.ObservedErrorMessage
	if message == "" {
		message = string(code)
	}

	switch code {
	case ZirveErrProviderTemporary, ZirveErrProviderRateLimit:
		return ZirveValidationIssue{
			Code:           code,
			Severity:       ZirveSeverityWarn,
			Message:        message,
			RetryCategory:  ZirveRetryCategoryRetryable,
			Retryable:      true,
			SendToDLQ:      false,
			ManualReview:   false,
			RequiredAction: "retry_until_max_attempt_then_dlq",
		}
	case ZirveErrSchemaMismatch, ZirveErrObjectUnsupported, ZirveErrProviderAuth:
		return ZirveValidationIssue{
			Code:           code,
			Severity:       ZirveSeverityError,
			Message:        message,
			RetryCategory:  ZirveRetryCategoryManualReview,
			Retryable:      false,
			SendToDLQ:      false,
			ManualReview:   true,
			RequiredAction: "route_to_manual_review",
		}
	case ZirveErrPackageMissing, ZirveErrPackageArtifactMissing:
		return ZirveValidationIssue{
			Code:           code,
			Severity:       ZirveSeverityBlocker,
			Message:        message,
			RetryCategory:  ZirveRetryCategoryNonRetryable,
			Retryable:      false,
			SendToDLQ:      true,
			ManualReview:   true,
			RequiredAction: "send_to_dlq_and_manual_review",
		}
	case ZirveErrRealDeliveryAttempted:
		return ZirveValidationIssue{
			Code:           code,
			Severity:       ZirveSeverityBlocker,
			Message:        message,
			RetryCategory:  ZirveRetryCategorySecurityBlock,
			Retryable:      false,
			SendToDLQ:      true,
			ManualReview:   true,
			RequiredAction: "deny_real_operation_and_escalate",
		}
	case ZirveErrTenantRequired, ZirveErrCorrelationRequired:
		return ZirveValidationIssue{
			Code:           code,
			Severity:       ZirveSeverityBlocker,
			Message:        message,
			RetryCategory:  ZirveRetryCategoryNonRetryable,
			Retryable:      false,
			SendToDLQ:      true,
			ManualReview:   false,
			RequiredAction: "fix_request_contract",
		}
	default:
		return ZirveValidationIssue{
			Code:           ZirveErrUnknown,
			Severity:       ZirveSeverityError,
			Message:        message,
			RetryCategory:  ZirveRetryCategoryManualReview,
			Retryable:      false,
			SendToDLQ:      false,
			ManualReview:   true,
			RequiredAction: "manual_triage_unknown_error",
		}
	}
}

func decideZirveValidationOutcome(request ZirveValidationRetryDLQRequest, issue ZirveValidationIssue) ZirveValidationOutcome {
	if issue.Code == ZirveErrNone {
		return ZirveValidationOutcomePass
	}

	if issue.Code == ZirveErrRealDeliveryAttempted {
		return ZirveValidationOutcomeDeny
	}

	if issue.Retryable {
		if request.Attempt < request.MaxAttempts {
			return ZirveValidationOutcomeRetry
		}
		return ZirveValidationOutcomeDLQ
	}

	if issue.SendToDLQ {
		return ZirveValidationOutcomeDLQ
	}

	if issue.ManualReview {
		return ZirveValidationOutcomeManualReview
	}

	return ZirveValidationOutcomeManualReview
}

func decideZirveValidationRetryDLQOperation(operationCode string) OperationDecision {
	operationCode = strings.TrimSpace(operationCode)

	if operationCode == "DRY_RUN_VALIDATION_RETRY_DLQ_DECISION" {
		return OperationDecision{
			OperationCode: operationCode,
			Allowed:       true,
			Reason:        "dry-run validation retry-dlq decision is allowed without external delivery",
			RequiredGate:  "VALIDATION_RETRY_DLQ_ONLY",
		}
	}

	return OperationDecision{
		OperationCode: operationCode,
		Allowed:       false,
		Reason:        "real validation side effects are closed until provider live module",
		RequiredGate:  HandoffGateStatus,
	}
}
