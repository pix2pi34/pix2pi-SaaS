package logo

import (
	"errors"
	"fmt"
	"strings"
)

const (
	StepFAZ78L6 = "FAZ_7_8L.6"

	LogoImportDeliveryMode           = "IMPORT_PACKAGE_DELIVERY_CONTRACT_ONLY"
	LogoImportDeliveryContractStatus = "READY"
	LogoDeliveryContractStatus       = "DECLARED_DRY_RUN_ONLY"
	LogoDeliveryChannelStatus        = "PLACEHOLDER_ONLY"
	LogoRealDeliveryChannelStatus    = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
	LogoDeliveryEnvelopeStatus       = "DRY_RUN_DELIVERY_CONTRACT_READY"
)

type LogoDeliveryChannelName string

const (
	LogoDeliveryChannelManualUpload LogoDeliveryChannelName = "MANUAL_UPLOAD_PLACEHOLDER"
	LogoDeliveryChannelSFTP         LogoDeliveryChannelName = "SFTP_PLACEHOLDER"
	LogoDeliveryChannelProviderAPI  LogoDeliveryChannelName = "PROVIDER_API_PLACEHOLDER"
)

type LogoImportDeliveryOperationName string

const (
	LogoOperationDeclareImportDeliveryContract      LogoImportDeliveryOperationName = "DECLARE_LOGO_IMPORT_DELIVERY_CONTRACT"
	LogoOperationDeclareDeliveryChannelPlaceholders LogoImportDeliveryOperationName = "DECLARE_LOGO_DELIVERY_CHANNEL_PLACEHOLDERS"
	LogoOperationValidateDryRunPackageForDelivery   LogoImportDeliveryOperationName = "VALIDATE_LOGO_DRY_RUN_PACKAGE_FOR_DELIVERY"
	LogoOperationPrepareDryRunDeliveryEnvelope      LogoImportDeliveryOperationName = "PREPARE_LOGO_DRY_RUN_DELIVERY_ENVELOPE"
	LogoOperationValidateNoRealImportDelivery       LogoImportDeliveryOperationName = "VALIDATE_LOGO_NO_REAL_DELIVERY"
	LogoOperationValidateDeliveryTenantBoundary     LogoImportDeliveryOperationName = "VALIDATE_LOGO_DELIVERY_TENANT_BOUNDARY"
	LogoOperationPrepareValidationRetryDLQHandoff   LogoImportDeliveryOperationName = "PREPARE_LOGO_VALIDATION_RETRY_DLQ_HANDOFF"
)

type LogoDeliveryChannel struct {
	Name                LogoDeliveryChannelName `json:"name"`
	Status              string                  `json:"status"`
	DryRunOnly          bool                    `json:"dry_run_only"`
	RealDeliveryAllowed bool                    `json:"real_delivery_allowed"`
	ExternalCallAllowed bool                    `json:"external_call_allowed"`
	RequiresApproval    bool                    `json:"requires_approval"`
}

type LogoDeliveryContract struct {
	Declared               bool   `json:"declared"`
	Status                 string `json:"status"`
	DryRunOnly             bool   `json:"dry_run_only"`
	RealDeliveryAllowed    bool   `json:"real_delivery_allowed"`
	ExternalCallAllowed    bool   `json:"external_call_allowed"`
	ERPWriteAllowed        bool   `json:"erp_write_allowed"`
	ChecksumRequired       bool   `json:"checksum_required"`
	ManifestRequired       bool   `json:"manifest_required"`
	TenantScopeRequired    bool   `json:"tenant_scope_required"`
	CorrelationIDRequired  bool   `json:"correlation_id_required"`
	IdempotencyKeyRequired bool   `json:"idempotency_key_required"`
}

type LogoImportDeliveryOperationContract struct {
	Name                          LogoImportDeliveryOperationName `json:"name"`
	Mode                          string                          `json:"mode"`
	DryRunDeliveryContractAllowed bool                            `json:"dry_run_delivery_contract_allowed"`
	ExternalCallAllowed           bool                            `json:"external_call_allowed"`
	RealFileDeliveryAllowed       bool                            `json:"real_file_delivery_allowed"`
	ERPWriteAllowed               bool                            `json:"erp_write_allowed"`
}

type LogoImportDeliveryContract struct {
	Module                    string                                `json:"module"`
	Step                      string                                `json:"step"`
	ProviderCode              string                                `json:"provider_code"`
	ProviderName              string                                `json:"provider_name"`
	ConnectorCode             string                                `json:"connector_code"`
	ConnectorFamily           string                                `json:"connector_family"`
	RuntimeMode               string                                `json:"runtime_mode"`
	DeliveryMode              string                                `json:"delivery_mode"`
	TargetSystem              string                                `json:"target_system"`
	ImportDeliveryStatus      string                                `json:"import_delivery_contract_status"`
	RealProviderAPIStatus     string                                `json:"real_provider_api_status"`
	RealFileDeliveryStatus    string                                `json:"real_file_delivery_status"`
	RealERPWriteStatus        string                                `json:"real_erp_write_status"`
	RealDeliveryChannelStatus string                                `json:"real_delivery_channel_status"`
	DeliveryContract          LogoDeliveryContract                  `json:"delivery_contract"`
	DeliveryChannels          []LogoDeliveryChannel                 `json:"delivery_channels"`
	Operations                []LogoImportDeliveryOperationContract `json:"operations"`
}

type LogoImportDeliveryEnvelope struct {
	DeliveryID          string                  `json:"delivery_id"`
	PackageID           string                  `json:"package_id"`
	TenantID            string                  `json:"tenant_id"`
	CorrelationID       string                  `json:"correlation_id"`
	IdempotencyKey      string                  `json:"idempotency_key"`
	Channel             LogoDeliveryChannelName `json:"channel"`
	Status              string                  `json:"status"`
	FileName            string                  `json:"file_name"`
	ChecksumSHA256      string                  `json:"checksum_sha256"`
	Manifest            []string                `json:"manifest"`
	DryRunOnly          bool                    `json:"dry_run_only"`
	DeliveryAllowed     bool                    `json:"delivery_allowed"`
	ExternalCallAllowed bool                    `json:"external_call_allowed"`
	ERPWriteAllowed     bool                    `json:"erp_write_allowed"`
}

func NewLogoImportDeliveryContract() LogoImportDeliveryContract {
	return LogoImportDeliveryContract{
		Module:                    ModuleFAZ78L,
		Step:                      StepFAZ78L6,
		ProviderCode:              ProviderCode,
		ProviderName:              ProviderName,
		ConnectorCode:             ConnectorCode,
		ConnectorFamily:           ConnectorFamily,
		RuntimeMode:               RuntimeModeDryRun,
		DeliveryMode:              LogoImportDeliveryMode,
		TargetSystem:              LogoTargetSystem,
		ImportDeliveryStatus:      LogoImportDeliveryContractStatus,
		RealProviderAPIStatus:     RealProviderAPIClosedStatus,
		RealFileDeliveryStatus:    RealFileDeliveryClosedStatus,
		RealERPWriteStatus:        RealERPWriteClosedStatus,
		RealDeliveryChannelStatus: LogoRealDeliveryChannelStatus,
		DeliveryContract: LogoDeliveryContract{
			Declared:               true,
			Status:                 LogoDeliveryContractStatus,
			DryRunOnly:             true,
			RealDeliveryAllowed:    false,
			ExternalCallAllowed:    false,
			ERPWriteAllowed:        false,
			ChecksumRequired:       true,
			ManifestRequired:       true,
			TenantScopeRequired:    true,
			CorrelationIDRequired:  true,
			IdempotencyKeyRequired: true,
		},
		DeliveryChannels: []LogoDeliveryChannel{
			{Name: LogoDeliveryChannelManualUpload, Status: LogoDeliveryChannelStatus, DryRunOnly: true, RealDeliveryAllowed: false, ExternalCallAllowed: false, RequiresApproval: true},
			{Name: LogoDeliveryChannelSFTP, Status: LogoDeliveryChannelStatus, DryRunOnly: true, RealDeliveryAllowed: false, ExternalCallAllowed: false, RequiresApproval: true},
			{Name: LogoDeliveryChannelProviderAPI, Status: LogoDeliveryChannelStatus, DryRunOnly: true, RealDeliveryAllowed: false, ExternalCallAllowed: false, RequiresApproval: true},
		},
		Operations: []LogoImportDeliveryOperationContract{
			{Name: LogoOperationDeclareImportDeliveryContract, Mode: LogoImportDeliveryMode, DryRunDeliveryContractAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationDeclareDeliveryChannelPlaceholders, Mode: LogoImportDeliveryMode, DryRunDeliveryContractAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateDryRunPackageForDelivery, Mode: LogoImportDeliveryMode, DryRunDeliveryContractAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationPrepareDryRunDeliveryEnvelope, Mode: LogoImportDeliveryMode, DryRunDeliveryContractAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateNoRealImportDelivery, Mode: LogoImportDeliveryMode, DryRunDeliveryContractAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateDeliveryTenantBoundary, Mode: LogoImportDeliveryMode, DryRunDeliveryContractAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationPrepareValidationRetryDLQHandoff, Mode: LogoImportDeliveryMode, DryRunDeliveryContractAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
		},
	}
}

func (c LogoImportDeliveryContract) Validate() error {
	fileGeneration := NewLogoFileGenerationContract()
	if err := fileGeneration.Validate(); err != nil {
		return fmt.Errorf("logo file generation dry-run must be valid before import delivery contract: %w", err)
	}

	if importDeliveryTrim(c.Module) != ModuleFAZ78L {
		return fmt.Errorf("invalid module: %s", c.Module)
	}
	if importDeliveryTrim(c.Step) != StepFAZ78L6 {
		return fmt.Errorf("invalid step: %s", c.Step)
	}
	if importDeliveryTrim(c.ProviderCode) != ProviderCode {
		return fmt.Errorf("invalid provider code: %s", c.ProviderCode)
	}
	if strings.TrimSpace(c.ProviderName) != ProviderName {
		return fmt.Errorf("invalid provider name: %s", c.ProviderName)
	}
	if importDeliveryTrim(c.ConnectorCode) != ConnectorCode {
		return fmt.Errorf("invalid connector code: %s", c.ConnectorCode)
	}
	if importDeliveryTrim(c.ConnectorFamily) != ConnectorFamily {
		return fmt.Errorf("invalid connector family: %s", c.ConnectorFamily)
	}
	if importDeliveryTrim(c.RuntimeMode) != RuntimeModeDryRun {
		return fmt.Errorf("invalid runtime mode: %s", c.RuntimeMode)
	}
	if importDeliveryTrim(c.DeliveryMode) != LogoImportDeliveryMode {
		return fmt.Errorf("invalid delivery mode: %s", c.DeliveryMode)
	}
	if importDeliveryTrim(c.TargetSystem) != LogoTargetSystem {
		return fmt.Errorf("invalid target system: %s", c.TargetSystem)
	}
	if importDeliveryTrim(c.ImportDeliveryStatus) != LogoImportDeliveryContractStatus {
		return fmt.Errorf("invalid import delivery status: %s", c.ImportDeliveryStatus)
	}
	if !c.RealIntegrationsClosed() {
		return errors.New("real Logo provider API, real file delivery, delivery channel, and ERP write must remain closed")
	}
	if err := c.DeliveryContract.Validate(); err != nil {
		return err
	}
	if err := c.ValidateDeliveryChannels(); err != nil {
		return err
	}
	if err := c.ValidateOperations(); err != nil {
		return err
	}
	return nil
}

func (c LogoImportDeliveryContract) RealIntegrationsClosed() bool {
	return importDeliveryTrim(c.RealProviderAPIStatus) == RealProviderAPIClosedStatus &&
		importDeliveryTrim(c.RealFileDeliveryStatus) == RealFileDeliveryClosedStatus &&
		importDeliveryTrim(c.RealERPWriteStatus) == RealERPWriteClosedStatus &&
		importDeliveryTrim(c.RealDeliveryChannelStatus) == LogoRealDeliveryChannelStatus
}

func (c LogoImportDeliveryContract) ValidateDeliveryChannels() error {
	requiredChannels := []LogoDeliveryChannelName{
		LogoDeliveryChannelManualUpload,
		LogoDeliveryChannelSFTP,
		LogoDeliveryChannelProviderAPI,
	}

	for _, required := range requiredChannels {
		channel, ok := c.DeliveryChannel(required)
		if !ok {
			return fmt.Errorf("missing required delivery channel: %s", required)
		}
		if err := channel.Validate(); err != nil {
			return fmt.Errorf("invalid delivery channel %s: %w", required, err)
		}
	}
	return nil
}

func (c LogoImportDeliveryContract) ValidateOperations() error {
	requiredOperations := []LogoImportDeliveryOperationName{
		LogoOperationDeclareImportDeliveryContract,
		LogoOperationDeclareDeliveryChannelPlaceholders,
		LogoOperationValidateDryRunPackageForDelivery,
		LogoOperationPrepareDryRunDeliveryEnvelope,
		LogoOperationValidateNoRealImportDelivery,
		LogoOperationValidateDeliveryTenantBoundary,
		LogoOperationPrepareValidationRetryDLQHandoff,
	}

	for _, operationName := range requiredOperations {
		operation, ok := c.Operation(operationName)
		if !ok {
			return fmt.Errorf("missing required operation: %s", operationName)
		}
		if operation.Mode != LogoImportDeliveryMode {
			return fmt.Errorf("operation %s must use import delivery contract mode", operationName)
		}
		if !operation.DryRunDeliveryContractAllowed {
			return fmt.Errorf("operation %s must allow dry-run delivery contract", operationName)
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

func (c LogoImportDeliveryContract) DeliveryChannel(name LogoDeliveryChannelName) (LogoDeliveryChannel, bool) {
	for _, channel := range c.DeliveryChannels {
		if channel.Name == name {
			return channel, true
		}
	}
	return LogoDeliveryChannel{}, false
}

func (c LogoImportDeliveryContract) Operation(name LogoImportDeliveryOperationName) (LogoImportDeliveryOperationContract, bool) {
	for _, operation := range c.Operations {
		if operation.Name == name {
			return operation, true
		}
	}
	return LogoImportDeliveryOperationContract{}, false
}

func (c LogoImportDeliveryContract) PrepareDryRunDeliveryEnvelope(channelName LogoDeliveryChannelName, pkg LogoDryRunImportPackage) (LogoImportDeliveryEnvelope, error) {
	if err := c.Validate(); err != nil {
		return LogoImportDeliveryEnvelope{}, err
	}
	if err := pkg.Validate(); err != nil {
		return LogoImportDeliveryEnvelope{}, err
	}

	channel, ok := c.DeliveryChannel(channelName)
	if !ok {
		return LogoImportDeliveryEnvelope{}, fmt.Errorf("unknown delivery channel: %s", channelName)
	}
	if err := channel.Validate(); err != nil {
		return LogoImportDeliveryEnvelope{}, err
	}

	envelope := LogoImportDeliveryEnvelope{
		DeliveryID:          fmt.Sprintf("logo-delivery-dry-run:%s:%s", pkg.TenantID, pkg.IdempotencyKey),
		PackageID:           pkg.PackageID,
		TenantID:            pkg.TenantID,
		CorrelationID:       pkg.CorrelationID,
		IdempotencyKey:      pkg.IdempotencyKey,
		Channel:             channel.Name,
		Status:              LogoDeliveryEnvelopeStatus,
		FileName:            pkg.GeneratedFile.FileName,
		ChecksumSHA256:      pkg.GeneratedFile.ChecksumSHA256,
		Manifest:            append([]string{}, pkg.Manifest...),
		DryRunOnly:          true,
		DeliveryAllowed:     false,
		ExternalCallAllowed: false,
		ERPWriteAllowed:     false,
	}

	if err := envelope.Validate(); err != nil {
		return LogoImportDeliveryEnvelope{}, err
	}

	return envelope, nil
}

func (d LogoDeliveryContract) Validate() error {
	if !d.Declared {
		return errors.New("delivery contract must be declared")
	}
	if importDeliveryTrim(d.Status) != LogoDeliveryContractStatus {
		return fmt.Errorf("invalid delivery contract status: %s", d.Status)
	}
	if !d.DryRunOnly {
		return errors.New("delivery contract must be dry-run only")
	}
	if d.RealDeliveryAllowed {
		return errors.New("real delivery must not be allowed")
	}
	if d.ExternalCallAllowed {
		return errors.New("external call must not be allowed")
	}
	if d.ERPWriteAllowed {
		return errors.New("ERP write must not be allowed")
	}
	if !d.ChecksumRequired {
		return errors.New("checksum must be required")
	}
	if !d.ManifestRequired {
		return errors.New("manifest must be required")
	}
	if !d.TenantScopeRequired {
		return errors.New("tenant scope must be required")
	}
	if !d.CorrelationIDRequired {
		return errors.New("correlation id must be required")
	}
	if !d.IdempotencyKeyRequired {
		return errors.New("idempotency key must be required")
	}
	return nil
}

func (c LogoDeliveryChannel) Validate() error {
	if importDeliveryTrim(string(c.Name)) == "" {
		return errors.New("delivery channel name is required")
	}
	if importDeliveryTrim(c.Status) != LogoDeliveryChannelStatus {
		return fmt.Errorf("invalid delivery channel status: %s", c.Status)
	}
	if !c.DryRunOnly {
		return errors.New("delivery channel must be dry-run only")
	}
	if c.RealDeliveryAllowed {
		return errors.New("delivery channel must not allow real delivery")
	}
	if c.ExternalCallAllowed {
		return errors.New("delivery channel must not allow external calls")
	}
	if !c.RequiresApproval {
		return errors.New("delivery channel must require approval")
	}
	return nil
}

func (e LogoImportDeliveryEnvelope) Validate() error {
	if importDeliveryTrim(e.DeliveryID) == "" {
		return errors.New("delivery_id is required")
	}
	if importDeliveryTrim(e.PackageID) == "" {
		return errors.New("package_id is required")
	}
	if importDeliveryTrim(e.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if importDeliveryTrim(e.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if importDeliveryTrim(e.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if importDeliveryTrim(string(e.Channel)) == "" {
		return errors.New("channel is required")
	}
	if importDeliveryTrim(e.Status) != LogoDeliveryEnvelopeStatus {
		return fmt.Errorf("invalid delivery envelope status: %s", e.Status)
	}
	if importDeliveryTrim(e.FileName) == "" {
		return errors.New("file_name is required")
	}
	if importDeliveryTrim(e.ChecksumSHA256) == "" {
		return errors.New("checksum_sha256 is required")
	}
	if len(e.Manifest) == 0 {
		return errors.New("manifest is required")
	}
	if !e.DryRunOnly {
		return errors.New("delivery envelope must be dry-run only")
	}
	if e.DeliveryAllowed {
		return errors.New("delivery must not be allowed")
	}
	if e.ExternalCallAllowed {
		return errors.New("external call must not be allowed")
	}
	if e.ERPWriteAllowed {
		return errors.New("ERP write must not be allowed")
	}
	return nil
}

func importDeliveryTrim(value string) string {
	return strings.TrimSpace(value)
}
