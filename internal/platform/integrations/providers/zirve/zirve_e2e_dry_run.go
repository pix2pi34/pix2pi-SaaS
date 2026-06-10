package zirve

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

const (
	ZirveE2EDryRunModuleCode = "FAZ_7_8Z_6"
	ZirveE2EDryRunMode       = "E2E_DRY_RUN_FLOW_ONLY"
	ZirveE2EDryRunStatus     = "READY_DRY_RUN_ONLY"
	ZirveE2EChainPolicy      = "FOUNDATION_TO_ADMIN_OPS_DRY_RUN_CHAIN"
	ZirveE2EEvidencePolicy   = "CHAIN_EVIDENCE_REQUIRED_FOR_EVERY_STEP"
)

type ZirveE2EDryRunRequest struct {
	TenantID             string
	ExportRunID          string
	DeliveryRunID        string
	ValidationRunID      string
	ReviewID             string
	CorrelationID        string
	RequestedBy          string
	ObservedErrorCode    ZirveValidationErrorCode
	ObservedErrorMessage string
	Attempt              int
	MaxAttempts          int
	Objects              []ZirveExportObject
	DryRun               bool
	RequestedAt          time.Time
}

type ZirveE2EDryRunStepStatus string

const (
	ZirveE2EStepPass    ZirveE2EDryRunStepStatus = "PASS"
	ZirveE2EStepSkipped ZirveE2EDryRunStepStatus = "SKIPPED"
)

type ZirveE2EDryRunStep struct {
	StepCode   string
	StepName   string
	Status     ZirveE2EDryRunStepStatus
	Evidence   string
	ModuleCode string
}

type ZirveE2EDryRunResult struct {
	ProviderID                        string
	ModuleCode                        string
	Mode                              string
	Status                            string
	ChainPolicy                       string
	EvidencePolicy                    string
	TenantID                          string
	ExportRunID                       string
	DeliveryRunID                     string
	ValidationRunID                   string
	ReviewID                          string
	CorrelationID                     string
	RequestedBy                       string
	ExportPackage                     ZirveExportPackage
	ImportDeliveryContract            ZirveImportDeliveryContract
	ValidationDecision                ZirveValidationRetryDLQDecision
	ManualReviewOpened                bool
	ManualReviewItem                  ZirveManualReviewItem
	Steps                             []ZirveE2EDryRunStep
	FinalOutcome                      ZirveValidationOutcome
	RealProviderAPIAllowed            bool
	RealFileDeliveryAllowed           bool
	RealDeliveryChannelAllowed        bool
	RealERPWriteAllowed               bool
	RealOperatorProviderActionAllowed bool
	CreatedAtUTC                      time.Time
}

type ZirveE2EDryRunRuntime struct {
	Identity ZirveProviderIdentity
}

func NewZirveE2EDryRunRuntime(identity ZirveProviderIdentity) ZirveE2EDryRunRuntime {
	if strings.TrimSpace(identity.ProviderID) == "" {
		identity = NewZirveProviderIdentity(time.Now().UTC())
	}

	return ZirveE2EDryRunRuntime{
		Identity: identity,
	}
}

func (r ZirveE2EDryRunRuntime) RunDryRunFlow(request ZirveE2EDryRunRequest) (ZirveE2EDryRunResult, error) {
	if err := r.Identity.Validate(); err != nil {
		return ZirveE2EDryRunResult{}, fmt.Errorf("zirve identity validation failed: %w", err)
	}

	normalized, err := normalizeZirveE2EDryRunRequest(request)
	if err != nil {
		return ZirveE2EDryRunResult{}, err
	}

	if r.Identity.CanUseRealProviderAPI() {
		return ZirveE2EDryRunResult{}, errors.New("real Zirve provider API must remain closed in FAZ 7-8Z.6")
	}
	if r.Identity.CanDeliverRealFile() {
		return ZirveE2EDryRunResult{}, errors.New("real Zirve file delivery must remain closed in FAZ 7-8Z.6")
	}
	if r.Identity.CanWriteERP() {
		return ZirveE2EDryRunResult{}, errors.New("real ERP write must remain closed in FAZ 7-8Z.6")
	}
	if r.Identity.CanRunRealOperatorProviderAction() {
		return ZirveE2EDryRunResult{}, errors.New("real operator provider action must remain closed in FAZ 7-8Z.6")
	}

	steps := []ZirveE2EDryRunStep{
		{
			StepCode:   "7-8Z.6.1",
			StepName:   "Zirve foundation identity validated",
			Status:     ZirveE2EStepPass,
			Evidence:   "provider identity validation passed",
			ModuleCode: ModuleCode,
		},
	}

	exportBuilder := NewZirveExportPackageBuilder(r.Identity)
	exportPackage, err := exportBuilder.BuildDryRunExportPackage(ZirveExportPackageRequest{
		TenantID:      normalized.TenantID,
		ExportRunID:   normalized.ExportRunID,
		CorrelationID: normalized.CorrelationID,
		RequestedBy:   normalized.RequestedBy,
		Direction:     DirectionPix2piToZirve,
		DeliveryMode:  DeliveryModeFilePackageDryRun,
		DryRun:        true,
		RequestedAt:   normalized.RequestedAt,
		Objects:       normalized.Objects,
	})
	if err != nil {
		return ZirveE2EDryRunResult{}, fmt.Errorf("zirve file generation step failed: %w", err)
	}
	steps = append(steps, ZirveE2EDryRunStep{
		StepCode:   "7-8Z.6.2",
		StepName:   "Zirve file generation dry-run package built",
		Status:     ZirveE2EStepPass,
		Evidence:   fmt.Sprintf("artifact_count=%d target=%s", len(exportPackage.Artifacts), exportPackage.TargetSystem),
		ModuleCode: ZirveFileGenerationModuleCode,
	})

	deliveryBuilder := NewZirveImportDeliveryContractBuilder(r.Identity)
	deliveryContract, err := deliveryBuilder.BuildDryRunImportDeliveryContract(ZirveImportDeliveryRequest{
		TenantID:      normalized.TenantID,
		ExportRunID:   normalized.ExportRunID,
		DeliveryRunID: normalized.DeliveryRunID,
		CorrelationID: normalized.CorrelationID,
		RequestedBy:   normalized.RequestedBy,
		Package:       exportPackage,
		Channel:       ZirveDeliveryChannelLocalPackage,
		DryRun:        true,
		RequestedAt:   normalized.RequestedAt,
	})
	if err != nil {
		return ZirveE2EDryRunResult{}, fmt.Errorf("zirve import delivery contract step failed: %w", err)
	}
	steps = append(steps, ZirveE2EDryRunStep{
		StepCode:   "7-8Z.6.3",
		StepName:   "Zirve import delivery contract built",
		Status:     ZirveE2EStepPass,
		Evidence:   fmt.Sprintf("contract_status=%s channel=%s", deliveryContract.ContractStatus, deliveryContract.DeliveryChannel),
		ModuleCode: ZirveImportDeliveryModuleCode,
	})

	validationRuntime := NewZirveValidationRetryDLQRuntime(r.Identity)
	validationDecision, err := validationRuntime.BuildDryRunValidationRetryDLQDecision(ZirveValidationRetryDLQRequest{
		TenantID:             normalized.TenantID,
		ExportRunID:          normalized.ExportRunID,
		DeliveryRunID:        normalized.DeliveryRunID,
		ValidationRunID:      normalized.ValidationRunID,
		CorrelationID:        normalized.CorrelationID,
		RequestedBy:          normalized.RequestedBy,
		DeliveryContract:     deliveryContract,
		ObservedErrorCode:    normalized.ObservedErrorCode,
		ObservedErrorMessage: normalized.ObservedErrorMessage,
		Attempt:              normalized.Attempt,
		MaxAttempts:          normalized.MaxAttempts,
		DryRun:               true,
		RequestedAt:          normalized.RequestedAt,
	})
	if err != nil {
		return ZirveE2EDryRunResult{}, fmt.Errorf("zirve validation retry-dlq step failed: %w", err)
	}
	steps = append(steps, ZirveE2EDryRunStep{
		StepCode:   "7-8Z.6.4",
		StepName:   "Zirve validation retry-DLQ decision built",
		Status:     ZirveE2EStepPass,
		Evidence:   fmt.Sprintf("outcome=%s error_code=%s", validationDecision.Outcome, validationDecision.ErrorCode),
		ModuleCode: ZirveValidationRetryDLQModuleCode,
	})

	adminRuntime := NewZirveAdminOpsRuntime(r.Identity)
	manualReviewOpened := false
	manualReviewItem := ZirveManualReviewItem{}

	if isZirveE2EManualReviewEligible(validationDecision) {
		manualReviewItem, err = adminRuntime.OpenManualReview(
			validationDecision,
			normalized.ReviewID,
			normalized.RequestedBy,
			normalized.RequestedAt,
		)
		if err != nil {
			return ZirveE2EDryRunResult{}, fmt.Errorf("zirve admin ops manual review step failed: %w", err)
		}
		manualReviewOpened = true
		steps = append(steps, ZirveE2EDryRunStep{
			StepCode:   "7-8Z.6.5",
			StepName:   "Zirve admin ops manual review opened",
			Status:     ZirveE2EStepPass,
			Evidence:   fmt.Sprintf("review_id=%s priority=%s status=%s", manualReviewItem.ReviewID, manualReviewItem.Priority, manualReviewItem.Status),
			ModuleCode: ZirveAdminOpsModuleCode,
		})
	} else {
		steps = append(steps, ZirveE2EDryRunStep{
			StepCode:   "7-8Z.6.5",
			StepName:   "Zirve admin ops manual review not required",
			Status:     ZirveE2EStepSkipped,
			Evidence:   fmt.Sprintf("outcome=%s", validationDecision.Outcome),
			ModuleCode: ZirveAdminOpsModuleCode,
		})
	}

	steps = append(steps, ZirveE2EDryRunStep{
		StepCode:   "7-8Z.6.6",
		StepName:   "Zirve E2E dry-run final guard verified",
		Status:     ZirveE2EStepPass,
		Evidence:   "real provider API/file delivery/delivery channel/ERP write/operator action remained closed",
		ModuleCode: ZirveE2EDryRunModuleCode,
	})

	return ZirveE2EDryRunResult{
		ProviderID:                        ProviderID,
		ModuleCode:                        ZirveE2EDryRunModuleCode,
		Mode:                              ZirveE2EDryRunMode,
		Status:                            ZirveE2EDryRunStatus,
		ChainPolicy:                       ZirveE2EChainPolicy,
		EvidencePolicy:                    ZirveE2EEvidencePolicy,
		TenantID:                          normalized.TenantID,
		ExportRunID:                       normalized.ExportRunID,
		DeliveryRunID:                     normalized.DeliveryRunID,
		ValidationRunID:                   normalized.ValidationRunID,
		ReviewID:                          normalized.ReviewID,
		CorrelationID:                     normalized.CorrelationID,
		RequestedBy:                       normalized.RequestedBy,
		ExportPackage:                     exportPackage,
		ImportDeliveryContract:            deliveryContract,
		ValidationDecision:                validationDecision,
		ManualReviewOpened:                manualReviewOpened,
		ManualReviewItem:                  manualReviewItem,
		Steps:                             steps,
		FinalOutcome:                      validationDecision.Outcome,
		RealProviderAPIAllowed:            false,
		RealFileDeliveryAllowed:           false,
		RealDeliveryChannelAllowed:        false,
		RealERPWriteAllowed:               false,
		RealOperatorProviderActionAllowed: false,
		CreatedAtUTC:                      normalized.RequestedAt.UTC(),
	}, nil
}

func normalizeZirveE2EDryRunRequest(request ZirveE2EDryRunRequest) (ZirveE2EDryRunRequest, error) {
	request.TenantID = strings.TrimSpace(request.TenantID)
	request.ExportRunID = strings.TrimSpace(request.ExportRunID)
	request.DeliveryRunID = strings.TrimSpace(request.DeliveryRunID)
	request.ValidationRunID = strings.TrimSpace(request.ValidationRunID)
	request.ReviewID = strings.TrimSpace(request.ReviewID)
	request.CorrelationID = strings.TrimSpace(request.CorrelationID)
	request.RequestedBy = strings.TrimSpace(request.RequestedBy)
	request.ObservedErrorMessage = strings.TrimSpace(request.ObservedErrorMessage)

	if request.TenantID == "" {
		return request, errors.New("tenant id is required for Zirve E2E dry-run flow")
	}
	if request.ExportRunID == "" {
		return request, errors.New("export run id is required for Zirve E2E dry-run flow")
	}
	if request.DeliveryRunID == "" {
		return request, errors.New("delivery run id is required for Zirve E2E dry-run flow")
	}
	if request.ValidationRunID == "" {
		return request, errors.New("validation run id is required for Zirve E2E dry-run flow")
	}
	if request.ReviewID == "" {
		return request, errors.New("review id is required for Zirve E2E dry-run flow")
	}
	if request.CorrelationID == "" {
		return request, errors.New("correlation id is required for Zirve E2E dry-run flow")
	}
	if request.RequestedBy == "" {
		return request, errors.New("requested by is required for Zirve E2E dry-run flow")
	}
	if !request.DryRun {
		return request, errors.New("Zirve E2E flow is dry-run only in FAZ 7-8Z.6")
	}
	if len(request.Objects) == 0 {
		return request, errors.New("at least one export object is required for Zirve E2E dry-run flow")
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

func isZirveE2EManualReviewEligible(decision ZirveValidationRetryDLQDecision) bool {
	return decision.Outcome == ZirveValidationOutcomeDLQ ||
		decision.Outcome == ZirveValidationOutcomeManualReview ||
		decision.Outcome == ZirveValidationOutcomeDeny ||
		decision.ManualReview ||
		decision.SendToDLQ
}
