package mikro

import (
	"errors"
	"fmt"
	"strings"
)

const (
	MikroFinalClosurePhase        = "FAZ_7_8M_7"
	MikroFinalClosureModule       = "MIKRO_CONNECTOR_FINAL_CLOSURE"
	MikroFinalClosureModuleName   = "Mikro Connector Final Closure / Provider Live Module Handoff Gate"
	MikroFinalClosureMode         = "CONNECTOR_DRY_RUN_FINAL_CLOSURE_ONLY"
	MikroFinalClosureDirection    = "PIX2PI_TO_MIKRO"
	MikroFinalClosureSourceSystem = "PIX2PI_ERP"
	MikroFinalClosureTargetSystem = "MIKRO_ACCOUNTING_IMPORT_DRY_RUN"
	MikroFinalClosureGate         = "READY_AFTER_TEST_AND_AUDIT_PASS"

	MikroConnectorModuleFinalSealStatus      = "SEALED"
	MikroDryRunModuleStatus                  = "SEALED"
	MikroFinalClosureProviderLiveHandoffGate = "READY_FOR_PROVIDER_LIVE_MODULE"
	MikroProviderLiveModuleStatus            = "NOT_STARTED"
	MikroFinalClosureRealQueuePolicy         = "NO_REAL_QUEUE_WRITE_IN_THIS_PHASE"

	MikroFinalClosureStepFoundation     = "FOUNDATION"
	MikroFinalClosureStepExportMapping  = "EXPORT_MAPPING"
	MikroFinalClosureStepFileGeneration = "FILE_GENERATION"
	MikroFinalClosureStepImportDelivery = "IMPORT_DELIVERY"
	MikroFinalClosureStepValidation     = "VALIDATION_RETRY_DLQ"
	MikroFinalClosureStepAdminOps       = "ADMIN_OPS"
	MikroFinalClosureStepE2E            = "E2E_DRY_RUN"

	MikroFinalClosureDecisionReady              = "MIKRO_CONNECTOR_FINAL_CLOSURE_READY"
	MikroFinalClosureDecisionInvalidInput       = "MIKRO_CONNECTOR_FINAL_CLOSURE_INPUT_INVALID"
	MikroFinalClosureDecisionSecretDenied       = "MIKRO_CONNECTOR_FINAL_CLOSURE_SECRET_FIELD_FORBIDDEN"
	MikroFinalClosureDecisionRealProviderAPI    = "MIKRO_CONNECTOR_FINAL_CLOSURE_REAL_PROVIDER_API_CLOSED"
	MikroFinalClosureDecisionRealFileDelivery   = "MIKRO_CONNECTOR_FINAL_CLOSURE_REAL_FILE_DELIVERY_CLOSED"
	MikroFinalClosureDecisionRealERPWrite       = "MIKRO_CONNECTOR_FINAL_CLOSURE_REAL_ERP_WRITE_CLOSED"
	MikroFinalClosureDecisionRealDelivery       = "MIKRO_CONNECTOR_FINAL_CLOSURE_REAL_DELIVERY_CHANNEL_CLOSED"
	MikroFinalClosureDecisionRealProviderAction = "MIKRO_CONNECTOR_FINAL_CLOSURE_REAL_OPERATOR_PROVIDER_ACTION_CLOSED"
	MikroFinalClosureDecisionProviderLiveClosed = "MIKRO_CONNECTOR_FINAL_CLOSURE_PROVIDER_LIVE_MODE_CLOSED"
)

var (
	ErrInvalidMikroFinalClosureContract = errors.New("invalid mikro final closure contract")
	ErrInvalidMikroFinalClosureRequest  = errors.New("invalid mikro final closure request")
	ErrMikroFinalClosureSecretForbidden = errors.New("mikro final closure secret field is forbidden")
)

type MikroFinalClosureContract struct {
	Phase                            string
	Module                           string
	ModuleName                       string
	ProviderID                       string
	ProviderName                     string
	ProviderCategory                 string
	FinalClosureMode                 string
	Direction                        string
	SourceSystem                     string
	TargetSystem                     string
	FinalClosureGate                 string
	ConnectorModuleFinalSealStatus   string
	DryRunModuleStatus               string
	ProviderLiveHandoffGate          string
	ProviderLiveModuleStatus         string
	RealQueueWritePolicy             string
	RealProviderAPIStatus            string
	RealFileDeliveryStatus           string
	RealERPWriteStatus               string
	RealDeliveryChannelStatus        string
	RealOperatorProviderActionStatus string
	ClosureChain                     []string
	RequiredContextFields            []string
	ForbiddenFieldLabels             []string
}

type MikroFinalClosureRequest struct {
	TenantID                          string
	ActorUserID                       string
	CorrelationID                     string
	ClosureID                         string
	PackageID                         string
	DeliveryID                        string
	ValidationID                      string
	ReviewID                          string
	ERPObjectType                     string
	DeliveryChannel                   string
	RequestedMode                     string
	InjectedFieldName                 string
	Records                           []MikroDryRunPackageRecord
	RealProviderAPIEnabled            bool
	RealFileDeliveryEnabled           bool
	RealERPWriteEnabled               bool
	RealDeliveryEnabled               bool
	RealOperatorProviderActionEnabled bool
}

type MikroFinalClosureResult struct {
	Phase                            string
	Module                           string
	ProviderID                       string
	ProviderName                     string
	ClosureID                        string
	PackageID                        string
	DeliveryID                       string
	ValidationID                     string
	ReviewID                         string
	ERPObjectType                    string
	MikroObjectType                  string
	ConnectorModuleFinalSealStatus   string
	DryRunModuleStatus               string
	ProviderLiveHandoffGate          string
	ProviderLiveModuleStatus         string
	FoundationValidated              bool
	ExportMappingValidated           bool
	FileGenerationValidated          bool
	ImportDeliveryValidated          bool
	ValidationRetryDLQValidated      bool
	AdminOpsValidated                bool
	E2EDryRunValidated               bool
	E2EResult                        MikroE2EDryRunResult
	E2EDecision                      MikroE2EDryRunDecision
	RealExternalOperationCount       int
	RealProviderAPIStatus            string
	RealFileDeliveryStatus           string
	RealERPWriteStatus               string
	RealDeliveryChannelStatus        string
	RealOperatorProviderActionStatus string
}

type MikroFinalClosureDecision struct {
	Allowed                          bool
	Phase                            string
	Module                           string
	ProviderID                       string
	ProviderName                     string
	ClosureID                        string
	PackageID                        string
	DeliveryID                       string
	ValidationID                     string
	ReviewID                         string
	ERPObjectType                    string
	MikroObjectType                  string
	FinalClosureMode                 string
	Direction                        string
	TargetSystem                     string
	Reason                           string
	ConnectorModuleFinalSealStatus   string
	DryRunModuleStatus               string
	ProviderLiveHandoffGate          string
	ProviderLiveModuleStatus         string
	RealQueueWritePolicy             string
	RealProviderAPIStatus            string
	RealFileDeliveryStatus           string
	RealERPWriteStatus               string
	RealDeliveryChannelStatus        string
	RealOperatorProviderActionStatus string
	ValidatedSteps                   []string
	AuditFields                      map[string]string
}

type MikroFinalClosureRuntime struct {
	Contract MikroFinalClosureContract
}

func NewMikroFinalClosureContract() MikroFinalClosureContract {
	return MikroFinalClosureContract{
		Phase:                            MikroFinalClosurePhase,
		Module:                           MikroFinalClosureModule,
		ModuleName:                       MikroFinalClosureModuleName,
		ProviderID:                       ProviderID,
		ProviderName:                     ProviderName,
		ProviderCategory:                 ProviderCategory,
		FinalClosureMode:                 MikroFinalClosureMode,
		Direction:                        MikroFinalClosureDirection,
		SourceSystem:                     MikroFinalClosureSourceSystem,
		TargetSystem:                     MikroFinalClosureTargetSystem,
		FinalClosureGate:                 MikroFinalClosureGate,
		ConnectorModuleFinalSealStatus:   MikroConnectorModuleFinalSealStatus,
		DryRunModuleStatus:               MikroDryRunModuleStatus,
		ProviderLiveHandoffGate:          MikroFinalClosureProviderLiveHandoffGate,
		ProviderLiveModuleStatus:         MikroProviderLiveModuleStatus,
		RealQueueWritePolicy:             MikroFinalClosureRealQueuePolicy,
		RealProviderAPIStatus:            MikroRealProviderAPIStatus,
		RealFileDeliveryStatus:           MikroRealFileDeliveryStatus,
		RealERPWriteStatus:               MikroRealERPWriteStatus,
		RealDeliveryChannelStatus:        MikroRealDeliveryChannelStatus,
		RealOperatorProviderActionStatus: MikroRealOperatorProviderActionStatus,
		ClosureChain: []string{
			MikroFinalClosureStepFoundation,
			MikroFinalClosureStepExportMapping,
			MikroFinalClosureStepFileGeneration,
			MikroFinalClosureStepImportDelivery,
			MikroFinalClosureStepValidation,
			MikroFinalClosureStepAdminOps,
			MikroFinalClosureStepE2E,
		},
		RequiredContextFields: []string{
			"tenant_id",
			"actor_user_id",
			"correlation_id",
			"closure_id",
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

func NewMikroFinalClosureRuntime() MikroFinalClosureRuntime {
	return MikroFinalClosureRuntime{
		Contract: NewMikroFinalClosureContract(),
	}
}

func (c MikroFinalClosureContract) Validate() error {
	if strings.TrimSpace(c.Phase) != MikroFinalClosurePhase {
		return fmt.Errorf("%w: phase must be %s", ErrInvalidMikroFinalClosureContract, MikroFinalClosurePhase)
	}
	if strings.TrimSpace(c.Module) != MikroFinalClosureModule {
		return fmt.Errorf("%w: module must be %s", ErrInvalidMikroFinalClosureContract, MikroFinalClosureModule)
	}
	if strings.TrimSpace(c.ProviderID) != ProviderID {
		return fmt.Errorf("%w: provider_id must be %s", ErrInvalidMikroFinalClosureContract, ProviderID)
	}
	if strings.TrimSpace(c.FinalClosureMode) != MikroFinalClosureMode {
		return fmt.Errorf("%w: final closure mode mismatch", ErrInvalidMikroFinalClosureContract)
	}
	if strings.TrimSpace(c.Direction) != MikroFinalClosureDirection {
		return fmt.Errorf("%w: direction must be PIX2PI_TO_MIKRO", ErrInvalidMikroFinalClosureContract)
	}
	if strings.TrimSpace(c.TargetSystem) != MikroFinalClosureTargetSystem {
		return fmt.Errorf("%w: target system must be Mikro dry-run import", ErrInvalidMikroFinalClosureContract)
	}
	if c.ConnectorModuleFinalSealStatus != MikroConnectorModuleFinalSealStatus {
		return fmt.Errorf("%w: connector final seal must be SEALED", ErrInvalidMikroFinalClosureContract)
	}
	if c.DryRunModuleStatus != MikroDryRunModuleStatus {
		return fmt.Errorf("%w: dry-run module status must be SEALED", ErrInvalidMikroFinalClosureContract)
	}
	if c.ProviderLiveHandoffGate != MikroFinalClosureProviderLiveHandoffGate {
		return fmt.Errorf("%w: provider live handoff gate mismatch", ErrInvalidMikroFinalClosureContract)
	}
	if c.ProviderLiveModuleStatus != MikroProviderLiveModuleStatus {
		return fmt.Errorf("%w: provider live module must be NOT_STARTED", ErrInvalidMikroFinalClosureContract)
	}
	if c.RealQueueWritePolicy != MikroFinalClosureRealQueuePolicy {
		return fmt.Errorf("%w: real queue write policy must stay closed", ErrInvalidMikroFinalClosureContract)
	}
	if c.RealProviderAPIStatus != MikroRealProviderAPIStatus {
		return fmt.Errorf("%w: real provider API must stay closed", ErrInvalidMikroFinalClosureContract)
	}
	if c.RealFileDeliveryStatus != MikroRealFileDeliveryStatus {
		return fmt.Errorf("%w: real file delivery must stay closed", ErrInvalidMikroFinalClosureContract)
	}
	if c.RealERPWriteStatus != MikroRealERPWriteStatus {
		return fmt.Errorf("%w: real ERP write must stay closed", ErrInvalidMikroFinalClosureContract)
	}
	if c.RealDeliveryChannelStatus != MikroRealDeliveryChannelStatus {
		return fmt.Errorf("%w: real delivery channel must stay closed", ErrInvalidMikroFinalClosureContract)
	}
	if c.RealOperatorProviderActionStatus != MikroRealOperatorProviderActionStatus {
		return fmt.Errorf("%w: real operator provider action must stay closed", ErrInvalidMikroFinalClosureContract)
	}
	if len(c.ClosureChain) < 7 {
		return fmt.Errorf("%w: closure chain is incomplete", ErrInvalidMikroFinalClosureContract)
	}
	if len(c.RequiredContextFields) < 8 {
		return fmt.Errorf("%w: required context fields are incomplete", ErrInvalidMikroFinalClosureContract)
	}
	if len(c.ForbiddenFieldLabels) == 0 {
		return fmt.Errorf("%w: forbidden fields are required", ErrInvalidMikroFinalClosureContract)
	}
	return nil
}

func (r MikroFinalClosureRuntime) BuildFinalClosure(req MikroFinalClosureRequest) (MikroFinalClosureResult, MikroFinalClosureDecision, error) {
	result := MikroFinalClosureResult{}
	decision := r.baseDecision(req)

	if err := r.Contract.Validate(); err != nil {
		return result, decision, err
	}
	if err := validateMikroFinalClosureRequest(req); err != nil {
		decision.Reason = MikroFinalClosureDecisionInvalidInput
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
	decision.ValidatedSteps = append(decision.ValidatedSteps, MikroFinalClosureStepFoundation)
	result.FoundationValidated = true

	mappingContract := NewMikroExportMappingContract()
	if err := mappingContract.Validate(); err != nil {
		return result, decision, err
	}
	mapping, ok := mappingContract.MappingFor(req.ERPObjectType)
	if !ok {
		decision.Reason = MikroFinalClosureDecisionInvalidInput
		return result, decision, fmt.Errorf("%w: unsupported ERP object type", ErrInvalidMikroFinalClosureRequest)
	}
	decision.ValidatedSteps = append(decision.ValidatedSteps, MikroFinalClosureStepExportMapping)
	result.ExportMappingValidated = true

	fileGenerationContract := NewMikroFileGenerationContract()
	if err := fileGenerationContract.Validate(); err != nil {
		return result, decision, err
	}
	decision.ValidatedSteps = append(decision.ValidatedSteps, MikroFinalClosureStepFileGeneration)
	result.FileGenerationValidated = true

	importDeliveryContract := NewMikroImportDeliveryContract()
	if err := importDeliveryContract.Validate(); err != nil {
		return result, decision, err
	}
	decision.ValidatedSteps = append(decision.ValidatedSteps, MikroFinalClosureStepImportDelivery)
	result.ImportDeliveryValidated = true

	validationContract := NewMikroValidationRetryDLQContract()
	if err := validationContract.Validate(); err != nil {
		return result, decision, err
	}
	decision.ValidatedSteps = append(decision.ValidatedSteps, MikroFinalClosureStepValidation)
	result.ValidationRetryDLQValidated = true

	adminOpsContract := NewMikroAdminOpsContract()
	if err := adminOpsContract.Validate(); err != nil {
		return result, decision, err
	}
	decision.ValidatedSteps = append(decision.ValidatedSteps, MikroFinalClosureStepAdminOps)
	result.AdminOpsValidated = true

	e2eRuntime := NewMikroE2EDryRunRuntime()
	e2eResult, e2eDecision, err := e2eRuntime.Run(MikroE2EDryRunRequest{
		TenantID:                          req.TenantID,
		ActorUserID:                       req.ActorUserID,
		CorrelationID:                     req.CorrelationID,
		PackageID:                         req.PackageID,
		DeliveryID:                        req.DeliveryID,
		ValidationID:                      req.ValidationID,
		ReviewID:                          req.ReviewID,
		ERPObjectType:                     req.ERPObjectType,
		DeliveryChannel:                   req.DeliveryChannel,
		RequestedMode:                     MikroE2EDryRunMode,
		InjectedFieldName:                 req.InjectedFieldName,
		Records:                           req.Records,
		RealProviderAPIEnabled:            false,
		RealFileDeliveryEnabled:           false,
		RealERPWriteEnabled:               false,
		RealDeliveryEnabled:               false,
		RealOperatorProviderActionEnabled: false,
	})
	if err != nil {
		return result, decision, err
	}
	if !e2eDecision.Allowed {
		decision.Reason = e2eDecision.Reason
		return result, decision, nil
	}
	decision.ValidatedSteps = append(decision.ValidatedSteps, MikroFinalClosureStepE2E)
	result.E2EDryRunValidated = true

	result.Phase = r.Contract.Phase
	result.Module = r.Contract.Module
	result.ProviderID = r.Contract.ProviderID
	result.ProviderName = r.Contract.ProviderName
	result.ClosureID = strings.TrimSpace(req.ClosureID)
	result.PackageID = strings.TrimSpace(req.PackageID)
	result.DeliveryID = strings.TrimSpace(req.DeliveryID)
	result.ValidationID = strings.TrimSpace(req.ValidationID)
	result.ReviewID = strings.TrimSpace(req.ReviewID)
	result.ERPObjectType = normalizeExportMappingValue(req.ERPObjectType)
	result.MikroObjectType = mapping.MikroObjectType
	result.ConnectorModuleFinalSealStatus = r.Contract.ConnectorModuleFinalSealStatus
	result.DryRunModuleStatus = r.Contract.DryRunModuleStatus
	result.ProviderLiveHandoffGate = r.Contract.ProviderLiveHandoffGate
	result.ProviderLiveModuleStatus = r.Contract.ProviderLiveModuleStatus
	result.E2EResult = e2eResult
	result.E2EDecision = e2eDecision
	result.RealExternalOperationCount = 0
	result.RealProviderAPIStatus = r.Contract.RealProviderAPIStatus
	result.RealFileDeliveryStatus = r.Contract.RealFileDeliveryStatus
	result.RealERPWriteStatus = r.Contract.RealERPWriteStatus
	result.RealDeliveryChannelStatus = r.Contract.RealDeliveryChannelStatus
	result.RealOperatorProviderActionStatus = r.Contract.RealOperatorProviderActionStatus

	decision.Allowed = true
	decision.Reason = MikroFinalClosureDecisionReady
	decision.MikroObjectType = mapping.MikroObjectType
	return result, decision, nil
}

func (r MikroFinalClosureRuntime) baseDecision(req MikroFinalClosureRequest) MikroFinalClosureDecision {
	return MikroFinalClosureDecision{
		Allowed:                          false,
		Phase:                            r.Contract.Phase,
		Module:                           r.Contract.Module,
		ProviderID:                       r.Contract.ProviderID,
		ProviderName:                     r.Contract.ProviderName,
		ClosureID:                        strings.TrimSpace(req.ClosureID),
		PackageID:                        strings.TrimSpace(req.PackageID),
		DeliveryID:                       strings.TrimSpace(req.DeliveryID),
		ValidationID:                     strings.TrimSpace(req.ValidationID),
		ReviewID:                         strings.TrimSpace(req.ReviewID),
		ERPObjectType:                    normalizeExportMappingValue(req.ERPObjectType),
		FinalClosureMode:                 r.Contract.FinalClosureMode,
		Direction:                        r.Contract.Direction,
		TargetSystem:                     r.Contract.TargetSystem,
		ConnectorModuleFinalSealStatus:   r.Contract.ConnectorModuleFinalSealStatus,
		DryRunModuleStatus:               r.Contract.DryRunModuleStatus,
		ProviderLiveHandoffGate:          r.Contract.ProviderLiveHandoffGate,
		ProviderLiveModuleStatus:         r.Contract.ProviderLiveModuleStatus,
		RealQueueWritePolicy:             r.Contract.RealQueueWritePolicy,
		RealProviderAPIStatus:            r.Contract.RealProviderAPIStatus,
		RealFileDeliveryStatus:           r.Contract.RealFileDeliveryStatus,
		RealERPWriteStatus:               r.Contract.RealERPWriteStatus,
		RealDeliveryChannelStatus:        r.Contract.RealDeliveryChannelStatus,
		RealOperatorProviderActionStatus: r.Contract.RealOperatorProviderActionStatus,
		ValidatedSteps:                   []string{},
		AuditFields: map[string]string{
			"tenant_id":                   strings.TrimSpace(req.TenantID),
			"actor_user_id":               strings.TrimSpace(req.ActorUserID),
			"correlation_id":              strings.TrimSpace(req.CorrelationID),
			"closure_id":                  strings.TrimSpace(req.ClosureID),
			"package_id":                  strings.TrimSpace(req.PackageID),
			"delivery_id":                 strings.TrimSpace(req.DeliveryID),
			"validation_id":               strings.TrimSpace(req.ValidationID),
			"review_id":                   strings.TrimSpace(req.ReviewID),
			"provider_id":                 r.Contract.ProviderID,
			"phase":                       r.Contract.Phase,
			"final_closure_mode":          r.Contract.FinalClosureMode,
			"dry_run_module_status":       r.Contract.DryRunModuleStatus,
			"provider_live_handoff_gate":  r.Contract.ProviderLiveHandoffGate,
			"provider_live_module_status": r.Contract.ProviderLiveModuleStatus,
			"real_queue_write_policy":     r.Contract.RealQueueWritePolicy,
			"real_provider_action_status": r.Contract.RealOperatorProviderActionStatus,
		},
	}
}

func (r MikroFinalClosureRuntime) guardClosedRealOperations(req MikroFinalClosureRequest, decision *MikroFinalClosureDecision) error {
	if containsForbiddenMappingField(req.InjectedFieldName) {
		decision.Reason = MikroFinalClosureDecisionSecretDenied
		return ErrMikroFinalClosureSecretForbidden
	}
	if normalizeExportMappingValue(req.RequestedMode) == "PROVIDER_LIVE" {
		decision.Reason = MikroFinalClosureDecisionProviderLiveClosed
		return nil
	}
	if req.RealProviderAPIEnabled {
		decision.Reason = MikroFinalClosureDecisionRealProviderAPI
		return nil
	}
	if req.RealFileDeliveryEnabled {
		decision.Reason = MikroFinalClosureDecisionRealFileDelivery
		return nil
	}
	if req.RealERPWriteEnabled {
		decision.Reason = MikroFinalClosureDecisionRealERPWrite
		return nil
	}
	if req.RealDeliveryEnabled {
		decision.Reason = MikroFinalClosureDecisionRealDelivery
		return nil
	}
	if req.RealOperatorProviderActionEnabled {
		decision.Reason = MikroFinalClosureDecisionRealProviderAction
		return nil
	}
	return nil
}

func validateMikroFinalClosureRequest(req MikroFinalClosureRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return fmt.Errorf("%w: tenant_id is required", ErrInvalidMikroFinalClosureRequest)
	}
	if strings.TrimSpace(req.ActorUserID) == "" {
		return fmt.Errorf("%w: actor_user_id is required", ErrInvalidMikroFinalClosureRequest)
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return fmt.Errorf("%w: correlation_id is required", ErrInvalidMikroFinalClosureRequest)
	}
	if strings.TrimSpace(req.ClosureID) == "" {
		return fmt.Errorf("%w: closure_id is required", ErrInvalidMikroFinalClosureRequest)
	}
	if strings.TrimSpace(req.PackageID) == "" {
		return fmt.Errorf("%w: package_id is required", ErrInvalidMikroFinalClosureRequest)
	}
	if strings.TrimSpace(req.DeliveryID) == "" {
		return fmt.Errorf("%w: delivery_id is required", ErrInvalidMikroFinalClosureRequest)
	}
	if strings.TrimSpace(req.ValidationID) == "" {
		return fmt.Errorf("%w: validation_id is required", ErrInvalidMikroFinalClosureRequest)
	}
	if strings.TrimSpace(req.ReviewID) == "" {
		return fmt.Errorf("%w: review_id is required", ErrInvalidMikroFinalClosureRequest)
	}
	if strings.TrimSpace(req.ERPObjectType) == "" {
		return fmt.Errorf("%w: erp_object_type is required", ErrInvalidMikroFinalClosureRequest)
	}
	if strings.TrimSpace(req.DeliveryChannel) == "" {
		return fmt.Errorf("%w: delivery_channel is required", ErrInvalidMikroFinalClosureRequest)
	}
	if len(req.Records) == 0 {
		return fmt.Errorf("%w: at least one dry-run record is required", ErrInvalidMikroFinalClosureRequest)
	}
	return nil
}
