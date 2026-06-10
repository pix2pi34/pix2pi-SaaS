package logo

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
)

const (
	StepFAZ78L5 = "FAZ_7_8L.5"

	LogoFileGenerationMode  = "FILE_GENERATION_DRY_RUN_ONLY"
	LogoDryRunFileStatus    = "READY"
	LogoDryRunFileFormat    = "LOGO_DRY_RUN_IMPORT_PACKAGE_V1"
	LogoDryRunFileExtension = ".dryrun.logo.txt"
	LogoDryRunPackagePrefix = "logo-dry-run"
)

type LogoFileGenerationOperationName string

const (
	LogoOperationPrepareDryRunExportInput     LogoFileGenerationOperationName = "PREPARE_LOGO_DRY_RUN_EXPORT_INPUT"
	LogoOperationGenerateDryRunFile           LogoFileGenerationOperationName = "GENERATE_LOGO_DRY_RUN_FILE"
	LogoOperationValidateDryRunFileSchema     LogoFileGenerationOperationName = "VALIDATE_LOGO_DRY_RUN_FILE_SCHEMA"
	LogoOperationCalculateDryRunChecksum      LogoFileGenerationOperationName = "CALCULATE_LOGO_DRY_RUN_CHECKSUM"
	LogoOperationPrepareImportPackageDryRun   LogoFileGenerationOperationName = "PREPARE_LOGO_IMPORT_PACKAGE_DRY_RUN"
	LogoOperationValidateNoRealDelivery       LogoFileGenerationOperationName = "VALIDATE_LOGO_NO_REAL_DELIVERY"
	LogoOperationPrepareImportDeliveryHandoff LogoFileGenerationOperationName = "PREPARE_LOGO_IMPORT_DELIVERY_HANDOFF"
)

type LogoDryRunJournalHeader struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	IdempotencyKey string `json:"idempotency_key"`
	DocumentNo     string `json:"document_no"`
	DocumentDate   string `json:"document_date"`
}

type LogoDryRunJournalLine struct {
	AccountCode  string `json:"account_code"`
	DebitAmount  string `json:"debit_amount"`
	CreditAmount string `json:"credit_amount"`
	CurrencyCode string `json:"currency_code"`
	Description  string `json:"description"`
}

type LogoDryRunPartyAccount struct {
	PartyName  string `json:"party_name"`
	PartyTaxNo string `json:"party_tax_no"`
	TaxOffice  string `json:"tax_office"`
	Address    string `json:"address"`
}

type LogoDryRunTaxDetail struct {
	TaxRate        string `json:"tax_rate"`
	TaxAmount      string `json:"tax_amount"`
	TaxAccountCode string `json:"tax_account_code"`
}

type LogoDryRunInvoiceSummary struct {
	InvoiceNo   string `json:"invoice_no"`
	InvoiceDate string `json:"invoice_date"`
	GrossTotal  string `json:"gross_total"`
	NetTotal    string `json:"net_total"`
}

type LogoDryRunExportInput struct {
	Header         LogoDryRunJournalHeader  `json:"header"`
	Lines          []LogoDryRunJournalLine  `json:"lines"`
	PartyAccount   LogoDryRunPartyAccount   `json:"party_account"`
	TaxDetails     []LogoDryRunTaxDetail    `json:"tax_details"`
	InvoiceSummary LogoDryRunInvoiceSummary `json:"invoice_summary"`
}

type LogoGeneratedDryRunFile struct {
	FileName        string `json:"file_name"`
	FileFormat      string `json:"file_format"`
	Content         string `json:"content"`
	ChecksumSHA256  string `json:"checksum_sha256"`
	ByteSize        int    `json:"byte_size"`
	DryRunOnly      bool   `json:"dry_run_only"`
	DeliveryAllowed bool   `json:"delivery_allowed"`
}

type LogoDryRunImportPackage struct {
	PackageID       string                  `json:"package_id"`
	TenantID        string                  `json:"tenant_id"`
	CorrelationID   string                  `json:"correlation_id"`
	IdempotencyKey  string                  `json:"idempotency_key"`
	GeneratedFile   LogoGeneratedDryRunFile `json:"generated_file"`
	Manifest        []string                `json:"manifest"`
	DryRunOnly      bool                    `json:"dry_run_only"`
	DeliveryAllowed bool                    `json:"delivery_allowed"`
}

type LogoFileGenerationOperationContract struct {
	Name                        LogoFileGenerationOperationName `json:"name"`
	Mode                        string                          `json:"mode"`
	DryRunFileGenerationAllowed bool                            `json:"dry_run_file_generation_allowed"`
	ExternalCallAllowed         bool                            `json:"external_call_allowed"`
	RealFileDeliveryAllowed     bool                            `json:"real_file_delivery_allowed"`
	ERPWriteAllowed             bool                            `json:"erp_write_allowed"`
}

type LogoFileGenerationContract struct {
	Module                 string                                `json:"module"`
	Step                   string                                `json:"step"`
	ProviderCode           string                                `json:"provider_code"`
	ProviderName           string                                `json:"provider_name"`
	ConnectorCode          string                                `json:"connector_code"`
	ConnectorFamily        string                                `json:"connector_family"`
	RuntimeMode            string                                `json:"runtime_mode"`
	FileGenerationMode     string                                `json:"file_generation_mode"`
	TargetSystem           string                                `json:"target_system"`
	DryRunFileStatus       string                                `json:"dry_run_file_generation_status"`
	RealProviderAPIStatus  string                                `json:"real_provider_api_status"`
	RealFileDeliveryStatus string                                `json:"real_file_delivery_status"`
	RealERPWriteStatus     string                                `json:"real_erp_write_status"`
	FileFormat             string                                `json:"file_format"`
	Operations             []LogoFileGenerationOperationContract `json:"operations"`
}

func NewLogoFileGenerationContract() LogoFileGenerationContract {
	return LogoFileGenerationContract{
		Module:                 ModuleFAZ78L,
		Step:                   StepFAZ78L5,
		ProviderCode:           ProviderCode,
		ProviderName:           ProviderName,
		ConnectorCode:          ConnectorCode,
		ConnectorFamily:        ConnectorFamily,
		RuntimeMode:            RuntimeModeDryRun,
		FileGenerationMode:     LogoFileGenerationMode,
		TargetSystem:           LogoTargetSystem,
		DryRunFileStatus:       LogoDryRunFileStatus,
		RealProviderAPIStatus:  RealProviderAPIClosedStatus,
		RealFileDeliveryStatus: RealFileDeliveryClosedStatus,
		RealERPWriteStatus:     RealERPWriteClosedStatus,
		FileFormat:             LogoDryRunFileFormat,
		Operations: []LogoFileGenerationOperationContract{
			{Name: LogoOperationPrepareDryRunExportInput, Mode: LogoFileGenerationMode, DryRunFileGenerationAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationGenerateDryRunFile, Mode: LogoFileGenerationMode, DryRunFileGenerationAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateDryRunFileSchema, Mode: LogoFileGenerationMode, DryRunFileGenerationAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationCalculateDryRunChecksum, Mode: LogoFileGenerationMode, DryRunFileGenerationAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationPrepareImportPackageDryRun, Mode: LogoFileGenerationMode, DryRunFileGenerationAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationValidateNoRealDelivery, Mode: LogoFileGenerationMode, DryRunFileGenerationAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
			{Name: LogoOperationPrepareImportDeliveryHandoff, Mode: LogoFileGenerationMode, DryRunFileGenerationAllowed: true, ExternalCallAllowed: false, RealFileDeliveryAllowed: false, ERPWriteAllowed: false},
		},
	}
}

func NewLogoSampleDryRunExportInput() LogoDryRunExportInput {
	return LogoDryRunExportInput{
		Header: LogoDryRunJournalHeader{
			TenantID:       "tenant_7",
			CorrelationID:  "corr-logo-dry-run-001",
			IdempotencyKey: "idem-logo-dry-run-001",
			DocumentNo:     "DRY-LOGO-0001",
			DocumentDate:   "2026-05-02",
		},
		Lines: []LogoDryRunJournalLine{
			{AccountCode: "120", DebitAmount: "1200.00", CreditAmount: "0.00", CurrencyCode: "TRY", Description: "Dry-run satış cari borç"},
			{AccountCode: "600", DebitAmount: "0.00", CreditAmount: "1000.00", CurrencyCode: "TRY", Description: "Dry-run satış geliri"},
			{AccountCode: "391", DebitAmount: "0.00", CreditAmount: "200.00", CurrencyCode: "TRY", Description: "Dry-run hesaplanan KDV"},
		},
		PartyAccount: LogoDryRunPartyAccount{
			PartyName:  "Dry Run Cari A.Ş.",
			PartyTaxNo: "1234567890",
			TaxOffice:  "Dry Run Vergi Dairesi",
			Address:    "Dry Run Adres",
		},
		TaxDetails: []LogoDryRunTaxDetail{
			{TaxRate: "20", TaxAmount: "200.00", TaxAccountCode: "391"},
		},
		InvoiceSummary: LogoDryRunInvoiceSummary{
			InvoiceNo:   "FTR-DRY-0001",
			InvoiceDate: "2026-05-02",
			GrossTotal:  "1200.00",
			NetTotal:    "1000.00",
		},
	}
}

func (c LogoFileGenerationContract) Validate() error {
	exportMapping := NewLogoExportMappingContract()
	if err := exportMapping.Validate(); err != nil {
		return fmt.Errorf("logo export mapping contract must be valid before file generation dry-run: %w", err)
	}

	if fileGenerationTrim(c.Module) != ModuleFAZ78L {
		return fmt.Errorf("invalid module: %s", c.Module)
	}
	if fileGenerationTrim(c.Step) != StepFAZ78L5 {
		return fmt.Errorf("invalid step: %s", c.Step)
	}
	if fileGenerationTrim(c.ProviderCode) != ProviderCode {
		return fmt.Errorf("invalid provider code: %s", c.ProviderCode)
	}
	if strings.TrimSpace(c.ProviderName) != ProviderName {
		return fmt.Errorf("invalid provider name: %s", c.ProviderName)
	}
	if fileGenerationTrim(c.ConnectorCode) != ConnectorCode {
		return fmt.Errorf("invalid connector code: %s", c.ConnectorCode)
	}
	if fileGenerationTrim(c.ConnectorFamily) != ConnectorFamily {
		return fmt.Errorf("invalid connector family: %s", c.ConnectorFamily)
	}
	if fileGenerationTrim(c.RuntimeMode) != RuntimeModeDryRun {
		return fmt.Errorf("invalid runtime mode: %s", c.RuntimeMode)
	}
	if fileGenerationTrim(c.FileGenerationMode) != LogoFileGenerationMode {
		return fmt.Errorf("invalid file generation mode: %s", c.FileGenerationMode)
	}
	if fileGenerationTrim(c.TargetSystem) != LogoTargetSystem {
		return fmt.Errorf("invalid target system: %s", c.TargetSystem)
	}
	if fileGenerationTrim(c.DryRunFileStatus) != LogoDryRunFileStatus {
		return fmt.Errorf("invalid dry-run file status: %s", c.DryRunFileStatus)
	}
	if fileGenerationTrim(c.FileFormat) != LogoDryRunFileFormat {
		return fmt.Errorf("invalid file format: %s", c.FileFormat)
	}
	if !c.RealIntegrationsClosed() {
		return errors.New("real Logo provider API, real file delivery, and ERP write must remain closed")
	}
	if err := c.ValidateOperations(); err != nil {
		return err
	}
	return nil
}

func (c LogoFileGenerationContract) RealIntegrationsClosed() bool {
	return fileGenerationTrim(c.RealProviderAPIStatus) == RealProviderAPIClosedStatus &&
		fileGenerationTrim(c.RealFileDeliveryStatus) == RealFileDeliveryClosedStatus &&
		fileGenerationTrim(c.RealERPWriteStatus) == RealERPWriteClosedStatus
}

func (c LogoFileGenerationContract) ValidateOperations() error {
	requiredOperations := []LogoFileGenerationOperationName{
		LogoOperationPrepareDryRunExportInput,
		LogoOperationGenerateDryRunFile,
		LogoOperationValidateDryRunFileSchema,
		LogoOperationCalculateDryRunChecksum,
		LogoOperationPrepareImportPackageDryRun,
		LogoOperationValidateNoRealDelivery,
		LogoOperationPrepareImportDeliveryHandoff,
	}

	for _, operationName := range requiredOperations {
		operation, ok := c.Operation(operationName)
		if !ok {
			return fmt.Errorf("missing required operation: %s", operationName)
		}
		if operation.Mode != LogoFileGenerationMode {
			return fmt.Errorf("operation %s must use file generation dry-run mode", operationName)
		}
		if !operation.DryRunFileGenerationAllowed {
			return fmt.Errorf("operation %s must allow dry-run file generation", operationName)
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

func (c LogoFileGenerationContract) Operation(name LogoFileGenerationOperationName) (LogoFileGenerationOperationContract, bool) {
	for _, operation := range c.Operations {
		if operation.Name == name {
			return operation, true
		}
	}
	return LogoFileGenerationOperationContract{}, false
}

func (c LogoFileGenerationContract) GenerateDryRunImportPackage(input LogoDryRunExportInput) (LogoDryRunImportPackage, error) {
	if err := c.Validate(); err != nil {
		return LogoDryRunImportPackage{}, err
	}
	if err := input.Validate(); err != nil {
		return LogoDryRunImportPackage{}, err
	}

	content := input.BuildDryRunFileContent()
	checksum := CalculateLogoDryRunChecksum(content)
	fileName := fmt.Sprintf(
		"logo_%s_%s%s",
		safeLogoFilePart(input.Header.TenantID),
		safeLogoFilePart(input.Header.DocumentNo),
		LogoDryRunFileExtension,
	)

	generated := LogoGeneratedDryRunFile{
		FileName:        fileName,
		FileFormat:      LogoDryRunFileFormat,
		Content:         content,
		ChecksumSHA256:  checksum,
		ByteSize:        len([]byte(content)),
		DryRunOnly:      true,
		DeliveryAllowed: false,
	}

	pkg := LogoDryRunImportPackage{
		PackageID:      fmt.Sprintf("%s:%s:%s", LogoDryRunPackagePrefix, input.Header.TenantID, input.Header.IdempotencyKey),
		TenantID:       input.Header.TenantID,
		CorrelationID:  input.Header.CorrelationID,
		IdempotencyKey: input.Header.IdempotencyKey,
		GeneratedFile:  generated,
		Manifest: []string{
			"HEADER",
			"LINE",
			"PARTY",
			"TAX",
			"INVOICE",
			"MANIFEST",
		},
		DryRunOnly:      true,
		DeliveryAllowed: false,
	}

	if err := pkg.Validate(); err != nil {
		return LogoDryRunImportPackage{}, err
	}

	return pkg, nil
}

func (i LogoDryRunExportInput) Validate() error {
	if fileGenerationTrim(i.Header.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if fileGenerationTrim(i.Header.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if fileGenerationTrim(i.Header.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if fileGenerationTrim(i.Header.DocumentNo) == "" {
		return errors.New("document_no is required")
	}
	if fileGenerationTrim(i.Header.DocumentDate) == "" {
		return errors.New("document_date is required")
	}
	if len(i.Lines) == 0 {
		return errors.New("journal_lines are required")
	}
	for _, line := range i.Lines {
		if err := line.Validate(); err != nil {
			return err
		}
	}
	if err := i.PartyAccount.Validate(); err != nil {
		return err
	}
	if len(i.TaxDetails) == 0 {
		return errors.New("tax_details are required")
	}
	for _, tax := range i.TaxDetails {
		if err := tax.Validate(); err != nil {
			return err
		}
	}
	if err := i.InvoiceSummary.Validate(); err != nil {
		return err
	}
	return nil
}

func (l LogoDryRunJournalLine) Validate() error {
	if fileGenerationTrim(l.AccountCode) == "" {
		return errors.New("account_code is required")
	}
	if fileGenerationTrim(l.DebitAmount) == "" {
		return errors.New("debit_amount is required")
	}
	if fileGenerationTrim(l.CreditAmount) == "" {
		return errors.New("credit_amount is required")
	}
	if fileGenerationTrim(l.CurrencyCode) == "" {
		return errors.New("currency_code is required")
	}
	return nil
}

func (p LogoDryRunPartyAccount) Validate() error {
	if fileGenerationTrim(p.PartyName) == "" {
		return errors.New("party_name is required")
	}
	if fileGenerationTrim(p.PartyTaxNo) == "" {
		return errors.New("party_tax_no is required")
	}
	if fileGenerationTrim(p.TaxOffice) == "" {
		return errors.New("tax_office is required")
	}
	if fileGenerationTrim(p.Address) == "" {
		return errors.New("address is required")
	}
	return nil
}

func (t LogoDryRunTaxDetail) Validate() error {
	if fileGenerationTrim(t.TaxRate) == "" {
		return errors.New("tax_rate is required")
	}
	if fileGenerationTrim(t.TaxAmount) == "" {
		return errors.New("tax_amount is required")
	}
	if fileGenerationTrim(t.TaxAccountCode) == "" {
		return errors.New("tax_account_code is required")
	}
	return nil
}

func (s LogoDryRunInvoiceSummary) Validate() error {
	if fileGenerationTrim(s.InvoiceNo) == "" {
		return errors.New("invoice_no is required")
	}
	if fileGenerationTrim(s.InvoiceDate) == "" {
		return errors.New("invoice_date is required")
	}
	if fileGenerationTrim(s.GrossTotal) == "" {
		return errors.New("gross_total is required")
	}
	if fileGenerationTrim(s.NetTotal) == "" {
		return errors.New("net_total is required")
	}
	return nil
}

func (i LogoDryRunExportInput) BuildDryRunFileContent() string {
	var builder strings.Builder

	builder.WriteString("HEADER|")
	builder.WriteString(i.Header.TenantID)
	builder.WriteString("|")
	builder.WriteString(i.Header.CorrelationID)
	builder.WriteString("|")
	builder.WriteString(i.Header.IdempotencyKey)
	builder.WriteString("|")
	builder.WriteString(i.Header.DocumentNo)
	builder.WriteString("|")
	builder.WriteString(i.Header.DocumentDate)
	builder.WriteString("\n")

	for _, line := range i.Lines {
		builder.WriteString("LINE|")
		builder.WriteString(line.AccountCode)
		builder.WriteString("|")
		builder.WriteString(line.DebitAmount)
		builder.WriteString("|")
		builder.WriteString(line.CreditAmount)
		builder.WriteString("|")
		builder.WriteString(line.CurrencyCode)
		builder.WriteString("|")
		builder.WriteString(line.Description)
		builder.WriteString("\n")
	}

	builder.WriteString("PARTY|")
	builder.WriteString(i.PartyAccount.PartyName)
	builder.WriteString("|")
	builder.WriteString(i.PartyAccount.PartyTaxNo)
	builder.WriteString("|")
	builder.WriteString(i.PartyAccount.TaxOffice)
	builder.WriteString("|")
	builder.WriteString(i.PartyAccount.Address)
	builder.WriteString("\n")

	for _, tax := range i.TaxDetails {
		builder.WriteString("TAX|")
		builder.WriteString(tax.TaxRate)
		builder.WriteString("|")
		builder.WriteString(tax.TaxAmount)
		builder.WriteString("|")
		builder.WriteString(tax.TaxAccountCode)
		builder.WriteString("\n")
	}

	builder.WriteString("INVOICE|")
	builder.WriteString(i.InvoiceSummary.InvoiceNo)
	builder.WriteString("|")
	builder.WriteString(i.InvoiceSummary.InvoiceDate)
	builder.WriteString("|")
	builder.WriteString(i.InvoiceSummary.GrossTotal)
	builder.WriteString("|")
	builder.WriteString(i.InvoiceSummary.NetTotal)
	builder.WriteString("\n")

	builder.WriteString("MANIFEST|DRY_RUN_ONLY|NO_REAL_DELIVERY|NO_ERP_WRITE\n")

	return builder.String()
}

func (p LogoDryRunImportPackage) Validate() error {
	if fileGenerationTrim(p.PackageID) == "" {
		return errors.New("package_id is required")
	}
	if fileGenerationTrim(p.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if fileGenerationTrim(p.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if fileGenerationTrim(p.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if !p.DryRunOnly {
		return errors.New("package must be dry-run only")
	}
	if p.DeliveryAllowed {
		return errors.New("package must not allow delivery")
	}
	if err := p.GeneratedFile.Validate(); err != nil {
		return err
	}
	if len(p.Manifest) == 0 {
		return errors.New("manifest is required")
	}
	return nil
}

func (f LogoGeneratedDryRunFile) Validate() error {
	if fileGenerationTrim(f.FileName) == "" {
		return errors.New("file_name is required")
	}
	if fileGenerationTrim(f.FileFormat) != LogoDryRunFileFormat {
		return fmt.Errorf("invalid file format: %s", f.FileFormat)
	}
	if fileGenerationTrim(f.Content) == "" {
		return errors.New("content is required")
	}
	if fileGenerationTrim(f.ChecksumSHA256) == "" {
		return errors.New("checksum_sha256 is required")
	}
	if f.ByteSize <= 0 {
		return errors.New("byte_size must be positive")
	}
	if !f.DryRunOnly {
		return errors.New("file must be dry-run only")
	}
	if f.DeliveryAllowed {
		return errors.New("file must not allow delivery")
	}
	return nil
}

func CalculateLogoDryRunChecksum(content string) string {
	sum := sha256.Sum256([]byte(content))
	return hex.EncodeToString(sum[:])
}

func safeLogoFilePart(value string) string {
	clean := strings.ToLower(fileGenerationTrim(value))
	replacer := strings.NewReplacer(
		" ", "_",
		"/", "_",
		"\\", "_",
		":", "_",
		";", "_",
		"|", "_",
		".", "_",
	)
	return replacer.Replace(clean)
}

func fileGenerationTrim(value string) string {
	return strings.TrimSpace(value)
}
