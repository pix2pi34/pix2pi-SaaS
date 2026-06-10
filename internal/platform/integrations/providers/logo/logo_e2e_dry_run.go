package logo

import (
	"errors"
	"fmt"
	"strings"
)

const (
	StepFAZ78L9 = "FAZ_7_8L.9"

	LogoE2EDryRunMode   = "E2E_DRY_RUN_ONLY"
	LogoE2EDryRunStatus = "READY"

	LogoE2EFlowSuccessfulDryRun       = "SUCCESSFUL_DRY_RUN_FLOW"
	LogoE2EFlowValidationFailureToDLQ = "VALIDATION_FAILURE_TO_DLQ_FLOW"
	LogoE2EFlowTransientProviderRetry = "TRANSIENT_PROVIDER_RETRY_FLOW"
	LogoE2EFlowManualReview           = "UNKNOWN_PROVIDER_MANUAL_REVIEW_FLOW"
)

type LogoE2EDryRunOperationName string

const (
	LogoOperationDeclareE2EDryRunContract      LogoE2EDryRunOperationName = "DECLARE_LOGO_E2E_DRY_RUN_CONTRACT"
	LogoOperationRunE2EDryRunSuccessFlow       LogoE2EDryRunOperationName = "RUN_LOGO_E2E_DRY_RUN_SUCCESS_FLOW"
	LogoOperationRunE2EValidationFlow          LogoE2EDryRunOperationName = "RUN_LOGO_E2E_VALIDATION_FLOW"
	LogoOperationRunE2ERetryDecisionFlow       LogoE2EDryRunOperationName = "RUN_LOGO_E2E_RETRY_DECISION_FLOW"
	LogoOperationRunE2EManualReviewFlow        LogoE2EDryRunOperationName = "RUN_LOGO_E2E_MANUAL_REVIEW_FLOW"
	LogoOperationValidateE2EChainDependencies  LogoE2EDryRunOperationName = "VALIDATE_LOGO_E2E_CHAIN_DEPENDENCIES"
	LogoOperationValidateE2ENoRealProviderAPI  LogoE2EDryRunOperationName = "VALIDATE_LOGO_E2E_NO_REAL_PROVIDER_API"
	LogoOperationValidateE2ENoRealFileDelivery LogoE2EDryRunOperationName = "VALIDATE_LOGO_E2E_NO_REAL_FILE_DELIVERY"
	LogoOperationValidateE2ENoERPWrite         LogoE2EDryRunOperationName = "VALIDATE_LOGO_E2E_NO_ERP_WRITE"
	LogoOperationPrepareFinalClosureHandoff    LogoE2EDryRunOperationName = "PREPARE_LOGO_FINAL_CLOSURE_HANDOFF"
)

type LogoE2EDryRunContractRules struct {
	Declared                          bool   `json:"declared"`
	Status                            string `json:"status"`
	DryRunOnly                        bool   `json:"dry_run_only"`
	ChainDependencyValidationRequired bool   `json:"chain_dependency_validation_required"`
	SuccessfulFlowRequired            bool   `json:"successful_flow_required"`
	ValidationFailureFlowRequired     bool   `json:"validation_failure_flow_required"`
	RetryDecisionFlowRequired         bool   `json:"retry_decision_flow_required"`
	ManualReviewFlowRequired          bool   `json:"manual_review_flow_required"`
	ExternalCallAllowed               bool   `json:"external_call_allowed"`
	RealFileDeliveryAllowed           bool   `json:"real_file_delivery_allowed"`
	ERPWriteAllowed                   bool   `json:"erp_write_allowed"`
}

type LogoE2EDryRunOperationContract struct {
	Name                    LogoE2EDryRunOperationName `json:"name"`
	Mode                    string                     `json:"mode"`
	DryRunE2EAllowed        bool                       `json:"dry_run_e2e_allowed"`
	ExternalCallAllowed     bool                       `json:"external_call_allowed"`
	RealFileDeliveryAllowed bool                       `json:"real_file_delivery_allowed"`
	ERPWriteAllowed         bool                       `json:"erp_write_allowed"`
}

type LogoE2EDryRunContract struct {
	Module                 string                           `json:"module"`
	Step                   string                           `json:"step"`
	ProviderCode           string                           `json:"provider_code"`
	ProviderName           string                           `json:"provider_name"`
	ConnectorCode          string                           `json:"connector_code"`
	ConnectorFamily        string                           `json:"connector_family"`
	RuntimeMode            string                           `json:"runtime_mode"`
	E2EMode                string                           `json:"e2e_mode"`
	TargetSystem           string                           `json:"target_system"`
	E2EStatus              string                           `json:"e2e_dry_run_status"`
	RealProviderAPIStatus  string                           `json:"real_provider_api_status"`
	RealFileDeliveryStatus string                           `json:"real_file_delivery_status"`
	RealERPWriteStatus     string                           `json:"real_erp_write_status"`
	Rules                  LogoE2EDryRunContractRules       `json:"e2e_contract"`
	Operations             []LogoE2EDryRunOperationContract `json:"operations"`
}

type LogoE2EDryRunResult struct {
	FlowID                    string   `json:"flow_id"`
	FlowType                  string   `json:"flow_type"`
	TenantID                  string   `json:"tenant_id"`
	CorrelationID             string   `json:"correlation_id"`
	IdempotencyKey            string   `json:"idempotency_key"`
	PackageID                 string   `json:"package_id"`
	DeliveryID                string   `json:"delivery_id"`
	ValidationAction          string   `json:"validation_action"`
	FinalAction               string   `json:"final_action"`
	ManualReviewCreated       bool     `json:"manual_review_created"`
	ManualReviewID            string   `json:"manual_review_id"`
	RetryDecisionCreated      bool     `json:"retry_decision_created"`
	DLQDecisionCreated        bool     `json:"dlq_decision_created"`
	Steps                     []string `json:"steps"`
	DryRunOnly                bool     `json:"dry_run_only"`
	RealProviderAPICalled     bool     `json:"real_provider_api_called"`
	RealFileDeliveryAttempted bool     `json:"real_file_delivery_attempted"`
	ERPWriteAttempted         bool     `json:"erp_write_attempted"`
}

func NewLogoE2EDryRunContract() LogoE2EDryRunContract {
	return LogoE2EDryRunContract{
		Module:                 ModuleFAZ78L,
		Step:                   StepFAZ78L9,
		ProviderCode:           ProviderCode,
		ProviderName:           ProviderName,
		ConnectorCode:          ConnectorCode,
		ConnectorFamily:        ConnectorFamily,
		RuntimeMode:            RuntimeModeDryRun,
		E2EMode:                LogoE2EDryRunMode,
		TargetSystem:           LogoTargetSystem,
		E2EStatus:              LogoE2EDryRunStatus,
		RealProviderAPIStatus:  RealProviderAPIClosedStatus,
		RealFileDeliveryStatus: RealFileDeliveryClosedStatus,
		RealERPWriteStatus:     RealERPWriteClosedStatus,
		Rules: LogoE2EDryRunContractRules{
			Declared:                          true,
			Status:                            LogoE2EDryRunStatus,
			DryRunOnly:                        true,
			ChainDependencyValidationRequired: true,
			SuccessfulFlowRequired:            true,
			ValidationFailureFlowRequired:     true,
			RetryDecisionFlowRequired:         true,
			ManualReviewFlowRequired:          true,
			ExternalCallAllowed:               false,
			RealFileDeliveryAllowed:           false,
			ERPWriteAllowed:                   false,
		},
		Operations: []LogoE2EDryRunOperationContract{
			{Name: LogoOperationDeclareE2EDryRunContract, Mode: LogoE2EDryRunMode, DryRunE2EAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationRunE2EDryRunSuccessFlow, Mode: LogoE2EDryRunMode, DryRunE2EAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationRunE2EValidationFlow, Mode: LogoE2EDryRunMode, DryRunE2EAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationRunE2ERetryDecisionFlow, Mode: LogoE2EDryRunMode, DryRunE2EAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationRunE2EManualReviewFlow, Mode: LogoE2EDryRunMode, DryRunE2EAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateE2EChainDependencies, Mode: LogoE2EDryRunMode, DryRunE2EAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateE2ENoRealProviderAPI, Mode: LogoE2EDryRunMode, DryRunE2EAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateE2ENoRealFileDelivery, Mode: LogoE2EDryRunMode, DryRunE2EAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateE2ENoERPWrite, Mode: LogoE2EDryRunMode, DryRunE2EAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationPrepareFinalClosureHandoff, Mode: LogoE2EDryRunMode, DryRunE2EAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
		},
	}
}

func (c LogoE2EDryRunContract) Validate() error {
	adminOps := NewLogoAdminOpsContract()
	if err := adminOps.Validate(); err != nil {
		return fmt.Errorf("logo admin ops must be valid before E2E dry-run: %w", err)
	}

	if logoE2ETrim(c.Module) != ModuleFAZ78L {
		return fmt.Errorf("invalid module: %s", c.Module)
	}
	if logoE2ETrim(c.Step) != StepFAZ78L9 {
		return fmt.Errorf("invalid step: %s", c.Step)
	}
	if logoE2ETrim(c.ProviderCode) != ProviderCode {
		return fmt.Errorf("invalid provider code: %s", c.ProviderCode)
	}
	if logoE2ETrim(c.RuntimeMode) != RuntimeModeDryRun {
		return fmt.Errorf("invalid runtime mode: %s", c.RuntimeMode)
	}
	if logoE2ETrim(c.E2EMode) != LogoE2EDryRunMode {
		return fmt.Errorf("invalid E2E mode: %s", c.E2EMode)
	}
	if logoE2ETrim(c.TargetSystem) != LogoTargetSystem {
		return fmt.Errorf("invalid target system: %s", c.TargetSystem)
	}
	if logoE2ETrim(c.E2EStatus) != LogoE2EDryRunStatus {
		return fmt.Errorf("invalid E2E status: %s", c.E2EStatus)
	}
	if !c.RealIntegrationsClosed() {
		return errors.New("real Logo provider API, file delivery, and ERP write must remain closed")
	}
	if err := c.Rules.Validate(); err != nil {
		return err
	}
	if err := c.ValidateOperations(); err != nil {
		return err
	}
	return nil
}

func (c LogoE2EDryRunContract) RealIntegrationsClosed() bool {
	return logoE2ETrim(c.RealProviderAPIStatus) == RealProviderAPIClosedStatus &&
		logoE2ETrim(c.RealFileDeliveryStatus) == RealFileDeliveryClosedStatus &&
		logoE2ETrim(c.RealERPWriteStatus) == RealERPWriteClosedStatus
}

func (c LogoE2EDryRunContract) ValidateOperations() error {
	requiredOperations := []LogoE2EDryRunOperationName{
		LogoOperationDeclareE2EDryRunContract,
		LogoOperationRunE2EDryRunSuccessFlow,
		LogoOperationRunE2EValidationFlow,
		LogoOperationRunE2ERetryDecisionFlow,
		LogoOperationRunE2EManualReviewFlow,
		LogoOperationValidateE2EChainDependencies,
		LogoOperationValidateE2ENoRealProviderAPI,
		LogoOperationValidateE2ENoRealFileDelivery,
		LogoOperationValidateE2ENoERPWrite,
		LogoOperationPrepareFinalClosureHandoff,
	}

	for _, operationName := range requiredOperations {
		operation, ok := c.Operation(operationName)
		if !ok {
			return fmt.Errorf("missing required operation: %s", operationName)
		}
		if operation.Mode != LogoE2EDryRunMode {
			return fmt.Errorf("operation %s must use E2E dry-run mode", operationName)
		}
		if !operation.DryRunE2EAllowed {
			return fmt.Errorf("operation %s must allow E2E dry-run", operationName)
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

func (c LogoE2EDryRunContract) Operation(name LogoE2EDryRunOperationName) (LogoE2EDryRunOperationContract, bool) {
	for _, operation := range c.Operations {
		if operation.Name == name {
			return operation, true
		}
	}
	return LogoE2EDryRunOperationContract{}, false
}

func (c LogoE2EDryRunContract) RunSuccessfulDryRunFlow(input LogoDryRunExportInput, expectedTenantID string) (LogoE2EDryRunResult, error) {
	if err := c.Validate(); err != nil {
		return LogoE2EDryRunResult{}, err
	}
	if logoE2ETrim(expectedTenantID) == "" {
		expectedTenantID = input.Header.TenantID
	}

	fileGeneration := NewLogoFileGenerationContract()
	pkg, err := fileGeneration.GenerateDryRunImportPackage(input)
	if err != nil {
		return c.validationFailureResultFromInput(input, expectedTenantID, classifyLogoE2EInputError(input, expectedTenantID)), nil
	}

	importDelivery := NewLogoImportDeliveryContract()
	envelope, err := importDelivery.PrepareDryRunDeliveryEnvelope(LogoDeliveryChannelManualUpload, pkg)
	if err != nil {
		return c.validationFailureResultFromPackage(pkg, classifyLogoE2EPackageError(pkg)), nil
	}

	validation := NewLogoValidationRetryDLQContract()
	validationResult := validation.ValidateEnvelope(envelope, expectedTenantID)
	if !validationResult.Valid {
		decision := validation.Decide(validationResult.Errors[0].Code, 0)
		return LogoE2EDryRunResult{
			FlowID:                    fmt.Sprintf("logo-e2e:%s:%s", envelope.TenantID, envelope.IdempotencyKey),
			FlowType:                  LogoE2EFlowValidationFailureToDLQ,
			TenantID:                  envelope.TenantID,
			CorrelationID:             envelope.CorrelationID,
			IdempotencyKey:            envelope.IdempotencyKey,
			PackageID:                 envelope.PackageID,
			DeliveryID:                envelope.DeliveryID,
			ValidationAction:          decision.Action,
			FinalAction:               decision.Action,
			DLQDecisionCreated:        decision.DLQ,
			ManualReviewCreated:       decision.ManualReview,
			Steps:                     c.defaultSteps(),
			DryRunOnly:                true,
			RealProviderAPICalled:     false,
			RealFileDeliveryAttempted: false,
			ERPWriteAttempted:         false,
		}, nil
	}

	result := LogoE2EDryRunResult{
		FlowID:                    fmt.Sprintf("logo-e2e:%s:%s", envelope.TenantID, envelope.IdempotencyKey),
		FlowType:                  LogoE2EFlowSuccessfulDryRun,
		TenantID:                  envelope.TenantID,
		CorrelationID:             envelope.CorrelationID,
		IdempotencyKey:            envelope.IdempotencyKey,
		PackageID:                 envelope.PackageID,
		DeliveryID:                envelope.DeliveryID,
		ValidationAction:          LogoDecisionPass,
		FinalAction:               LogoDecisionPass,
		Steps:                     c.defaultSteps(),
		DryRunOnly:                true,
		RealProviderAPICalled:     false,
		RealFileDeliveryAttempted: false,
		ERPWriteAttempted:         false,
	}

	if err := result.ValidateNoRealSideEffects(); err != nil {
		return LogoE2EDryRunResult{}, err
	}

	return result, nil
}

func (c LogoE2EDryRunContract) RunManualReviewDryRunFlow(input LogoDryRunExportInput) (LogoE2EDryRunResult, error) {
	if err := c.Validate(); err != nil {
		return LogoE2EDryRunResult{}, err
	}

	fileGeneration := NewLogoFileGenerationContract()
	pkg, err := fileGeneration.GenerateDryRunImportPackage(input)
	if err != nil {
		return LogoE2EDryRunResult{}, err
	}

	importDelivery := NewLogoImportDeliveryContract()
	envelope, err := importDelivery.PrepareDryRunDeliveryEnvelope(LogoDeliveryChannelManualUpload, pkg)
	if err != nil {
		return LogoE2EDryRunResult{}, err
	}

	validation := NewLogoValidationRetryDLQContract()
	decision := validation.Decide(LogoErrorUnknownProvider, 0)

	item, err := NewLogoManualReviewItemFromDecision(envelope, decision, "logo-e2e-dry-run")
	if err != nil {
		return LogoE2EDryRunResult{}, err
	}

	adminOpsRuntime := NewLogoAdminOpsRuntime()
	created, err := adminOpsRuntime.CreateManualReviewItem(item)
	if err != nil {
		return LogoE2EDryRunResult{}, err
	}

	result := LogoE2EDryRunResult{
		FlowID:                    fmt.Sprintf("logo-e2e-manual-review:%s:%s", envelope.TenantID, envelope.IdempotencyKey),
		FlowType:                  LogoE2EFlowManualReview,
		TenantID:                  envelope.TenantID,
		CorrelationID:             envelope.CorrelationID,
		IdempotencyKey:            envelope.IdempotencyKey,
		PackageID:                 envelope.PackageID,
		DeliveryID:                envelope.DeliveryID,
		ValidationAction:          decision.Action,
		FinalAction:               decision.Action,
		ManualReviewCreated:       true,
		ManualReviewID:            created.ReviewID,
		Steps:                     c.defaultSteps(),
		DryRunOnly:                true,
		RealProviderAPICalled:     false,
		RealFileDeliveryAttempted: false,
		ERPWriteAttempted:         false,
	}

	if err := result.ValidateNoRealSideEffects(); err != nil {
		return LogoE2EDryRunResult{}, err
	}

	return result, nil
}

func (c LogoE2EDryRunContract) RunRetryDecisionDryRunFlow(code LogoErrorCode, currentAttempt int) (LogoRetryDecision, error) {
	if err := c.Validate(); err != nil {
		return LogoRetryDecision{}, err
	}

	validation := NewLogoValidationRetryDLQContract()
	return validation.Decide(code, currentAttempt), nil
}

func (c LogoE2EDryRunContract) validationFailureResultFromInput(input LogoDryRunExportInput, expectedTenantID string, code LogoErrorCode) LogoE2EDryRunResult {
	validation := NewLogoValidationRetryDLQContract()
	decision := validation.Decide(code, 0)

	tenantID := input.Header.TenantID
	if logoE2ETrim(tenantID) == "" {
		tenantID = expectedTenantID
	}
	if logoE2ETrim(tenantID) == "" {
		tenantID = "unknown_tenant"
	}

	correlationID := input.Header.CorrelationID
	if logoE2ETrim(correlationID) == "" {
		correlationID = "missing_correlation_id"
	}

	idempotencyKey := input.Header.IdempotencyKey
	if logoE2ETrim(idempotencyKey) == "" {
		idempotencyKey = "missing_idempotency_key"
	}

	return LogoE2EDryRunResult{
		FlowID:                    fmt.Sprintf("logo-e2e-validation-failure:%s:%s", tenantID, idempotencyKey),
		FlowType:                  LogoE2EFlowValidationFailureToDLQ,
		TenantID:                  tenantID,
		CorrelationID:             correlationID,
		IdempotencyKey:            idempotencyKey,
		ValidationAction:          decision.Action,
		FinalAction:               decision.Action,
		DLQDecisionCreated:        decision.DLQ,
		ManualReviewCreated:       decision.ManualReview,
		Steps:                     c.defaultSteps(),
		DryRunOnly:                true,
		RealProviderAPICalled:     false,
		RealFileDeliveryAttempted: false,
		ERPWriteAttempted:         false,
	}
}

func (c LogoE2EDryRunContract) validationFailureResultFromPackage(pkg LogoDryRunImportPackage, code LogoErrorCode) LogoE2EDryRunResult {
	validation := NewLogoValidationRetryDLQContract()
	decision := validation.Decide(code, 0)

	return LogoE2EDryRunResult{
		FlowID:                    fmt.Sprintf("logo-e2e-validation-failure:%s:%s", pkg.TenantID, pkg.IdempotencyKey),
		FlowType:                  LogoE2EFlowValidationFailureToDLQ,
		TenantID:                  pkg.TenantID,
		CorrelationID:             pkg.CorrelationID,
		IdempotencyKey:            pkg.IdempotencyKey,
		PackageID:                 pkg.PackageID,
		ValidationAction:          decision.Action,
		FinalAction:               decision.Action,
		DLQDecisionCreated:        decision.DLQ,
		ManualReviewCreated:       decision.ManualReview,
		Steps:                     c.defaultSteps(),
		DryRunOnly:                true,
		RealProviderAPICalled:     false,
		RealFileDeliveryAttempted: false,
		ERPWriteAttempted:         false,
	}
}

func classifyLogoE2EInputError(input LogoDryRunExportInput, expectedTenantID string) LogoErrorCode {
	if logoE2ETrim(input.Header.TenantID) == "" {
		return LogoErrorMissingTenantID
	}
	if logoE2ETrim(input.Header.CorrelationID) == "" {
		return LogoErrorMissingCorrelationID
	}
	if logoE2ETrim(input.Header.IdempotencyKey) == "" {
		return LogoErrorMissingIdempotencyKey
	}
	if logoE2ETrim(expectedTenantID) != "" && input.Header.TenantID != expectedTenantID {
		return LogoErrorTenantBoundaryViolation
	}
	return LogoErrorInvalidManifest
}

func classifyLogoE2EPackageError(pkg LogoDryRunImportPackage) LogoErrorCode {
	if logoE2ETrim(pkg.TenantID) == "" {
		return LogoErrorMissingTenantID
	}
	if logoE2ETrim(pkg.CorrelationID) == "" {
		return LogoErrorMissingCorrelationID
	}
	if logoE2ETrim(pkg.IdempotencyKey) == "" {
		return LogoErrorMissingIdempotencyKey
	}
	if len(pkg.Manifest) == 0 {
		return LogoErrorInvalidManifest
	}
	return LogoErrorInvalidManifest
}

func (c LogoE2EDryRunContract) defaultSteps() []string {
	return []string{
		"FOUNDATION_VALIDATED",
		"LIVE_CONTRACT_VALIDATED",
		"CREDENTIAL_CONTRACT_VALIDATED",
		"EXPORT_MAPPING_VALIDATED",
		"FILE_GENERATION_DRY_RUN_COMPLETED",
		"IMPORT_DELIVERY_ENVELOPE_PREPARED",
		"VALIDATION_RETRY_DLQ_EVALUATED",
		"ADMIN_OPS_MANUAL_REVIEW_EVALUATED",
		"NO_REAL_PROVIDER_API_CALLED",
		"NO_REAL_FILE_DELIVERY_ATTEMPTED",
		"NO_ERP_WRITE_ATTEMPTED",
	}
}

func (r LogoE2EDryRunResult) ValidateNoRealSideEffects() error {
	if !r.DryRunOnly {
		return errors.New("E2E result must be dry-run only")
	}
	if r.RealProviderAPICalled {
		return errors.New("real provider API must not be called")
	}
	if r.RealFileDeliveryAttempted {
		return errors.New("real file delivery must not be attempted")
	}
	if r.ERPWriteAttempted {
		return errors.New("ERP write must not be attempted")
	}
	if logoE2ETrim(r.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if logoE2ETrim(r.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if logoE2ETrim(r.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if logoE2ETrim(r.FinalAction) == "" {
		return errors.New("final action is required")
	}
	return nil
}

func (r LogoE2EDryRunResult) HasStep(step string) bool {
	for _, item := range r.Steps {
		if item == step {
			return true
		}
	}
	return false
}

func (r LogoE2EDryRunResult) ValidateRequiredSteps() error {
	required := []string{
		"FOUNDATION_VALIDATED",
		"LIVE_CONTRACT_VALIDATED",
		"CREDENTIAL_CONTRACT_VALIDATED",
		"EXPORT_MAPPING_VALIDATED",
		"FILE_GENERATION_DRY_RUN_COMPLETED",
		"IMPORT_DELIVERY_ENVELOPE_PREPARED",
		"VALIDATION_RETRY_DLQ_EVALUATED",
		"ADMIN_OPS_MANUAL_REVIEW_EVALUATED",
		"NO_REAL_PROVIDER_API_CALLED",
		"NO_REAL_FILE_DELIVERY_ATTEMPTED",
		"NO_ERP_WRITE_ATTEMPTED",
	}

	for _, step := range required {
		if !r.HasStep(step) {
			return fmt.Errorf("missing E2E step: %s", step)
		}
	}
	return nil
}

func (r LogoE2EDryRunContractRules) Validate() error {
	if !r.Declared {
		return errors.New("E2E contract must be declared")
	}
	if logoE2ETrim(r.Status) != LogoE2EDryRunStatus {
		return fmt.Errorf("invalid E2E contract status: %s", r.Status)
	}
	if !r.DryRunOnly {
		return errors.New("E2E contract must be dry-run only")
	}
	if !r.ChainDependencyValidationRequired {
		return errors.New("chain dependency validation must be required")
	}
	if !r.SuccessfulFlowRequired {
		return errors.New("successful flow must be required")
	}
	if !r.ValidationFailureFlowRequired {
		return errors.New("validation failure flow must be required")
	}
	if !r.RetryDecisionFlowRequired {
		return errors.New("retry decision flow must be required")
	}
	if !r.ManualReviewFlowRequired {
		return errors.New("manual review flow must be required")
	}
	if r.ExternalCallAllowed {
		return errors.New("external call must not be allowed")
	}
	if r.RealFileDeliveryAllowed {
		return errors.New("real file delivery must not be allowed")
	}
	if r.ERPWriteAllowed {
		return errors.New("ERP write must not be allowed")
	}
	return nil
}

func logoE2ETrim(value string) string {
	return strings.TrimSpace(value)
}
