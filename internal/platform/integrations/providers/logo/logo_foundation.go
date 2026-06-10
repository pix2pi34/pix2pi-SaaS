package logo

import (
	"errors"
	"fmt"
	"strings"
)

const (
	ModuleFAZ78L = "FAZ_7_8L"
	StepFAZ78L1  = "FAZ_7_8L.1"

	ProviderCode    = "LOGO"
	ProviderName    = "Logo"
	ConnectorCode   = "logo_connector"
	ConnectorFamily = "accounting_export_connector"

	RuntimeModeDryRun = "DRY_RUN"

	RealProviderAPIClosedStatus   = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
	RealFileDeliveryClosedStatus  = "CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE"
	RealERPWriteClosedStatus      = "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
	OperationModeDryRunOnly       = "DRY_RUN_ONLY"
	ProviderLiveHandoffGateStatus = "PENDING_7_8L_10"
)

type Capability string

const (
	CapabilityExportMappingContract    Capability = "EXPORT_MAPPING_CONTRACT"
	CapabilityFileGenerationDryRun     Capability = "FILE_GENERATION_DRY_RUN"
	CapabilityImportPackagePreparation Capability = "IMPORT_PACKAGE_PREPARATION"
	CapabilityValidationErrorMapping   Capability = "VALIDATION_ERROR_MAPPING"
	CapabilityRetryDLQReadiness        Capability = "RETRY_DLQ_READINESS"
	CapabilityAdminOpsManualReview     Capability = "ADMIN_OPS_MANUAL_REVIEW"
	CapabilityE2EDryRunFlow            Capability = "E2E_DRY_RUN_FLOW"
	CapabilityProviderLiveHandoffGate  Capability = "PROVIDER_LIVE_HANDOFF_GATE"
)

type OperationName string

const (
	OperationBuildExportModel        OperationName = "BUILD_EXPORT_MODEL"
	OperationGenerateLogoDryRunFile  OperationName = "GENERATE_LOGO_DRY_RUN_FILE"
	OperationPrepareImportPackage    OperationName = "PREPARE_IMPORT_PACKAGE"
	OperationValidateImportPackage   OperationName = "VALIDATE_IMPORT_PACKAGE"
	OperationMapLogoError            OperationName = "MAP_LOGO_ERROR"
	OperationCreateManualReviewItem  OperationName = "CREATE_MANUAL_REVIEW_ITEM"
	OperationRunE2EDryRun            OperationName = "RUN_E2E_DRY_RUN"
	OperationPrepareProviderLiveGate OperationName = "PREPARE_PROVIDER_LIVE_HANDOFF"
)

type ProviderIdentity struct {
	Module                        string       `json:"module"`
	Step                          string       `json:"step"`
	ProviderCode                  string       `json:"provider_code"`
	ProviderName                  string       `json:"provider_name"`
	ConnectorCode                 string       `json:"connector_code"`
	ConnectorFamily               string       `json:"connector_family"`
	RuntimeMode                   string       `json:"runtime_mode"`
	RealProviderAPIStatus         string       `json:"real_provider_api_status"`
	RealFileDeliveryStatus        string       `json:"real_file_delivery_status"`
	RealERPWriteStatus            string       `json:"real_erp_write_status"`
	Capabilities                  []Capability `json:"capabilities"`
	Operations                    []Operation  `json:"operations"`
	ProviderLiveHandoffGateStatus string       `json:"provider_live_handoff_gate_status"`
}

type Operation struct {
	Name                OperationName `json:"name"`
	Mode                string        `json:"mode"`
	ExternalCallAllowed bool          `json:"external_call_allowed"`
	ERPWriteAllowed     bool          `json:"erp_write_allowed"`
}

func NewProviderIdentity() ProviderIdentity {
	return ProviderIdentity{
		Module:                 ModuleFAZ78L,
		Step:                   StepFAZ78L1,
		ProviderCode:           ProviderCode,
		ProviderName:           ProviderName,
		ConnectorCode:          ConnectorCode,
		ConnectorFamily:        ConnectorFamily,
		RuntimeMode:            RuntimeModeDryRun,
		RealProviderAPIStatus:  RealProviderAPIClosedStatus,
		RealFileDeliveryStatus: RealFileDeliveryClosedStatus,
		RealERPWriteStatus:     RealERPWriteClosedStatus,
		Capabilities: []Capability{
			CapabilityExportMappingContract,
			CapabilityFileGenerationDryRun,
			CapabilityImportPackagePreparation,
			CapabilityValidationErrorMapping,
			CapabilityRetryDLQReadiness,
			CapabilityAdminOpsManualReview,
			CapabilityE2EDryRunFlow,
			CapabilityProviderLiveHandoffGate,
		},
		Operations: []Operation{
			{Name: OperationBuildExportModel, Mode: OperationModeDryRunOnly, ExternalCallAllowed: false, ERPWriteAllowed: false},
			{Name: OperationGenerateLogoDryRunFile, Mode: OperationModeDryRunOnly, ExternalCallAllowed: false, ERPWriteAllowed: false},
			{Name: OperationPrepareImportPackage, Mode: OperationModeDryRunOnly, ExternalCallAllowed: false, ERPWriteAllowed: false},
			{Name: OperationValidateImportPackage, Mode: OperationModeDryRunOnly, ExternalCallAllowed: false, ERPWriteAllowed: false},
			{Name: OperationMapLogoError, Mode: OperationModeDryRunOnly, ExternalCallAllowed: false, ERPWriteAllowed: false},
			{Name: OperationCreateManualReviewItem, Mode: OperationModeDryRunOnly, ExternalCallAllowed: false, ERPWriteAllowed: false},
			{Name: OperationRunE2EDryRun, Mode: OperationModeDryRunOnly, ExternalCallAllowed: false, ERPWriteAllowed: false},
			{Name: OperationPrepareProviderLiveGate, Mode: OperationModeDryRunOnly, ExternalCallAllowed: false, ERPWriteAllowed: false},
		},
		ProviderLiveHandoffGateStatus: ProviderLiveHandoffGateStatus,
	}
}

func (p ProviderIdentity) Validate() error {
	if normalize(p.Module) != ModuleFAZ78L {
		return fmt.Errorf("invalid module: %s", p.Module)
	}
	if normalize(p.Step) != StepFAZ78L1 {
		return fmt.Errorf("invalid step: %s", p.Step)
	}
	if normalize(p.ProviderCode) != ProviderCode {
		return fmt.Errorf("invalid provider code: %s", p.ProviderCode)
	}
	if strings.TrimSpace(p.ProviderName) != ProviderName {
		return fmt.Errorf("invalid provider name: %s", p.ProviderName)
	}
	if normalize(p.ConnectorCode) != ConnectorCode {
		return fmt.Errorf("invalid connector code: %s", p.ConnectorCode)
	}
	if normalize(p.ConnectorFamily) != ConnectorFamily {
		return fmt.Errorf("invalid connector family: %s", p.ConnectorFamily)
	}
	if normalize(p.RuntimeMode) != RuntimeModeDryRun {
		return fmt.Errorf("invalid runtime mode: %s", p.RuntimeMode)
	}
	if !p.RealIntegrationsClosed() {
		return errors.New("real Logo provider API, file delivery, and ERP write must remain closed")
	}

	requiredCapabilities := []Capability{
		CapabilityExportMappingContract,
		CapabilityFileGenerationDryRun,
		CapabilityImportPackagePreparation,
		CapabilityValidationErrorMapping,
		CapabilityRetryDLQReadiness,
		CapabilityAdminOpsManualReview,
		CapabilityE2EDryRunFlow,
		CapabilityProviderLiveHandoffGate,
	}

	for _, capability := range requiredCapabilities {
		if !p.HasCapability(capability) {
			return fmt.Errorf("missing required capability: %s", capability)
		}
	}

	requiredOperations := []OperationName{
		OperationBuildExportModel,
		OperationGenerateLogoDryRunFile,
		OperationPrepareImportPackage,
		OperationValidateImportPackage,
		OperationMapLogoError,
		OperationCreateManualReviewItem,
		OperationRunE2EDryRun,
		OperationPrepareProviderLiveGate,
	}

	for _, operationName := range requiredOperations {
		operation, ok := p.Operation(operationName)
		if !ok {
			return fmt.Errorf("missing required operation: %s", operationName)
		}
		if operation.Mode != OperationModeDryRunOnly {
			return fmt.Errorf("operation %s must be dry-run only", operationName)
		}
		if operation.ExternalCallAllowed {
			return fmt.Errorf("operation %s must not allow external calls", operationName)
		}
		if operation.ERPWriteAllowed {
			return fmt.Errorf("operation %s must not allow ERP writes", operationName)
		}
	}

	return nil
}

func (p ProviderIdentity) RealIntegrationsClosed() bool {
	return normalize(p.RealProviderAPIStatus) == RealProviderAPIClosedStatus &&
		normalize(p.RealFileDeliveryStatus) == RealFileDeliveryClosedStatus &&
		normalize(p.RealERPWriteStatus) == RealERPWriteClosedStatus
}

func (p ProviderIdentity) HasCapability(capability Capability) bool {
	for _, item := range p.Capabilities {
		if item == capability {
			return true
		}
	}
	return false
}

func (p ProviderIdentity) Operation(name OperationName) (Operation, bool) {
	for _, operation := range p.Operations {
		if operation.Name == name {
			return operation, true
		}
	}
	return Operation{}, false
}

func (p ProviderIdentity) DryRunOperationNames() []OperationName {
	names := make([]OperationName, 0, len(p.Operations))
	for _, operation := range p.Operations {
		if operation.Mode == OperationModeDryRunOnly && !operation.ExternalCallAllowed && !operation.ERPWriteAllowed {
			names = append(names, operation.Name)
		}
	}
	return names
}

func normalize(value string) string {
	return strings.TrimSpace(value)
}
