package logo

import (
	"errors"
	"fmt"
	"strings"
)

const (
	StepFAZ78L4 = "FAZ_7_8L.4"

	LogoExportMappingMode        = "EXPORT_MAPPING_CONTRACT_ONLY"
	LogoExportMappingStatus      = "DECLARED_DRY_RUN_ONLY"
	LogoMappingDirection         = "PIX2PI_TO_LOGO"
	LogoTargetSystem             = "LOGO_ACCOUNTING_IMPORT_DRY_RUN"
	LogoRealFileGenerationStatus = "CLOSED_UNTIL_FILE_GENERATION_DRY_RUN_MODULE"
)

type LogoExportMappingOperationName string

const (
	LogoOperationDeclareExportMapping          LogoExportMappingOperationName = "DECLARE_LOGO_EXPORT_MAPPING"
	LogoOperationValidateRequiredFields        LogoExportMappingOperationName = "VALIDATE_LOGO_REQUIRED_FIELDS"
	LogoOperationValidateTDHPAccountMapping    LogoExportMappingOperationName = "VALIDATE_LOGO_TDHP_ACCOUNT_MAPPING"
	LogoOperationValidateTaxMapping            LogoExportMappingOperationName = "VALIDATE_LOGO_TAX_MAPPING"
	LogoOperationValidateTenantMappingBoundary LogoExportMappingOperationName = "VALIDATE_LOGO_TENANT_MAPPING_BOUNDARY"
	LogoOperationPrepareFileGenerationHandoff  LogoExportMappingOperationName = "PREPARE_LOGO_FILE_GENERATION_HANDOFF"
	LogoOperationPrepareImportPackageHandoff   LogoExportMappingOperationName = "PREPARE_LOGO_IMPORT_PACKAGE_MAPPING_HANDOFF"
)

type LogoFieldMapping struct {
	SourceField string `json:"source_field"`
	TargetField string `json:"target_field"`
	Required    bool   `json:"required"`
	Transform   string `json:"transform"`
	Validation  string `json:"validation"`
}

type LogoEntityMapping struct {
	SourceEntity  string             `json:"source_entity"`
	TargetEntity  string             `json:"target_entity"`
	Required      bool               `json:"required"`
	FieldMappings []LogoFieldMapping `json:"field_mappings"`
}

type LogoTDHPMapping struct {
	RuleCode      string `json:"rule_code"`
	SourceEvent   string `json:"source_event"`
	VoucherType   string `json:"voucher_type"`
	DebitAccount  string `json:"debit_account"`
	CreditAccount string `json:"credit_account"`
	TaxAccount    string `json:"tax_account"`
	Currency      string `json:"currency"`
	TaxPolicy     string `json:"tax_policy"`
}

type LogoExportMappingOperationContract struct {
	Name                  LogoExportMappingOperationName `json:"name"`
	Mode                  string                         `json:"mode"`
	ExternalCallAllowed   bool                           `json:"external_call_allowed"`
	FileGenerationAllowed bool                           `json:"file_generation_allowed"`
	FileDeliveryAllowed   bool                           `json:"file_delivery_allowed"`
	ERPWriteAllowed       bool                           `json:"erp_write_allowed"`
}

type LogoExportMappingContract struct {
	Module                   string                               `json:"module"`
	Step                     string                               `json:"step"`
	ProviderCode             string                               `json:"provider_code"`
	ProviderName             string                               `json:"provider_name"`
	ConnectorCode            string                               `json:"connector_code"`
	ConnectorFamily          string                               `json:"connector_family"`
	RuntimeMode              string                               `json:"runtime_mode"`
	MappingMode              string                               `json:"mapping_mode"`
	MappingStatus            string                               `json:"mapping_status"`
	MappingDirection         string                               `json:"mapping_direction"`
	TargetSystem             string                               `json:"target_system"`
	RealProviderAPIStatus    string                               `json:"real_provider_api_status"`
	RealFileGenerationStatus string                               `json:"real_file_generation_status"`
	RealFileDeliveryStatus   string                               `json:"real_file_delivery_status"`
	RealERPWriteStatus       string                               `json:"real_erp_write_status"`
	EntityMappings           []LogoEntityMapping                  `json:"entity_mappings"`
	TDHPMappings             []LogoTDHPMapping                    `json:"tdhp_mappings"`
	Operations               []LogoExportMappingOperationContract `json:"operations"`
}

func NewLogoExportMappingContract() LogoExportMappingContract {
	return LogoExportMappingContract{
		Module:                   ModuleFAZ78L,
		Step:                     StepFAZ78L4,
		ProviderCode:             ProviderCode,
		ProviderName:             ProviderName,
		ConnectorCode:            ConnectorCode,
		ConnectorFamily:          ConnectorFamily,
		RuntimeMode:              RuntimeModeDryRun,
		MappingMode:              LogoExportMappingMode,
		MappingStatus:            LogoExportMappingStatus,
		MappingDirection:         LogoMappingDirection,
		TargetSystem:             LogoTargetSystem,
		RealProviderAPIStatus:    RealProviderAPIClosedStatus,
		RealFileGenerationStatus: LogoRealFileGenerationStatus,
		RealFileDeliveryStatus:   RealFileDeliveryClosedStatus,
		RealERPWriteStatus:       RealERPWriteClosedStatus,
		EntityMappings: []LogoEntityMapping{
			{
				SourceEntity: "PIX2PI_JOURNAL_HEADER",
				TargetEntity: "LOGO_FICHE_HEADER",
				Required:     true,
				FieldMappings: []LogoFieldMapping{
					{SourceField: "tenant_id", TargetField: "TENANT_REF", Required: true, Transform: "COPY", Validation: "NON_EMPTY"},
					{SourceField: "correlation_id", TargetField: "CORRELATION_REF", Required: true, Transform: "COPY", Validation: "NON_EMPTY"},
					{SourceField: "idempotency_key", TargetField: "IDEMPOTENCY_REF", Required: true, Transform: "COPY", Validation: "NON_EMPTY"},
					{SourceField: "document_no", TargetField: "FICHE_NO", Required: true, Transform: "COPY", Validation: "NON_EMPTY"},
					{SourceField: "document_date", TargetField: "FICHE_DATE", Required: true, Transform: "DATE_YYYY_MM_DD", Validation: "DATE"},
				},
			},
			{
				SourceEntity: "PIX2PI_JOURNAL_LINE",
				TargetEntity: "LOGO_FICHE_LINE",
				Required:     true,
				FieldMappings: []LogoFieldMapping{
					{SourceField: "account_code", TargetField: "ACCOUNT_CODE", Required: true, Transform: "TDHP_ACCOUNT", Validation: "NON_EMPTY"},
					{SourceField: "debit_amount", TargetField: "DEBIT", Required: true, Transform: "DECIMAL_2", Validation: "AMOUNT"},
					{SourceField: "credit_amount", TargetField: "CREDIT", Required: true, Transform: "DECIMAL_2", Validation: "AMOUNT"},
					{SourceField: "currency_code", TargetField: "CURRENCY", Required: true, Transform: "ISO_4217", Validation: "NON_EMPTY"},
					{SourceField: "description", TargetField: "LINE_DESCRIPTION", Required: false, Transform: "TRIM", Validation: "OPTIONAL_TEXT"},
				},
			},
			{
				SourceEntity: "PIX2PI_PARTY_ACCOUNT",
				TargetEntity: "LOGO_CARI_CARD",
				Required:     true,
				FieldMappings: []LogoFieldMapping{
					{SourceField: "party_name", TargetField: "TITLE", Required: true, Transform: "TRIM", Validation: "NON_EMPTY"},
					{SourceField: "party_tax_no", TargetField: "TAX_NO", Required: true, Transform: "DIGITS_ONLY", Validation: "TAX_NO"},
					{SourceField: "tax_office", TargetField: "TAX_OFFICE", Required: true, Transform: "TRIM", Validation: "NON_EMPTY"},
					{SourceField: "address", TargetField: "ADDRESS", Required: true, Transform: "TRIM", Validation: "NON_EMPTY"},
				},
			},
			{
				SourceEntity: "PIX2PI_TAX_DETAIL",
				TargetEntity: "LOGO_TAX_LINE",
				Required:     true,
				FieldMappings: []LogoFieldMapping{
					{SourceField: "tax_rate", TargetField: "VAT_RATE", Required: true, Transform: "PERCENT", Validation: "TAX_RATE"},
					{SourceField: "tax_amount", TargetField: "VAT_AMOUNT", Required: true, Transform: "DECIMAL_2", Validation: "AMOUNT"},
					{SourceField: "tax_account_code", TargetField: "VAT_ACCOUNT_CODE", Required: true, Transform: "TDHP_ACCOUNT", Validation: "NON_EMPTY"},
				},
			},
			{
				SourceEntity: "PIX2PI_INVOICE_SUMMARY",
				TargetEntity: "LOGO_INVOICE_REFERENCE",
				Required:     true,
				FieldMappings: []LogoFieldMapping{
					{SourceField: "invoice_no", TargetField: "INVOICE_NO", Required: true, Transform: "COPY", Validation: "NON_EMPTY"},
					{SourceField: "invoice_date", TargetField: "INVOICE_DATE", Required: true, Transform: "DATE_YYYY_MM_DD", Validation: "DATE"},
					{SourceField: "gross_total", TargetField: "GROSS_TOTAL", Required: true, Transform: "DECIMAL_2", Validation: "AMOUNT"},
					{SourceField: "net_total", TargetField: "NET_TOTAL", Required: true, Transform: "DECIMAL_2", Validation: "AMOUNT"},
				},
			},
		},
		TDHPMappings: []LogoTDHPMapping{
			{RuleCode: "SATIS_FATURASI", SourceEvent: "sales.invoice.posted", VoucherType: "SALES", DebitAccount: "120", CreditAccount: "600", TaxAccount: "391", Currency: "TRY", TaxPolicy: "KDV_OUTPUT"},
			{RuleCode: "ALIS_FATURASI", SourceEvent: "purchase.invoice.posted", VoucherType: "PURCHASE", DebitAccount: "153", CreditAccount: "320", TaxAccount: "191", Currency: "TRY", TaxPolicy: "KDV_INPUT"},
			{RuleCode: "TAHSILAT", SourceEvent: "payment.received", VoucherType: "COLLECTION", DebitAccount: "100", CreditAccount: "120", TaxAccount: "", Currency: "TRY", TaxPolicy: "NO_TAX"},
			{RuleCode: "ODEME", SourceEvent: "payment.sent", VoucherType: "PAYMENT", DebitAccount: "320", CreditAccount: "100", TaxAccount: "", Currency: "TRY", TaxPolicy: "NO_TAX"},
		},
		Operations: []LogoExportMappingOperationContract{
			{Name: LogoOperationDeclareExportMapping, Mode: LogoExportMappingMode, ExternalCallAllowed: false, FileGenerationAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateRequiredFields, Mode: LogoExportMappingMode, ExternalCallAllowed: false, FileGenerationAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateTDHPAccountMapping, Mode: LogoExportMappingMode, ExternalCallAllowed: false, FileGenerationAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateTaxMapping, Mode: LogoExportMappingMode, ExternalCallAllowed: false, FileGenerationAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateTenantMappingBoundary, Mode: LogoExportMappingMode, ExternalCallAllowed: false, FileGenerationAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationPrepareFileGenerationHandoff, Mode: LogoExportMappingMode, ExternalCallAllowed: false, FileGenerationAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationPrepareImportPackageHandoff, Mode: LogoExportMappingMode, ExternalCallAllowed: false, FileGenerationAllowed: false, FileDeliveryAllowed: false, ERPWriteAllowed: false},
		},
	}
}

func (c LogoExportMappingContract) Validate() error {
	credential := NewLogoCredentialContract()
	if err := credential.Validate(); err != nil {
		return fmt.Errorf("logo credential readiness must be valid before export mapping contract: %w", err)
	}

	if exportMappingTrim(c.Module) != ModuleFAZ78L {
		return fmt.Errorf("invalid module: %s", c.Module)
	}
	if exportMappingTrim(c.Step) != StepFAZ78L4 {
		return fmt.Errorf("invalid step: %s", c.Step)
	}
	if exportMappingTrim(c.ProviderCode) != ProviderCode {
		return fmt.Errorf("invalid provider code: %s", c.ProviderCode)
	}
	if strings.TrimSpace(c.ProviderName) != ProviderName {
		return fmt.Errorf("invalid provider name: %s", c.ProviderName)
	}
	if exportMappingTrim(c.ConnectorCode) != ConnectorCode {
		return fmt.Errorf("invalid connector code: %s", c.ConnectorCode)
	}
	if exportMappingTrim(c.ConnectorFamily) != ConnectorFamily {
		return fmt.Errorf("invalid connector family: %s", c.ConnectorFamily)
	}
	if exportMappingTrim(c.RuntimeMode) != RuntimeModeDryRun {
		return fmt.Errorf("invalid runtime mode: %s", c.RuntimeMode)
	}
	if exportMappingTrim(c.MappingMode) != LogoExportMappingMode {
		return fmt.Errorf("invalid mapping mode: %s", c.MappingMode)
	}
	if exportMappingTrim(c.MappingStatus) != LogoExportMappingStatus {
		return fmt.Errorf("invalid mapping status: %s", c.MappingStatus)
	}
	if exportMappingTrim(c.MappingDirection) != LogoMappingDirection {
		return fmt.Errorf("invalid mapping direction: %s", c.MappingDirection)
	}
	if exportMappingTrim(c.TargetSystem) != LogoTargetSystem {
		return fmt.Errorf("invalid target system: %s", c.TargetSystem)
	}
	if !c.RealIntegrationsClosed() {
		return errors.New("real Logo provider API, file generation, file delivery, and ERP write must remain closed")
	}
	if err := c.ValidateEntityMappings(); err != nil {
		return err
	}
	if err := c.ValidateTDHPMappings(); err != nil {
		return err
	}
	if err := c.ValidateOperations(); err != nil {
		return err
	}
	return nil
}

func (c LogoExportMappingContract) RealIntegrationsClosed() bool {
	return exportMappingTrim(c.RealProviderAPIStatus) == RealProviderAPIClosedStatus &&
		exportMappingTrim(c.RealFileGenerationStatus) == LogoRealFileGenerationStatus &&
		exportMappingTrim(c.RealFileDeliveryStatus) == RealFileDeliveryClosedStatus &&
		exportMappingTrim(c.RealERPWriteStatus) == RealERPWriteClosedStatus
}

func (c LogoExportMappingContract) ValidateEntityMappings() error {
	if len(c.EntityMappings) == 0 {
		return errors.New("entity mappings must be declared")
	}

	requiredEntities := []string{
		"PIX2PI_JOURNAL_HEADER",
		"PIX2PI_JOURNAL_LINE",
		"PIX2PI_PARTY_ACCOUNT",
		"PIX2PI_TAX_DETAIL",
		"PIX2PI_INVOICE_SUMMARY",
	}

	for _, required := range requiredEntities {
		entity, ok := c.EntityMapping(required)
		if !ok {
			return fmt.Errorf("missing required entity mapping: %s", required)
		}
		if err := entity.Validate(); err != nil {
			return fmt.Errorf("invalid entity mapping %s: %w", required, err)
		}
	}

	if !c.HasRequiredSourceField("PIX2PI_JOURNAL_HEADER", "tenant_id") {
		return errors.New("tenant_id mapping is required")
	}
	if !c.HasRequiredSourceField("PIX2PI_JOURNAL_HEADER", "correlation_id") {
		return errors.New("correlation_id mapping is required")
	}
	if !c.HasRequiredSourceField("PIX2PI_JOURNAL_HEADER", "idempotency_key") {
		return errors.New("idempotency_key mapping is required")
	}
	if !c.HasRequiredSourceField("PIX2PI_JOURNAL_LINE", "account_code") {
		return errors.New("account_code mapping is required")
	}
	if !c.HasRequiredSourceField("PIX2PI_TAX_DETAIL", "tax_rate") {
		return errors.New("tax_rate mapping is required")
	}

	return nil
}

func (c LogoExportMappingContract) ValidateTDHPMappings() error {
	if len(c.TDHPMappings) == 0 {
		return errors.New("TDHP mappings must be declared")
	}

	requiredRules := []string{
		"SATIS_FATURASI",
		"ALIS_FATURASI",
		"TAHSILAT",
		"ODEME",
	}

	for _, required := range requiredRules {
		mapping, ok := c.TDHPMapping(required)
		if !ok {
			return fmt.Errorf("missing required TDHP mapping: %s", required)
		}
		if err := mapping.Validate(); err != nil {
			return fmt.Errorf("invalid TDHP mapping %s: %w", required, err)
		}
	}
	return nil
}

func (c LogoExportMappingContract) ValidateOperations() error {
	requiredOperations := []LogoExportMappingOperationName{
		LogoOperationDeclareExportMapping,
		LogoOperationValidateRequiredFields,
		LogoOperationValidateTDHPAccountMapping,
		LogoOperationValidateTaxMapping,
		LogoOperationValidateTenantMappingBoundary,
		LogoOperationPrepareFileGenerationHandoff,
		LogoOperationPrepareImportPackageHandoff,
	}

	for _, operationName := range requiredOperations {
		operation, ok := c.Operation(operationName)
		if !ok {
			return fmt.Errorf("missing required operation: %s", operationName)
		}
		if operation.Mode != LogoExportMappingMode {
			return fmt.Errorf("operation %s must use export mapping contract mode", operationName)
		}
		if operation.ExternalCallAllowed {
			return fmt.Errorf("operation %s must not allow external calls", operationName)
		}
		if operation.FileGenerationAllowed {
			return fmt.Errorf("operation %s must not allow file generation", operationName)
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

func (c LogoExportMappingContract) EntityMapping(sourceEntity string) (LogoEntityMapping, bool) {
	for _, mapping := range c.EntityMappings {
		if mapping.SourceEntity == sourceEntity {
			return mapping, true
		}
	}
	return LogoEntityMapping{}, false
}

func (c LogoExportMappingContract) TDHPMapping(ruleCode string) (LogoTDHPMapping, bool) {
	for _, mapping := range c.TDHPMappings {
		if mapping.RuleCode == ruleCode {
			return mapping, true
		}
	}
	return LogoTDHPMapping{}, false
}

func (c LogoExportMappingContract) Operation(name LogoExportMappingOperationName) (LogoExportMappingOperationContract, bool) {
	for _, operation := range c.Operations {
		if operation.Name == name {
			return operation, true
		}
	}
	return LogoExportMappingOperationContract{}, false
}

func (c LogoExportMappingContract) HasRequiredSourceField(sourceEntity string, sourceField string) bool {
	entity, ok := c.EntityMapping(sourceEntity)
	if !ok {
		return false
	}
	for _, field := range entity.FieldMappings {
		if field.SourceField == sourceField && field.Required {
			return true
		}
	}
	return false
}

func (e LogoEntityMapping) Validate() error {
	if exportMappingTrim(e.SourceEntity) == "" {
		return errors.New("source entity is required")
	}
	if exportMappingTrim(e.TargetEntity) == "" {
		return errors.New("target entity is required")
	}
	if !e.Required {
		return errors.New("entity mapping must be required")
	}
	if len(e.FieldMappings) == 0 {
		return errors.New("field mappings must be declared")
	}
	for _, field := range e.FieldMappings {
		if err := field.Validate(); err != nil {
			return err
		}
	}
	return nil
}

func (f LogoFieldMapping) Validate() error {
	if exportMappingTrim(f.SourceField) == "" {
		return errors.New("source field is required")
	}
	if exportMappingTrim(f.TargetField) == "" {
		return errors.New("target field is required")
	}
	if exportMappingTrim(f.Transform) == "" {
		return errors.New("transform is required")
	}
	if exportMappingTrim(f.Validation) == "" {
		return errors.New("validation is required")
	}
	return nil
}

func (m LogoTDHPMapping) Validate() error {
	if exportMappingTrim(m.RuleCode) == "" {
		return errors.New("rule code is required")
	}
	if exportMappingTrim(m.SourceEvent) == "" {
		return errors.New("source event is required")
	}
	if exportMappingTrim(m.VoucherType) == "" {
		return errors.New("voucher type is required")
	}
	if exportMappingTrim(m.DebitAccount) == "" {
		return errors.New("debit account is required")
	}
	if exportMappingTrim(m.CreditAccount) == "" {
		return errors.New("credit account is required")
	}
	if exportMappingTrim(m.Currency) == "" {
		return errors.New("currency is required")
	}
	if exportMappingTrim(m.TaxPolicy) == "" {
		return errors.New("tax policy is required")
	}
	return nil
}

func exportMappingTrim(value string) string {
	return strings.TrimSpace(value)
}
