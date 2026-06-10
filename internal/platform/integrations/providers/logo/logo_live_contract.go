package logo

import (
	"errors"
	"fmt"
	"strings"
)

const (
	StepFAZ78L2 = "FAZ_7_8L.2"

	LogoLiveContractMode = "DRY_RUN_CONTRACT_ONLY"

	LogoAPIContractStatus  = "DECLARED_DRY_RUN_ONLY"
	LogoFileContractStatus = "DECLARED_DRY_RUN_ONLY"
)

type LogoLiveOperationName string

const (
	LogoOperationDeclareAPIContract               LogoLiveOperationName = "DECLARE_LOGO_API_CONTRACT"
	LogoOperationDeclareFileContract              LogoLiveOperationName = "DECLARE_LOGO_FILE_CONTRACT"
	LogoOperationValidateLiveContract             LogoLiveOperationName = "VALIDATE_LOGO_LIVE_CONTRACT"
	LogoOperationPrepareAuthReferenceRequirements LogoLiveOperationName = "PREPARE_LOGO_AUTH_REFERENCE_REQUIREMENTS"
	LogoOperationPrepareImportPackageContract     LogoLiveOperationName = "PREPARE_LOGO_IMPORT_PACKAGE_CONTRACT"
	LogoOperationPrepareLiveHandoffRequirements   LogoLiveOperationName = "PREPARE_LOGO_LIVE_HANDOFF_REQUIREMENTS"
)

type LogoAPIEndpoint struct {
	Name         string `json:"name"`
	Method       string `json:"method"`
	PathTemplate string `json:"path_template"`
	DryRunOnly   bool   `json:"dry_run_only"`
}

type LogoAPIContract struct {
	Declared                     bool              `json:"declared"`
	Status                       string            `json:"status"`
	BaseURLRequiredForLiveModule bool              `json:"base_url_required_for_live_module"`
	AuthReferenceRequired        bool              `json:"auth_reference_required"`
	TenantScopeRequired          bool              `json:"tenant_scope_required"`
	IdempotencyKeyRequired       bool              `json:"idempotency_key_required"`
	CorrelationIDRequired        bool              `json:"correlation_id_required"`
	RealCallAllowed              bool              `json:"real_call_allowed"`
	Endpoints                    []LogoAPIEndpoint `json:"endpoints"`
}

type LogoFileContract struct {
	Declared                        bool     `json:"declared"`
	Status                          string   `json:"status"`
	ImportPackageValidationRequired bool     `json:"import_package_validation_required"`
	TenantScopeRequired             bool     `json:"tenant_scope_required"`
	IdempotencyKeyRequired          bool     `json:"idempotency_key_required"`
	CorrelationIDRequired           bool     `json:"correlation_id_required"`
	FileChecksumRequired            bool     `json:"file_checksum_required"`
	RealFileDeliveryAllowed         bool     `json:"real_file_delivery_allowed"`
	Formats                         []string `json:"formats"`
	DeliveryChannels                []string `json:"delivery_channels"`
}

type LogoLiveOperationContract struct {
	Name                LogoLiveOperationName `json:"name"`
	Mode                string                `json:"mode"`
	ExternalCallAllowed bool                  `json:"external_call_allowed"`
	FileDeliveryAllowed bool                  `json:"file_delivery_allowed"`
	ERPWriteAllowed     bool                  `json:"erp_write_allowed"`
}

type LogoLiveContract struct {
	Module                 string                      `json:"module"`
	Step                   string                      `json:"step"`
	ProviderCode           string                      `json:"provider_code"`
	ProviderName           string                      `json:"provider_name"`
	ConnectorCode          string                      `json:"connector_code"`
	ConnectorFamily        string                      `json:"connector_family"`
	RuntimeMode            string                      `json:"runtime_mode"`
	ContractMode           string                      `json:"contract_mode"`
	RealProviderAPIStatus  string                      `json:"real_provider_api_status"`
	RealFileDeliveryStatus string                      `json:"real_file_delivery_status"`
	RealERPWriteStatus     string                      `json:"real_erp_write_status"`
	APIContract            LogoAPIContract             `json:"api_contract"`
	FileContract           LogoFileContract            `json:"file_contract"`
	Operations             []LogoLiveOperationContract `json:"operations"`
}

func NewLogoLiveContract() LogoLiveContract {
	return LogoLiveContract{
		Module:                 ModuleFAZ78L,
		Step:                   StepFAZ78L2,
		ProviderCode:           ProviderCode,
		ProviderName:           ProviderName,
		ConnectorCode:          ConnectorCode,
		ConnectorFamily:        ConnectorFamily,
		RuntimeMode:            RuntimeModeDryRun,
		ContractMode:           LogoLiveContractMode,
		RealProviderAPIStatus:  RealProviderAPIClosedStatus,
		RealFileDeliveryStatus: RealFileDeliveryClosedStatus,
		RealERPWriteStatus:     RealERPWriteClosedStatus,
		APIContract: LogoAPIContract{
			Declared:                     true,
			Status:                       LogoAPIContractStatus,
			BaseURLRequiredForLiveModule: true,
			AuthReferenceRequired:        true,
			TenantScopeRequired:          true,
			IdempotencyKeyRequired:       true,
			CorrelationIDRequired:        true,
			RealCallAllowed:              false,
			Endpoints: []LogoAPIEndpoint{
				{Name: "LOGO_AUTH_CHECK", Method: "GET", PathTemplate: "/live-module-provider-specific/auth/check", DryRunOnly: true},
				{Name: "LOGO_IMPORT_PACKAGE_STATUS", Method: "GET", PathTemplate: "/live-module-provider-specific/import-packages/{package_id}/status", DryRunOnly: true},
				{Name: "LOGO_IMPORT_PACKAGE_SUBMIT", Method: "POST", PathTemplate: "/live-module-provider-specific/import-packages", DryRunOnly: true},
			},
		},
		FileContract: LogoFileContract{
			Declared:                        true,
			Status:                          LogoFileContractStatus,
			ImportPackageValidationRequired: true,
			TenantScopeRequired:             true,
			IdempotencyKeyRequired:          true,
			CorrelationIDRequired:           true,
			FileChecksumRequired:            true,
			RealFileDeliveryAllowed:         false,
			Formats: []string{
				"LOGO_ACCOUNTING_EXPORT_DRY_RUN",
				"LOGO_IMPORT_PACKAGE_DRY_RUN",
			},
			DeliveryChannels: []string{
				"MANUAL_UPLOAD_PLACEHOLDER",
				"SFTP_PLACEHOLDER",
				"PROVIDER_API_PLACEHOLDER",
			},
		},
		Operations: []LogoLiveOperationContract{
			{Name: LogoOperationDeclareAPIContract, Mode: LogoLiveContractMode, ExternalCallAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationDeclareFileContract, Mode: LogoLiveContractMode, ExternalCallAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateLiveContract, Mode: LogoLiveContractMode, ExternalCallAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationPrepareAuthReferenceRequirements, Mode: LogoLiveContractMode, ExternalCallAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationPrepareImportPackageContract, Mode: LogoLiveContractMode, ExternalCallAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationPrepareLiveHandoffRequirements, Mode: LogoLiveContractMode, ExternalCallAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false},
		},
	}
}

func (c LogoLiveContract) Validate() error {
	foundation := NewProviderIdentity()
	if err := foundation.Validate(); err != nil {
		return fmt.Errorf("logo foundation must be valid before live contract readiness: %w", err)
	}

	if liveTrim(c.Module) != ModuleFAZ78L {
		return fmt.Errorf("invalid module: %s", c.Module)
	}
	if liveTrim(c.Step) != StepFAZ78L2 {
		return fmt.Errorf("invalid step: %s", c.Step)
	}
	if liveTrim(c.ProviderCode) != ProviderCode {
		return fmt.Errorf("invalid provider code: %s", c.ProviderCode)
	}
	if strings.TrimSpace(c.ProviderName) != ProviderName {
		return fmt.Errorf("invalid provider name: %s", c.ProviderName)
	}
	if liveTrim(c.ConnectorCode) != ConnectorCode {
		return fmt.Errorf("invalid connector code: %s", c.ConnectorCode)
	}
	if liveTrim(c.ConnectorFamily) != ConnectorFamily {
		return fmt.Errorf("invalid connector family: %s", c.ConnectorFamily)
	}
	if liveTrim(c.RuntimeMode) != RuntimeModeDryRun {
		return fmt.Errorf("invalid runtime mode: %s", c.RuntimeMode)
	}
	if liveTrim(c.ContractMode) != LogoLiveContractMode {
		return fmt.Errorf("invalid contract mode: %s", c.ContractMode)
	}
	if !c.RealIntegrationsClosed() {
		return errors.New("real Logo provider API, file delivery, and ERP write must remain closed")
	}
	if err := c.APIContract.Validate(); err != nil {
		return fmt.Errorf("invalid API contract: %w", err)
	}
	if err := c.FileContract.Validate(); err != nil {
		return fmt.Errorf("invalid file contract: %w", err)
	}

	requiredOperations := []LogoLiveOperationName{
		LogoOperationDeclareAPIContract,
		LogoOperationDeclareFileContract,
		LogoOperationValidateLiveContract,
		LogoOperationPrepareAuthReferenceRequirements,
		LogoOperationPrepareImportPackageContract,
		LogoOperationPrepareLiveHandoffRequirements,
	}

	for _, operationName := range requiredOperations {
		operation, ok := c.Operation(operationName)
		if !ok {
			return fmt.Errorf("missing required operation: %s", operationName)
		}
		if operation.Mode != LogoLiveContractMode {
			return fmt.Errorf("operation %s must use dry-run contract mode", operationName)
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
	}

	return nil
}

func (c LogoLiveContract) RealIntegrationsClosed() bool {
	return liveTrim(c.RealProviderAPIStatus) == RealProviderAPIClosedStatus &&
		liveTrim(c.RealFileDeliveryStatus) == RealFileDeliveryClosedStatus &&
		liveTrim(c.RealERPWriteStatus) == RealERPWriteClosedStatus
}

func (c LogoLiveContract) Operation(name LogoLiveOperationName) (LogoLiveOperationContract, bool) {
	for _, operation := range c.Operations {
		if operation.Name == name {
			return operation, true
		}
	}
	return LogoLiveOperationContract{}, false
}

func (a LogoAPIContract) Validate() error {
	if !a.Declared {
		return errors.New("API contract must be declared")
	}
	if liveTrim(a.Status) != LogoAPIContractStatus {
		return fmt.Errorf("invalid API contract status: %s", a.Status)
	}
	if !a.BaseURLRequiredForLiveModule {
		return errors.New("API base URL must be required for live module")
	}
	if !a.AuthReferenceRequired {
		return errors.New("API auth reference must be required")
	}
	if !a.TenantScopeRequired {
		return errors.New("API tenant scope must be required")
	}
	if !a.IdempotencyKeyRequired {
		return errors.New("API idempotency key must be required")
	}
	if !a.CorrelationIDRequired {
		return errors.New("API correlation id must be required")
	}
	if a.RealCallAllowed {
		return errors.New("real API call must not be allowed in dry-run contract readiness")
	}
	if len(a.Endpoints) == 0 {
		return errors.New("API contract endpoints must be declared")
	}
	for _, endpoint := range a.Endpoints {
		if strings.TrimSpace(endpoint.Name) == "" {
			return errors.New("API endpoint name is required")
		}
		if strings.TrimSpace(endpoint.Method) == "" {
			return fmt.Errorf("API endpoint %s method is required", endpoint.Name)
		}
		if strings.TrimSpace(endpoint.PathTemplate) == "" {
			return fmt.Errorf("API endpoint %s path template is required", endpoint.Name)
		}
		if !endpoint.DryRunOnly {
			return fmt.Errorf("API endpoint %s must be dry-run only", endpoint.Name)
		}
	}
	return nil
}

func (f LogoFileContract) Validate() error {
	if !f.Declared {
		return errors.New("file contract must be declared")
	}
	if liveTrim(f.Status) != LogoFileContractStatus {
		return fmt.Errorf("invalid file contract status: %s", f.Status)
	}
	if !f.ImportPackageValidationRequired {
		return errors.New("import package validation must be required")
	}
	if !f.TenantScopeRequired {
		return errors.New("file contract tenant scope must be required")
	}
	if !f.IdempotencyKeyRequired {
		return errors.New("file contract idempotency key must be required")
	}
	if !f.CorrelationIDRequired {
		return errors.New("file contract correlation id must be required")
	}
	if !f.FileChecksumRequired {
		return errors.New("file checksum must be required")
	}
	if f.RealFileDeliveryAllowed {
		return errors.New("real file delivery must not be allowed in dry-run contract readiness")
	}
	if len(f.Formats) == 0 {
		return errors.New("file formats must be declared")
	}
	if len(f.DeliveryChannels) == 0 {
		return errors.New("delivery channels must be declared")
	}
	return nil
}

func liveTrim(value string) string {
	return strings.TrimSpace(value)
}
