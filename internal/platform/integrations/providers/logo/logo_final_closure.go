package logo

import (
	"errors"
	"fmt"
	"strings"
)

const (
	StepFAZ78L10 = "FAZ_7_8L.10"

	LogoFinalClosureMode               = "FINAL_CLOSURE_PROVIDER_LIVE_HANDOFF_GATE"
	LogoFinalClosureStatus             = "PASS"
	LogoConnectorModuleFinalSealStatus = "SEALED"
	LogoDryRunModuleStatus             = "SEALED"
	LogoProviderLiveHandoffGate        = "READY_FOR_PROVIDER_LIVE_MODULE"
	LogoProviderLiveRequirementPending = "PENDING_PROVIDER_LIVE_MODULE"
	LogoFAZ79HoldStatus                = "HOLD_UNTIL_INTEGRATION_FAMILY_DONE"
	LogoNextProviderModuleReadyStatus  = "YES"
)

type LogoFinalClosureOperationName string

const (
	LogoOperationDeclareFinalClosureContract             LogoFinalClosureOperationName = "DECLARE_LOGO_FINAL_CLOSURE_CONTRACT"
	LogoOperationValidateModuleChainSeals                LogoFinalClosureOperationName = "VALIDATE_LOGO_MODULE_CHAIN_SEALS"
	LogoOperationValidateDryRunE2ESeal                   LogoFinalClosureOperationName = "VALIDATE_LOGO_DRY_RUN_E2E_SEAL"
	LogoOperationSealDryRunModule                        LogoFinalClosureOperationName = "SEAL_LOGO_DRY_RUN_MODULE"
	LogoOperationDeclareProviderLiveHandoffGate          LogoFinalClosureOperationName = "DECLARE_LOGO_PROVIDER_LIVE_HANDOFF_GATE"
	LogoOperationValidateProviderLivePrerequisiteHolders LogoFinalClosureOperationName = "VALIDATE_LOGO_PROVIDER_LIVE_PREREQUISITES_PLACEHOLDERS"
	LogoOperationValidateNoRealProviderAPIFinalClosure   LogoFinalClosureOperationName = "VALIDATE_LOGO_NO_REAL_PROVIDER_API"
	LogoOperationValidateNoRealFileDeliveryFinalClosure  LogoFinalClosureOperationName = "VALIDATE_LOGO_NO_REAL_FILE_DELIVERY"
	LogoOperationValidateNoERPWriteFinalClosure          LogoFinalClosureOperationName = "VALIDATE_LOGO_NO_ERP_WRITE"
	LogoOperationReturnToFAZ78IntegrationFamily          LogoFinalClosureOperationName = "RETURN_TO_FAZ_7_8_INTEGRATION_FAMILY"
)

type LogoRequiredStepSeal struct {
	Step     string `json:"step"`
	Gate     string `json:"gate"`
	Status   string `json:"status"`
	Required bool   `json:"required"`
}

type LogoProviderLiveHandoffRequirements struct {
	LegalApprovalStatus                 string `json:"legal_approval_status"`
	FinanceApprovalStatus               string `json:"finance_approval_status"`
	SecurityApprovalStatus              string `json:"security_approval_status"`
	ProviderDocumentationApprovalStatus string `json:"provider_documentation_approval_status"`
	SecretVaultApprovalStatus           string `json:"secret_vault_approval_status"`
	LiveCredentialInjectionStatus       string `json:"live_credential_injection_status"`
	LiveFileDeliveryApprovalStatus      string `json:"live_file_delivery_approval_status"`
	RollbackPlanApprovalStatus          string `json:"rollback_plan_approval_status"`
	IncidentResponseApprovalStatus      string `json:"incident_response_approval_status"`
	MonitoringAlertingApprovalStatus    string `json:"monitoring_alerting_approval_status"`
	TenantPilotApprovalStatus           string `json:"tenant_pilot_approval_status"`
}

type LogoFinalClosureRules struct {
	Declared                        bool   `json:"declared"`
	Status                          string `json:"status"`
	DryRunOnly                      bool   `json:"dry_run_only"`
	ModuleSealRequired              bool   `json:"module_seal_required"`
	ProviderLiveHandoffGateRequired bool   `json:"provider_live_handoff_gate_required"`
	ExternalCallAllowed             bool   `json:"external_call_allowed"`
	RealFileDeliveryAllowed         bool   `json:"real_file_delivery_allowed"`
	ERPWriteAllowed                 bool   `json:"erp_write_allowed"`
	RealProviderLiveAllowed         bool   `json:"real_provider_live_allowed"`
}

type LogoFinalClosureOperationContract struct {
	Name                    LogoFinalClosureOperationName `json:"name"`
	Mode                    string                        `json:"mode"`
	FinalClosureAllowed     bool                          `json:"final_closure_allowed"`
	ExternalCallAllowed     bool                          `json:"external_call_allowed"`
	RealFileDeliveryAllowed bool                          `json:"real_file_delivery_allowed"`
	ERPWriteAllowed         bool                          `json:"erp_write_allowed"`
	RealProviderLiveAllowed bool                          `json:"real_provider_live_allowed"`
}

type LogoFinalClosureContract struct {
	Module                    string                              `json:"module"`
	Step                      string                              `json:"step"`
	ProviderCode              string                              `json:"provider_code"`
	ProviderName              string                              `json:"provider_name"`
	ConnectorCode             string                              `json:"connector_code"`
	ConnectorFamily           string                              `json:"connector_family"`
	RuntimeMode               string                              `json:"runtime_mode"`
	ClosureMode               string                              `json:"closure_mode"`
	TargetSystem              string                              `json:"target_system"`
	FinalClosureStatus        string                              `json:"final_closure_status"`
	ModuleFinalSealStatus     string                              `json:"module_final_seal_status"`
	DryRunModuleStatus        string                              `json:"dry_run_module_status"`
	ProviderLiveHandoffGate   string                              `json:"provider_live_handoff_gate"`
	RealProviderAPIStatus     string                              `json:"real_provider_api_status"`
	RealFileDeliveryStatus    string                              `json:"real_file_delivery_status"`
	RealERPWriteStatus        string                              `json:"real_erp_write_status"`
	RealSecretValueStatus     string                              `json:"real_secret_value_status"`
	RealDeliveryChannelStatus string                              `json:"real_delivery_channel_status"`
	FAZ79HoldStatus           string                              `json:"faz_7_9_hold_status"`
	NextProviderModuleReady   string                              `json:"faz_7_8_next_provider_module_ready"`
	RequiredStepSeals         []LogoRequiredStepSeal              `json:"required_step_seals"`
	ProviderLiveRequirements  LogoProviderLiveHandoffRequirements `json:"provider_live_handoff_requirements"`
	Rules                     LogoFinalClosureRules               `json:"final_closure_contract"`
	Operations                []LogoFinalClosureOperationContract `json:"operations"`
}

type LogoFinalClosureSummary struct {
	ProviderCode            string   `json:"provider_code"`
	ModuleFinalSealStatus   string   `json:"module_final_seal_status"`
	ProviderLiveHandoffGate string   `json:"provider_live_handoff_gate"`
	RealProviderAPIStatus   string   `json:"real_provider_api_status"`
	RealFileDeliveryStatus  string   `json:"real_file_delivery_status"`
	RealERPWriteStatus      string   `json:"real_erp_write_status"`
	FAZ79HoldStatus         string   `json:"faz_7_9_hold_status"`
	NextProviderModuleReady string   `json:"faz_7_8_next_provider_module_ready"`
	SealedSteps             []string `json:"sealed_steps"`
}

func NewLogoFinalClosureContract() LogoFinalClosureContract {
	return LogoFinalClosureContract{
		Module:                    ModuleFAZ78L,
		Step:                      StepFAZ78L10,
		ProviderCode:              ProviderCode,
		ProviderName:              ProviderName,
		ConnectorCode:             ConnectorCode,
		ConnectorFamily:           ConnectorFamily,
		RuntimeMode:               RuntimeModeDryRun,
		ClosureMode:               LogoFinalClosureMode,
		TargetSystem:              LogoTargetSystem,
		FinalClosureStatus:        LogoFinalClosureStatus,
		ModuleFinalSealStatus:     LogoConnectorModuleFinalSealStatus,
		DryRunModuleStatus:        LogoDryRunModuleStatus,
		ProviderLiveHandoffGate:   LogoProviderLiveHandoffGate,
		RealProviderAPIStatus:     RealProviderAPIClosedStatus,
		RealFileDeliveryStatus:    RealFileDeliveryClosedStatus,
		RealERPWriteStatus:        RealERPWriteClosedStatus,
		RealSecretValueStatus:     LogoRealSecretValueStatus,
		RealDeliveryChannelStatus: LogoRealDeliveryChannelStatus,
		FAZ79HoldStatus:           LogoFAZ79HoldStatus,
		NextProviderModuleReady:   LogoNextProviderModuleReadyStatus,
		RequiredStepSeals: []LogoRequiredStepSeal{
			{Step: "FAZ_7_8L.1", Gate: "LOGO_CONNECTOR_FOUNDATION_GATE", Status: "READY", Required: true},
			{Step: "FAZ_7_8L.2", Gate: "LOGO_LIVE_CONTRACT_GATE", Status: "READY", Required: true},
			{Step: "FAZ_7_8L.3", Gate: "LOGO_CREDENTIAL_SECRET_REFERENCE_GATE", Status: "READY", Required: true},
			{Step: "FAZ_7_8L.4", Gate: "LOGO_EXPORT_MAPPING_GATE", Status: "READY", Required: true},
			{Step: "FAZ_7_8L.5", Gate: "LOGO_FILE_GENERATION_GATE", Status: "READY", Required: true},
			{Step: "FAZ_7_8L.6", Gate: "LOGO_IMPORT_DELIVERY_GATE", Status: "READY", Required: true},
			{Step: "FAZ_7_8L.7", Gate: "LOGO_VALIDATION_RETRY_DLQ_GATE", Status: "READY", Required: true},
			{Step: "FAZ_7_8L.8", Gate: "LOGO_ADMIN_OPS_GATE", Status: "READY", Required: true},
			{Step: "FAZ_7_8L.9", Gate: "LOGO_E2E_DRY_RUN_GATE", Status: "READY", Required: true},
		},
		ProviderLiveRequirements: LogoProviderLiveHandoffRequirements{
			LegalApprovalStatus:                 LogoProviderLiveRequirementPending,
			FinanceApprovalStatus:               LogoProviderLiveRequirementPending,
			SecurityApprovalStatus:              LogoProviderLiveRequirementPending,
			ProviderDocumentationApprovalStatus: LogoProviderLiveRequirementPending,
			SecretVaultApprovalStatus:           LogoProviderLiveRequirementPending,
			LiveCredentialInjectionStatus:       LogoProviderLiveRequirementPending,
			LiveFileDeliveryApprovalStatus:      LogoProviderLiveRequirementPending,
			RollbackPlanApprovalStatus:          LogoProviderLiveRequirementPending,
			IncidentResponseApprovalStatus:      LogoProviderLiveRequirementPending,
			MonitoringAlertingApprovalStatus:    LogoProviderLiveRequirementPending,
			TenantPilotApprovalStatus:           LogoProviderLiveRequirementPending,
		},
		Rules: LogoFinalClosureRules{
			Declared:                        true,
			Status:                          LogoFinalClosureStatus,
			DryRunOnly:                      true,
			ModuleSealRequired:              true,
			ProviderLiveHandoffGateRequired: true,
			ExternalCallAllowed:             false,
			RealFileDeliveryAllowed:         false,
			ERPWriteAllowed:                 false,
			RealProviderLiveAllowed:         false,
		},
		Operations: []LogoFinalClosureOperationContract{
			{Name: LogoOperationDeclareFinalClosureContract, Mode: LogoFinalClosureMode, FinalClosureAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false, RealProviderLiveAllowed: false},
			{Name: LogoOperationValidateModuleChainSeals, Mode: LogoFinalClosureMode, FinalClosureAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false, RealProviderLiveAllowed: false},
			{Name: LogoOperationValidateDryRunE2ESeal, Mode: LogoFinalClosureMode, FinalClosureAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false, RealProviderLiveAllowed: false},
			{Name: LogoOperationSealDryRunModule, Mode: LogoFinalClosureMode, FinalClosureAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false, RealProviderLiveAllowed: false},
			{Name: LogoOperationDeclareProviderLiveHandoffGate, Mode: LogoFinalClosureMode, FinalClosureAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false, RealProviderLiveAllowed: false},
			{Name: LogoOperationValidateProviderLivePrerequisiteHolders, Mode: LogoFinalClosureMode, FinalClosureAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false, RealProviderLiveAllowed: false},
			{Name: LogoOperationValidateNoRealProviderAPIFinalClosure, Mode: LogoFinalClosureMode, FinalClosureAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false, RealProviderLiveAllowed: false},
			{Name: LogoOperationValidateNoRealFileDeliveryFinalClosure, Mode: LogoFinalClosureMode, FinalClosureAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false, RealProviderLiveAllowed: false},
			{Name: LogoOperationValidateNoERPWriteFinalClosure, Mode: LogoFinalClosureMode, FinalClosureAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false, RealProviderLiveAllowed: false},
			{Name: LogoOperationReturnToFAZ78IntegrationFamily, Mode: LogoFinalClosureMode, FinalClosureAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false, RealProviderLiveAllowed: false},
		},
	}
}

func (c LogoFinalClosureContract) Validate() error {
	e2e := NewLogoE2EDryRunContract()
	if err := e2e.Validate(); err != nil {
		return fmt.Errorf("logo E2E dry-run must be valid before final closure: %w", err)
	}

	if finalClosureTrim(c.Module) != ModuleFAZ78L {
		return fmt.Errorf("invalid module: %s", c.Module)
	}
	if finalClosureTrim(c.Step) != StepFAZ78L10 {
		return fmt.Errorf("invalid step: %s", c.Step)
	}
	if finalClosureTrim(c.ProviderCode) != ProviderCode {
		return fmt.Errorf("invalid provider code: %s", c.ProviderCode)
	}
	if finalClosureTrim(c.RuntimeMode) != RuntimeModeDryRun {
		return fmt.Errorf("invalid runtime mode: %s", c.RuntimeMode)
	}
	if finalClosureTrim(c.ClosureMode) != LogoFinalClosureMode {
		return fmt.Errorf("invalid closure mode: %s", c.ClosureMode)
	}
	if finalClosureTrim(c.TargetSystem) != LogoTargetSystem {
		return fmt.Errorf("invalid target system: %s", c.TargetSystem)
	}
	if finalClosureTrim(c.FinalClosureStatus) != LogoFinalClosureStatus {
		return fmt.Errorf("invalid final closure status: %s", c.FinalClosureStatus)
	}
	if finalClosureTrim(c.ModuleFinalSealStatus) != LogoConnectorModuleFinalSealStatus {
		return fmt.Errorf("invalid module final seal status: %s", c.ModuleFinalSealStatus)
	}
	if finalClosureTrim(c.ProviderLiveHandoffGate) != LogoProviderLiveHandoffGate {
		return fmt.Errorf("invalid provider live handoff gate: %s", c.ProviderLiveHandoffGate)
	}
	if !c.RealIntegrationsClosed() {
		return errors.New("real Logo provider API, file delivery, ERP write, secret values, and delivery channel must remain closed")
	}
	if err := c.ValidateRequiredStepSeals(); err != nil {
		return err
	}
	if err := c.ProviderLiveRequirements.Validate(); err != nil {
		return err
	}
	if err := c.Rules.Validate(); err != nil {
		return err
	}
	if err := c.ValidateOperations(); err != nil {
		return err
	}
	return nil
}

func (c LogoFinalClosureContract) RealIntegrationsClosed() bool {
	return finalClosureTrim(c.RealProviderAPIStatus) == RealProviderAPIClosedStatus &&
		finalClosureTrim(c.RealFileDeliveryStatus) == RealFileDeliveryClosedStatus &&
		finalClosureTrim(c.RealERPWriteStatus) == RealERPWriteClosedStatus &&
		finalClosureTrim(c.RealSecretValueStatus) == LogoRealSecretValueStatus &&
		finalClosureTrim(c.RealDeliveryChannelStatus) == LogoRealDeliveryChannelStatus
}

func (c LogoFinalClosureContract) ValidateRequiredStepSeals() error {
	requiredSteps := []string{
		"FAZ_7_8L.1",
		"FAZ_7_8L.2",
		"FAZ_7_8L.3",
		"FAZ_7_8L.4",
		"FAZ_7_8L.5",
		"FAZ_7_8L.6",
		"FAZ_7_8L.7",
		"FAZ_7_8L.8",
		"FAZ_7_8L.9",
	}

	for _, step := range requiredSteps {
		seal, ok := c.RequiredStepSeal(step)
		if !ok {
			return fmt.Errorf("missing required step seal: %s", step)
		}
		if err := seal.Validate(); err != nil {
			return fmt.Errorf("invalid required step seal %s: %w", step, err)
		}
	}
	return nil
}

func (c LogoFinalClosureContract) RequiredStepSeal(step string) (LogoRequiredStepSeal, bool) {
	for _, seal := range c.RequiredStepSeals {
		if seal.Step == step {
			return seal, true
		}
	}
	return LogoRequiredStepSeal{}, false
}

func (c LogoFinalClosureContract) ValidateOperations() error {
	requiredOperations := []LogoFinalClosureOperationName{
		LogoOperationDeclareFinalClosureContract,
		LogoOperationValidateModuleChainSeals,
		LogoOperationValidateDryRunE2ESeal,
		LogoOperationSealDryRunModule,
		LogoOperationDeclareProviderLiveHandoffGate,
		LogoOperationValidateProviderLivePrerequisiteHolders,
		LogoOperationValidateNoRealProviderAPIFinalClosure,
		LogoOperationValidateNoRealFileDeliveryFinalClosure,
		LogoOperationValidateNoERPWriteFinalClosure,
		LogoOperationReturnToFAZ78IntegrationFamily,
	}

	for _, operationName := range requiredOperations {
		operation, ok := c.Operation(operationName)
		if !ok {
			return fmt.Errorf("missing required operation: %s", operationName)
		}
		if operation.Mode != LogoFinalClosureMode {
			return fmt.Errorf("operation %s must use final closure mode", operationName)
		}
		if !operation.FinalClosureAllowed {
			return fmt.Errorf("operation %s must allow final closure", operationName)
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
		if operation.RealProviderLiveAllowed {
			return fmt.Errorf("operation %s must not allow real provider live", operationName)
		}
	}
	return nil
}

func (c LogoFinalClosureContract) Operation(name LogoFinalClosureOperationName) (LogoFinalClosureOperationContract, bool) {
	for _, operation := range c.Operations {
		if operation.Name == name {
			return operation, true
		}
	}
	return LogoFinalClosureOperationContract{}, false
}

func (c LogoFinalClosureContract) BuildSummary() (LogoFinalClosureSummary, error) {
	if err := c.Validate(); err != nil {
		return LogoFinalClosureSummary{}, err
	}

	sealedSteps := make([]string, 0, len(c.RequiredStepSeals))
	for _, seal := range c.RequiredStepSeals {
		sealedSteps = append(sealedSteps, seal.Step)
	}

	return LogoFinalClosureSummary{
		ProviderCode:            c.ProviderCode,
		ModuleFinalSealStatus:   c.ModuleFinalSealStatus,
		ProviderLiveHandoffGate: c.ProviderLiveHandoffGate,
		RealProviderAPIStatus:   c.RealProviderAPIStatus,
		RealFileDeliveryStatus:  c.RealFileDeliveryStatus,
		RealERPWriteStatus:      c.RealERPWriteStatus,
		FAZ79HoldStatus:         c.FAZ79HoldStatus,
		NextProviderModuleReady: c.NextProviderModuleReady,
		SealedSteps:             sealedSteps,
	}, nil
}

func (s LogoRequiredStepSeal) Validate() error {
	if finalClosureTrim(s.Step) == "" {
		return errors.New("step is required")
	}
	if finalClosureTrim(s.Gate) == "" {
		return errors.New("gate is required")
	}
	if finalClosureTrim(s.Status) != "READY" {
		return fmt.Errorf("step seal status must be READY: %s", s.Status)
	}
	if !s.Required {
		return errors.New("step seal must be required")
	}
	return nil
}

func (r LogoProviderLiveHandoffRequirements) Validate() error {
	statuses := []string{
		r.LegalApprovalStatus,
		r.FinanceApprovalStatus,
		r.SecurityApprovalStatus,
		r.ProviderDocumentationApprovalStatus,
		r.SecretVaultApprovalStatus,
		r.LiveCredentialInjectionStatus,
		r.LiveFileDeliveryApprovalStatus,
		r.RollbackPlanApprovalStatus,
		r.IncidentResponseApprovalStatus,
		r.MonitoringAlertingApprovalStatus,
		r.TenantPilotApprovalStatus,
	}

	for _, status := range statuses {
		if finalClosureTrim(status) != LogoProviderLiveRequirementPending {
			return fmt.Errorf("provider live requirement must remain pending provider live module: %s", status)
		}
	}
	return nil
}

func (r LogoFinalClosureRules) Validate() error {
	if !r.Declared {
		return errors.New("final closure contract must be declared")
	}
	if finalClosureTrim(r.Status) != LogoFinalClosureStatus {
		return fmt.Errorf("invalid final closure rule status: %s", r.Status)
	}
	if !r.DryRunOnly {
		return errors.New("final closure must be dry-run only")
	}
	if !r.ModuleSealRequired {
		return errors.New("module seal must be required")
	}
	if !r.ProviderLiveHandoffGateRequired {
		return errors.New("provider live handoff gate must be required")
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
	if r.RealProviderLiveAllowed {
		return errors.New("real provider live must not be allowed")
	}
	return nil
}

func finalClosureTrim(value string) string {
	return strings.TrimSpace(value)
}
