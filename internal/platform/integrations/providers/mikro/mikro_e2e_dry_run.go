package mikro

import (
	"errors"
	"fmt"
	"strings"
)

const (
	MikroE2EDryRunPhase          = "FAZ_7_8M_6"
	MikroE2EDryRunModule         = "MIKRO_E2E_DRY_RUN_FLOW"
	MikroE2EDryRunModuleName     = "Mikro E2E Dry-Run Flow / Connector Closure Preparation"
	MikroE2EDryRunMode           = "E2E_DRY_RUN_ONLY"
	MikroE2EDryRunDirection      = "PIX2PI_TO_MIKRO"
	MikroE2EDryRunSourceSystem   = "PIX2PI_ERP"
	MikroE2EDryRunTargetSystem   = "MIKRO_ACCOUNTING_IMPORT_DRY_RUN"
	MikroE2EDryRunGate           = "READY_AFTER_TEST_AND_AUDIT_PASS"
	MikroE2EChainStatusReady     = "READY"
	MikroE2EClosurePrepReady     = "READY"
	MikroE2ERealQueueWritePolicy = "NO_REAL_QUEUE_WRITE_IN_THIS_PHASE"

	MikroE2EStepFoundationValidation = "FOUNDATION_CONTRACT_VALIDATION"
	MikroE2EStepExportMapping        = "EXPORT_MAPPING_CONTRACT_VALIDATION"
	MikroE2EStepFileGeneration       = "FILE_GENERATION_DRY_RUN_PACKAGE_BUILD"
	MikroE2EStepImportDelivery       = "IMPORT_DELIVERY_DRY_RUN_RECEIPT"
	MikroE2EStepValidationRetryDLQ   = "VALIDATION_RETRY_DLQ_DECISION"
	MikroE2EStepAdminOps             = "ADMIN_OPS_MANUAL_REVIEW_BRIDGE"
	MikroE2EStepOperatorAction       = "OPERATOR_ACTION_DRY_RUN_EVALUATION"

	MikroE2EDecisionReady              = "MIKRO_E2E_DRY_RUN_FLOW_READY"
	MikroE2EDecisionManualReviewReady  = "MIKRO_E2E_MANUAL_REVIEW_FLOW_READY"
	MikroE2EDecisionRetryReady         = "MIKRO_E2E_RETRY_FLOW_READY"
	MikroE2EDecisionDLQReady           = "MIKRO_E2E_DLQ_FLOW_READY"
	MikroE2EDecisionInvalidInput       = "MIKRO_E2E_INPUT_INVALID"
	MikroE2EDecisionSecretDenied       = "MIKRO_E2E_SECRET_FIELD_FORBIDDEN"
	MikroE2EDecisionRealProviderAPI    = "MIKRO_E2E_REAL_PROVIDER_API_CLOSED"
	MikroE2EDecisionRealFileDelivery   = "MIKRO_E2E_REAL_FILE_DELIVERY_CLOSED"
	MikroE2EDecisionRealERPWrite       = "MIKRO_E2E_REAL_ERP_WRITE_CLOSED"
	MikroE2EDecisionRealDelivery       = "MIKRO_E2E_REAL_DELIVERY_CHANNEL_CLOSED"
	MikroE2EDecisionRealProviderAction = "MIKRO_E2E_REAL_OPERATOR_PROVIDER_ACTION_CLOSED"
	MikroE2EDecisionProviderLiveClosed = "MIKRO_E2E_PROVIDER_LIVE_MODE_CLOSED"
)

var (
	ErrInvalidMikroE2EDryRunContract = errors.New("invalid mikro e2e dry-run contract")
	ErrInvalidMikroE2EDryRunRequest  = errors.New("invalid mikro e2e dry-run request")
	ErrMikroE2EDryRunSecretForbidden = errors.New("mikro e2e dry-run secret field is forbidden")
)

type MikroE2EDryRunContract struct {
	Phase                            string
	Module                           string
	ModuleName                       string
	ProviderID                       string
	ProviderName                     string
	ProviderCategory                 string
	E2EMode                          string
	Direction                        string
	SourceSystem                     string
	TargetSystem                     string
	E2EGate                          string
	ChainStatus                      string
	ClosurePreparationStatus         string
	RealQueueWritePolicy             string
	RealProviderAPIStatus            string
	RealFileDeliveryStatus           string
	RealERPWriteStatus               string
	RealDeliveryChannelStatus        string
	RealOperatorProviderActionStatus string
	ChainSteps                       []string
	RequiredContextFields            []string
	ForbiddenFieldLabels             []string
}

type MikroE2EDryRunRequest struct {
	TenantID                          string
	ActorUserID                       string
	CorrelationID                     string
	PackageID                         string
	DeliveryID                        string
	ValidationID                      string
	ReviewID                          string
	ERPObjectType                     string
	DeliveryChannel                   string
	RequestedMode                     string
	ProviderErrorCode                 string
	OperatorAction                    string
	OperatorNote                      string
	InjectedFieldName                 string
	Records                           []MikroDryRunPackageRecord
	RealProviderAPIEnabled            bool
	RealFileDeliveryEnabled           bool
	RealERPWriteEnabled               bool
	RealDeliveryEnabled               bool
	RealOperatorProviderActionEnabled bool
}

type MikroE2EDryRunResult struct {
	Phase                      string
	Module                     string
	ProviderID                 string
	ProviderName               string
	PackageID                  string
	DeliveryID                 string
	ValidationID               string
	ReviewID                   string
	ERPObjectType              string
	MikroObjectType            string
	FinalAction                string
	FinalReason                string
	FoundationValidated        bool
	MappingValidated           bool
	PackageBuilt               bool
	DeliveryReceiptCreated     bool
	ValidationEvaluated        bool
	AdminOpsEvaluated          bool
	ManualReviewItemCreated    bool
	OperatorActionEvaluated    bool
	DryRunPackage              MikroDryRunPackage
	DeliveryReceipt            MikroImportDeliveryReceipt
	ValidationDecision         MikroValidationDecision
	ManualReviewItem           MikroManualReviewItem
	OperatorActionDecision     MikroAdminOpsDecision
	RealExternalOperationCount int
}

type MikroE2EDryRunDecision struct {
	Allowed                          bool
	Phase                            string
	Module                           string
	ProviderID                       string
	ProviderName                     string
	PackageID                        string
	DeliveryID                       string
	ValidationID                     string
	ReviewID                         string
	ERPObjectType                    string
	MikroObjectType                  string
	E2EMode                          string
	Direction                        string
	TargetSystem                     string
	Reason                           string
	FinalAction                      string
	ChainStatus                      string
	ClosurePreparationStatus         string
	RealQueueWritePolicy             string
	RealProviderAPIStatus            string
	RealFileDeliveryStatus           string
	RealERPWriteStatus               string
	RealDeliveryChannelStatus        string
	RealOperatorProviderActionStatus string
	ExecutedSteps                    []string
	AuditFields                      map[string]string
}

type MikroE2EDryRunRuntime struct {
	Contract MikroE2EDryRunContract
}

func NewMikroE2EDryRunContract() MikroE2EDryRunContract {
	return MikroE2EDryRunContract{
		Phase:                            MikroE2EDryRunPhase,
		Module:                           MikroE2EDryRunModule,
		ModuleName:                       MikroE2EDryRunModuleName,
		ProviderID:                       ProviderID,
		ProviderName:                     ProviderName,
		ProviderCategory:                 ProviderCategory,
		E2EMode:                          MikroE2EDryRunMode,
		Direction:                        MikroE2EDryRunDirection,
		SourceSystem:                     MikroE2EDryRunSourceSystem,
		TargetSystem:                     MikroE2EDryRunTargetSystem,
		E2EGate:                          MikroE2EDryRunGate,
		ChainStatus:                      MikroE2EChainStatusReady,
		ClosurePreparationStatus:         MikroE2EClosurePrepReady,
		RealQueueWritePolicy:             MikroE2ERealQueueWritePolicy,
		RealProviderAPIStatus:            MikroRealProviderAPIStatus,
		RealFileDeliveryStatus:           MikroRealFileDeliveryStatus,
		RealERPWriteStatus:               MikroRealERPWriteStatus,
		RealDeliveryChannelStatus:        MikroRealDeliveryChannelStatus,
		RealOperatorProviderActionStatus: MikroRealOperatorProviderActionStatus,
		ChainSteps: []string{
			MikroE2EStepFoundationValidation,
			MikroE2EStepExportMapping,
			MikroE2EStepFileGeneration,
			MikroE2EStepImportDelivery,
			MikroE2EStepValidationRetryDLQ,
			MikroE2EStepAdminOps,
			MikroE2EStepOperatorAction,
		},
		RequiredContextFields: []string{
			"tenant_id",
			"actor_user_id",
			"correlation_id",
			"package_id",
			"delivery_id",
			"validation_id",
			"review_id",
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

func NewMikroE2EDryRunRuntime() MikroE2EDryRunRuntime {
	return MikroE2EDryRunRuntime{
		Contract: NewMikroE2EDryRunContract(),
	}
}

func (c MikroE2EDryRunContract) Validate() error {
	if strings.TrimSpace(c.Phase) != MikroE2EDryRunPhase {
		return fmt.Errorf("%w: phase must be %s", ErrInvalidMikroE2EDryRunContract, MikroE2EDryRunPhase)
	}
	if strings.TrimSpace(c.Module) != MikroE2EDryRunModule {
		return fmt.Errorf("%w: module must be %s", ErrInvalidMikroE2EDryRunContract, MikroE2EDryRunModule)
	}
	if strings.TrimSpace(c.ProviderID) != ProviderID {
		return fmt.Errorf("%w: provider_id must be %s", ErrInvalidMikroE2EDryRunContract, ProviderID)
	}
	if strings.TrimSpace(c.E2EMode) != MikroE2EDryRunMode {
		return fmt.Errorf("%w: e2e mode mismatch", ErrInvalidMikroE2EDryRunContract)
	}
	if strings.TrimSpace(c.Direction) != MikroE2EDryRunDirection {
		return fmt.Errorf("%w: direction must be PIX2PI_TO_MIKRO", ErrInvalidMikroE2EDryRunContract)
	}
	if strings.TrimSpace(c.TargetSystem) != MikroE2EDryRunTargetSystem {
		return fmt.Errorf("%w: target system must be Mikro dry-run import", ErrInvalidMikroE2EDryRunContract)
	}
	if c.ChainStatus != MikroE2EChainStatusReady {
		return fmt.Errorf("%w: chain status must be ready", ErrInvalidMikroE2EDryRunContract)
	}
	if c.ClosurePreparationStatus != MikroE2EClosurePrepReady {
		return fmt.Errorf("%w: closure preparation must be ready", ErrInvalidMikroE2EDryRunContract)
	}
	if c.RealQueueWritePolicy != MikroE2ERealQueueWritePolicy {
		return fmt.Errorf("%w: real queue write policy must stay closed", ErrInvalidMikroE2EDryRunContract)
	}
	if c.RealProviderAPIStatus != MikroRealProviderAPIStatus {
		return fmt.Errorf("%w: real provider API must stay closed", ErrInvalidMikroE2EDryRunContract)
	}
	if c.RealFileDeliveryStatus != MikroRealFileDeliveryStatus {
		return fmt.Errorf("%w: real file delivery must stay closed", ErrInvalidMikroE2EDryRunContract)
	}
	if c.RealERPWriteStatus != MikroRealERPWriteStatus {
		return fmt.Errorf("%w: real ERP write must stay closed", ErrInvalidMikroE2EDryRunContract)
	}
	if c.RealDeliveryChannelStatus != MikroRealDeliveryChannelStatus {
		return fmt.Errorf("%w: real delivery channel must stay closed", ErrInvalidMikroE2EDryRunContract)
	}
	if c.RealOperatorProviderActionStatus != MikroRealOperatorProviderActionStatus {
		return fmt.Errorf("%w: real operator provider action must stay closed", ErrInvalidMikroE2EDryRunContract)
	}
	if len(c.ChainSteps) < 7 {
		return fmt.Errorf("%w: chain steps are incomplete", ErrInvalidMikroE2EDryRunContract)
	}
	if len(c.RequiredContextFields) < 7 {
		return fmt.Errorf("%w: required context fields are incomplete", ErrInvalidMikroE2EDryRunContract)
	}
	if len(c.ForbiddenFieldLabels) == 0 {
		return fmt.Errorf("%w: forbidden fields are required", ErrInvalidMikroE2EDryRunContract)
	}
	return nil
}

func (r MikroE2EDryRunRuntime) Run(req MikroE2EDryRunRequest) (MikroE2EDryRunResult, MikroE2EDryRunDecision, error) {
	result := MikroE2EDryRunResult{}
	decision := r.baseDecision(req)

	if err := r.Contract.Validate(); err != nil {
		return result, decision, err
	}
	if err := validateMikroE2EDryRunRequest(req); err != nil {
		decision.Reason = MikroE2EDecisionInvalidInput
		return result, decision, err
	}
	if err := r.guardClosedRealOperations(req, &decision); err != nil {
		return result, decision, err
	}
	if decision.Reason != "" {
		return result, decision, nil
	}

	foundation := NewFoundation()
	if err := foundation.Validate(); err != nil {
		return result, decision, err
	}
	decision.ExecutedSteps = append(decision.ExecutedSteps, MikroE2EStepFoundationValidation)
	result.FoundationValidated = true

	mappingContract := NewMikroExportMappingContract()
	if err := mappingContract.Validate(); err != nil {
		return result, decision, err
	}
	mapping, ok := mappingContract.MappingFor(req.ERPObjectType)
	if !ok {
		decision.Reason = MikroE2EDecisionInvalidInput
		return result, decision, fmt.Errorf("%w: unsupported ERP object type", ErrInvalidMikroE2EDryRunRequest)
	}
	decision.ExecutedSteps = append(decision.ExecutedSteps, MikroE2EStepExportMapping)
	result.MappingValidated = true

	fileBuilder := NewMikroFileGenerationBuilder()
	pkg, packageDecision, err := fileBuilder.BuildDryRunPackage(MikroFileGenerationRequest{
		TenantID:                req.TenantID,
		ActorUserID:             req.ActorUserID,
		CorrelationID:           req.CorrelationID,
		PackageID:               req.PackageID,
		ERPObjectType:           req.ERPObjectType,
		RequestedMode:           MikroFileGenerationBuilderMode,
		InjectedFieldName:       req.InjectedFieldName,
		Records:                 req.Records,
		RealProviderAPIEnabled:  false,
		RealFileDeliveryEnabled: false,
		RealERPWriteEnabled:     false,
	})
	if err != nil {
		return result, decision, err
	}
	if !packageDecision.Allowed {
		decision.Reason = packageDecision.Reason
		return result, decision, nil
	}
	decision.ExecutedSteps = append(decision.ExecutedSteps, MikroE2EStepFileGeneration)
	result.PackageBuilt = true
	result.DryRunPackage = pkg

	deliveryRuntime := NewMikroImportDeliveryRuntime()
	receipt, deliveryDecision, err := deliveryRuntime.CreateDryRunDeliveryReceipt(MikroImportDeliveryRequest{
		TenantID:                req.TenantID,
		ActorUserID:             req.ActorUserID,
		CorrelationID:           req.CorrelationID,
		DeliveryID:              req.DeliveryID,
		RequestedMode:           MikroImportDeliveryContractMode,
		DeliveryChannel:         req.DeliveryChannel,
		InjectedFieldName:       req.InjectedFieldName,
		Package:                 pkg,
		RealProviderAPIEnabled:  false,
		RealFileDeliveryEnabled: false,
		RealERPWriteEnabled:     false,
		RealDeliveryEnabled:     false,
	})
	if err != nil {
		return result, decision, err
	}
	if !deliveryDecision.Allowed {
		decision.Reason = deliveryDecision.Reason
		return result, decision, nil
	}
	decision.ExecutedSteps = append(decision.ExecutedSteps, MikroE2EStepImportDelivery)
	result.DeliveryReceiptCreated = true
	result.DeliveryReceipt = receipt

	validationRuntime := NewMikroValidationRetryDLQRuntime()
	validationDecision, err := validationRuntime.Evaluate(MikroValidationRequest{
		TenantID:                req.TenantID,
		ActorUserID:             req.ActorUserID,
		CorrelationID:           req.CorrelationID,
		ValidationID:            req.ValidationID,
		RequestedMode:           MikroValidationRetryDLQMode,
		Attempt:                 1,
		ProviderErrorCode:       req.ProviderErrorCode,
		InjectedFieldName:       req.InjectedFieldName,
		Package:                 pkg,
		RealProviderAPIEnabled:  false,
		RealFileDeliveryEnabled: false,
		RealERPWriteEnabled:     false,
		RealDeliveryEnabled:     false,
	})
	if err != nil {
		return result, decision, err
	}
	if !validationDecision.Allowed {
		decision.Reason = validationDecision.Reason
		return result, decision, nil
	}
	decision.ExecutedSteps = append(decision.ExecutedSteps, MikroE2EStepValidationRetryDLQ)
	result.ValidationEvaluated = true
	result.ValidationDecision = validationDecision

	result.Phase = r.Contract.Phase
	result.Module = r.Contract.Module
	result.ProviderID = r.Contract.ProviderID
	result.ProviderName = r.Contract.ProviderName
	result.PackageID = pkg.Manifest.PackageID
	result.DeliveryID = strings.TrimSpace(req.DeliveryID)
	result.ValidationID = strings.TrimSpace(req.ValidationID)
	result.ReviewID = strings.TrimSpace(req.ReviewID)
	result.ERPObjectType = normalizeExportMappingValue(req.ERPObjectType)
	result.MikroObjectType = mapping.MikroObjectType
	result.FinalAction = validationDecision.Action
	result.FinalReason = validationDecision.Reason

	if validationDecision.ManualReview || validationDecision.SendToDLQ {
		adminRuntime := NewMikroAdminOpsRuntime()
		item, reviewDecision, err := adminRuntime.CreateManualReviewItem(MikroManualReviewRequest{
			TenantID:                          req.TenantID,
			ActorUserID:                       req.ActorUserID,
			CorrelationID:                     req.CorrelationID,
			ReviewID:                          req.ReviewID,
			RequestedMode:                     MikroAdminOpsMode,
			InjectedFieldName:                 req.InjectedFieldName,
			ValidationDecision:                validationDecision,
			Package:                           pkg,
			RealProviderAPIEnabled:            false,
			RealFileDeliveryEnabled:           false,
			RealERPWriteEnabled:               false,
			RealDeliveryEnabled:               false,
			RealOperatorProviderActionEnabled: false,
		})
		if err != nil {
			return result, decision, err
		}
		if !reviewDecision.Allowed {
			decision.Reason = reviewDecision.Reason
			return result, decision, nil
		}
		decision.ExecutedSteps = append(decision.ExecutedSteps, MikroE2EStepAdminOps)
		result.AdminOpsEvaluated = true
		result.ManualReviewItemCreated = true
		result.ManualReviewItem = item

		if strings.TrimSpace(req.OperatorAction) != "" {
			actionDecision, err := adminRuntime.EvaluateOperatorAction(MikroOperatorActionRequest{
				TenantID:                          req.TenantID,
				ActorUserID:                       req.ActorUserID,
				CorrelationID:                     req.CorrelationID,
				ReviewID:                          req.ReviewID,
				PackageID:                         req.PackageID,
				CurrentStatus:                     item.ReviewStatus,
				OperatorAction:                    req.OperatorAction,
				OperatorNote:                      req.OperatorNote,
				RequestedMode:                     MikroAdminOpsMode,
				InjectedFieldName:                 req.InjectedFieldName,
				RealProviderAPIEnabled:            false,
				RealFileDeliveryEnabled:           false,
				RealERPWriteEnabled:               false,
				RealDeliveryEnabled:               false,
				RealOperatorProviderActionEnabled: false,
			})
			if err != nil {
				return result, decision, err
			}
			if !actionDecision.Allowed {
				decision.Reason = actionDecision.Reason
				return result, decision, nil
			}
			decision.ExecutedSteps = append(decision.ExecutedSteps, MikroE2EStepOperatorAction)
			result.OperatorActionEvaluated = true
			result.OperatorActionDecision = actionDecision
			result.FinalAction = actionDecision.OperatorAction
			result.FinalReason = actionDecision.Reason
		}
	}

	result.RealExternalOperationCount = 0
	decision.Allowed = true
	decision.PackageID = result.PackageID
	decision.ERPObjectType = result.ERPObjectType
	decision.MikroObjectType = result.MikroObjectType
	decision.FinalAction = result.FinalAction

	switch validationDecision.Action {
	case MikroValidationActionRetry:
		decision.Reason = MikroE2EDecisionRetryReady
	case MikroValidationActionDLQ:
		decision.Reason = MikroE2EDecisionDLQReady
	case MikroValidationActionManualReview:
		decision.Reason = MikroE2EDecisionManualReviewReady
	default:
		decision.Reason = MikroE2EDecisionReady
	}

	return result, decision, nil
}

func (r MikroE2EDryRunRuntime) baseDecision(req MikroE2EDryRunRequest) MikroE2EDryRunDecision {
	return MikroE2EDryRunDecision{
		Allowed:                          false,
		Phase:                            r.Contract.Phase,
		Module:                           r.Contract.Module,
		ProviderID:                       r.Contract.ProviderID,
		ProviderName:                     r.Contract.ProviderName,
		PackageID:                        strings.TrimSpace(req.PackageID),
		DeliveryID:                       strings.TrimSpace(req.DeliveryID),
		ValidationID:                     strings.TrimSpace(req.ValidationID),
		ReviewID:                         strings.TrimSpace(req.ReviewID),
		ERPObjectType:                    normalizeExportMappingValue(req.ERPObjectType),
		E2EMode:                          r.Contract.E2EMode,
		Direction:                        r.Contract.Direction,
		TargetSystem:                     r.Contract.TargetSystem,
		ChainStatus:                      r.Contract.ChainStatus,
		ClosurePreparationStatus:         r.Contract.ClosurePreparationStatus,
		RealQueueWritePolicy:             r.Contract.RealQueueWritePolicy,
		RealProviderAPIStatus:            r.Contract.RealProviderAPIStatus,
		RealFileDeliveryStatus:           r.Contract.RealFileDeliveryStatus,
		RealERPWriteStatus:               r.Contract.RealERPWriteStatus,
		RealDeliveryChannelStatus:        r.Contract.RealDeliveryChannelStatus,
		RealOperatorProviderActionStatus: r.Contract.RealOperatorProviderActionStatus,
		ExecutedSteps:                    []string{},
		AuditFields: map[string]string{
			"tenant_id":                   strings.TrimSpace(req.TenantID),
			"actor_user_id":               strings.TrimSpace(req.ActorUserID),
			"correlation_id":              strings.TrimSpace(req.CorrelationID),
			"package_id":                  strings.TrimSpace(req.PackageID),
			"delivery_id":                 strings.TrimSpace(req.DeliveryID),
			"validation_id":               strings.TrimSpace(req.ValidationID),
			"review_id":                   strings.TrimSpace(req.ReviewID),
			"provider_id":                 r.Contract.ProviderID,
			"phase":                       r.Contract.Phase,
			"e2e_mode":                    r.Contract.E2EMode,
			"target_system":               r.Contract.TargetSystem,
			"real_queue_write_policy":     r.Contract.RealQueueWritePolicy,
			"real_provider_action_status": r.Contract.RealOperatorProviderActionStatus,
			"closure_preparation_status":  r.Contract.ClosurePreparationStatus,
		},
	}
}

func (r MikroE2EDryRunRuntime) guardClosedRealOperations(req MikroE2EDryRunRequest, decision *MikroE2EDryRunDecision) error {
	if containsForbiddenMappingField(req.InjectedFieldName) {
		decision.Reason = MikroE2EDecisionSecretDenied
		return ErrMikroE2EDryRunSecretForbidden
	}
	if normalizeExportMappingValue(req.RequestedMode) == "PROVIDER_LIVE" {
		decision.Reason = MikroE2EDecisionProviderLiveClosed
		return nil
	}
	if req.RealProviderAPIEnabled {
		decision.Reason = MikroE2EDecisionRealProviderAPI
		return nil
	}
	if req.RealFileDeliveryEnabled {
		decision.Reason = MikroE2EDecisionRealFileDelivery
		return nil
	}
	if req.RealERPWriteEnabled {
		decision.Reason = MikroE2EDecisionRealERPWrite
		return nil
	}
	if req.RealDeliveryEnabled {
		decision.Reason = MikroE2EDecisionRealDelivery
		return nil
	}
	if req.RealOperatorProviderActionEnabled {
		decision.Reason = MikroE2EDecisionRealProviderAction
		return nil
	}
	return nil
}

func validateMikroE2EDryRunRequest(req MikroE2EDryRunRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return fmt.Errorf("%w: tenant_id is required", ErrInvalidMikroE2EDryRunRequest)
	}
	if strings.TrimSpace(req.ActorUserID) == "" {
		return fmt.Errorf("%w: actor_user_id is required", ErrInvalidMikroE2EDryRunRequest)
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return fmt.Errorf("%w: correlation_id is required", ErrInvalidMikroE2EDryRunRequest)
	}
	if strings.TrimSpace(req.PackageID) == "" {
		return fmt.Errorf("%w: package_id is required", ErrInvalidMikroE2EDryRunRequest)
	}
	if strings.TrimSpace(req.DeliveryID) == "" {
		return fmt.Errorf("%w: delivery_id is required", ErrInvalidMikroE2EDryRunRequest)
	}
	if strings.TrimSpace(req.ValidationID) == "" {
		return fmt.Errorf("%w: validation_id is required", ErrInvalidMikroE2EDryRunRequest)
	}
	if strings.TrimSpace(req.ReviewID) == "" {
		return fmt.Errorf("%w: review_id is required", ErrInvalidMikroE2EDryRunRequest)
	}
	if strings.TrimSpace(req.ERPObjectType) == "" {
		return fmt.Errorf("%w: erp_object_type is required", ErrInvalidMikroE2EDryRunRequest)
	}
	if strings.TrimSpace(req.DeliveryChannel) == "" {
		return fmt.Errorf("%w: delivery_channel is required", ErrInvalidMikroE2EDryRunRequest)
	}
	if len(req.Records) == 0 {
		return fmt.Errorf("%w: at least one dry-run record is required", ErrInvalidMikroE2EDryRunRequest)
	}
	if strings.TrimSpace(req.OperatorAction) != "" && strings.TrimSpace(req.OperatorNote) == "" {
		return fmt.Errorf("%w: operator_note is required when operator_action is provided", ErrInvalidMikroE2EDryRunRequest)
	}
	return nil
}
