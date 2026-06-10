package voucherpipeline

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

type DocumentType string

const (
	DocumentTypeSalesInvoice      DocumentType = "SALES_INVOICE"
	DocumentTypePurchaseInvoice   DocumentType = "PURCHASE_INVOICE"
	DocumentTypePaymentCollection DocumentType = "PAYMENT_COLLECTION"
	DocumentTypeSalesRefund       DocumentType = "SALES_REFUND"
	DocumentTypePurchaseRefund    DocumentType = "PURCHASE_REFUND"
	DocumentTypeOpeningBalance    DocumentType = "OPENING_BALANCE"
)

type LineDirection string

const (
	DirectionDebit  LineDirection = "DEBIT"
	DirectionCredit LineDirection = "CREDIT"
)

type PipelineStage string

const (
	StageInputValidated PipelineStage = "INPUT_VALIDATED"
	StageAccountMapped  PipelineStage = "ACCOUNT_MAPPED"
	StageLinesBuilt     PipelineStage = "LINES_BUILT"
	StageBalanced       PipelineStage = "BALANCED"
	StagePostingReady   PipelineStage = "POSTING_READY"
)

type DecisionStatus string

const (
	DecisionReady    DecisionStatus = "READY"
	DecisionRejected DecisionStatus = "REJECTED"
)

type RuntimeConfig struct {
	RuntimeEnabled        bool            `json:"runtime_enabled"`
	DefaultCurrencyCode   string          `json:"default_currency_code"`
	IdempotencyRequired   bool            `json:"idempotency_required"`
	StrictBalanceRequired bool            `json:"strict_balance_required"`
	RequireTaxTrace       bool            `json:"require_tax_trace"`
	RequirePartyTrace     bool            `json:"require_party_trace"`
	AllowedDocumentTypes  []DocumentType  `json:"allowed_document_types"`
	RequiredStages        []PipelineStage `json:"required_stages"`
}

type AccountMapping struct {
	AccountReceivable string `json:"account_receivable"`
	AccountSales      string `json:"account_sales"`
	AccountOutputKDV  string `json:"account_output_kdv"`

	AccountInventory string `json:"account_inventory"`
	AccountInputKDV  string `json:"account_input_kdv"`
	AccountPayable   string `json:"account_payable"`

	AccountBank           string `json:"account_bank"`
	AccountSalesReturn    string `json:"account_sales_return"`
	AccountPurchaseReturn string `json:"account_purchase_return"`
	AccountOpeningBalance string `json:"account_opening_balance"`
}

type SourceDocument struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	DocumentType DocumentType `json:"document_type"`
	DocumentID   string       `json:"document_id"`
	DocumentNo   string       `json:"document_no"`
	DocumentDate time.Time    `json:"document_date"`

	PartyID    string `json:"party_id"`
	PartyTitle string `json:"party_title"`
	PartyTaxNo string `json:"party_tax_no"`

	NetAmountKurus   int64  `json:"net_amount_kurus"`
	TaxAmountKurus   int64  `json:"tax_amount_kurus"`
	GrossAmountKurus int64  `json:"gross_amount_kurus"`
	TaxRateBps       int    `json:"tax_rate_bps"`
	CurrencyCode     string `json:"currency_code"`

	Description  string    `json:"description"`
	SourceSystem string    `json:"source_system"`
	RequestedBy  string    `json:"requested_by"`
	RequestedAt  time.Time `json:"requested_at"`
}

type VoucherLine struct {
	LineNo      int           `json:"line_no"`
	AccountCode string        `json:"account_code"`
	AccountName string        `json:"account_name"`
	Direction   LineDirection `json:"direction"`

	DebitAmountKurus  int64 `json:"debit_amount_kurus"`
	CreditAmountKurus int64 `json:"credit_amount_kurus"`

	DocumentID string `json:"document_id"`
	DocumentNo string `json:"document_no"`
	PartyID    string `json:"party_id"`
	PartyTaxNo string `json:"party_tax_no"`

	TaxTraceCode string `json:"tax_trace_code"`
	Description  string `json:"description"`
}

type Voucher struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	VoucherID string `json:"voucher_id"`
	VoucherNo string `json:"voucher_no"`

	DocumentType DocumentType `json:"document_type"`
	DocumentID   string       `json:"document_id"`
	DocumentNo   string       `json:"document_no"`
	DocumentDate time.Time    `json:"document_date"`

	CurrencyCode string `json:"currency_code"`

	Lines []VoucherLine `json:"lines"`

	TotalDebitKurus  int64 `json:"total_debit_kurus"`
	TotalCreditKurus int64 `json:"total_credit_kurus"`
	Balanced         bool  `json:"balanced"`

	Stages         []PipelineStage `json:"stages"`
	DecisionStatus DecisionStatus  `json:"decision_status"`

	PostingReady bool   `json:"posting_ready"`
	AuditTraceID string `json:"audit_trace_id"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CreatedAt           time.Time `json:"created_at"`
}

type VoucherPipelineRuntime struct {
	config  RuntimeConfig
	mapping AccountMapping
}

func DefaultTRAccountMapping() AccountMapping {
	return AccountMapping{
		AccountReceivable:     "120.01",
		AccountSales:          "600.01",
		AccountOutputKDV:      "391.01.20",
		AccountInventory:      "153.01",
		AccountInputKDV:       "191.01.20",
		AccountPayable:        "320.01",
		AccountBank:           "102.01",
		AccountSalesReturn:    "610.01",
		AccountPurchaseReturn: "153.99",
		AccountOpeningBalance: "500.01",
	}
}

func NewVoucherPipelineRuntime(config RuntimeConfig, mapping AccountMapping) (*VoucherPipelineRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("voucher pipeline runtime is disabled")
	}
	if strings.TrimSpace(config.DefaultCurrencyCode) == "" {
		return nil, errors.New("default_currency_code is required")
	}
	if len(config.AllowedDocumentTypes) == 0 {
		return nil, errors.New("allowed_document_types are required")
	}
	if len(config.RequiredStages) == 0 {
		return nil, errors.New("required_stages are required")
	}
	if err := validateAccountMapping(mapping); err != nil {
		return nil, err
	}

	return &VoucherPipelineRuntime{
		config:  config,
		mapping: mapping,
	}, nil
}

func (r *VoucherPipelineRuntime) BuildVoucher(doc SourceDocument) (Voucher, error) {
	if err := r.validateSourceDocument(doc); err != nil {
		return rejectedVoucher(doc, "VALIDATION_FAILED", err.Error()), err
	}

	var (
		lines []VoucherLine
		err   error
	)

	switch doc.DocumentType {
	case DocumentTypeSalesInvoice:
		lines, err = r.buildSalesInvoiceLines(doc)
	case DocumentTypePurchaseInvoice:
		lines, err = r.buildPurchaseInvoiceLines(doc)
	case DocumentTypePaymentCollection:
		lines, err = r.buildPaymentCollectionLines(doc)
	case DocumentTypeSalesRefund:
		lines, err = r.buildSalesRefundLines(doc)
	case DocumentTypePurchaseRefund:
		lines, err = r.buildPurchaseRefundLines(doc)
	case DocumentTypeOpeningBalance:
		lines, err = r.buildOpeningBalanceLines(doc)
	default:
		err = fmt.Errorf("document_type is unsupported: %s", doc.DocumentType)
	}

	if err != nil {
		return rejectedVoucher(doc, "LINE_BUILD_FAILED", err.Error()), err
	}

	voucher := r.assembleVoucher(doc, lines)

	if r.config.StrictBalanceRequired && !voucher.Balanced {
		voucher.DecisionStatus = DecisionRejected
		voucher.PostingReady = false
		voucher.ErrorCode = "VOUCHER_NOT_BALANCED"
		voucher.ErrorMessage = "voucher debit and credit totals are not equal"
		voucher.AuditAction = "REAL_VOUCHER_PIPELINE_REJECTED"
		voucher.AuditDecisionReason = "voucher is not balanced"
		return voucher, errors.New("voucher debit and credit totals are not equal")
	}

	voucher.DecisionStatus = DecisionReady
	voucher.PostingReady = true
	voucher.AuditAction = "REAL_VOUCHER_PIPELINE_READY"
	voucher.AuditDecisionReason = "source document validated, accounts mapped, voucher lines built and balanced"
	return voucher, nil
}

func (r *VoucherPipelineRuntime) validateSourceDocument(doc SourceDocument) error {
	if strings.TrimSpace(doc.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(doc.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(doc.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if r.config.IdempotencyRequired && strings.TrimSpace(doc.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if !r.documentTypeAllowed(doc.DocumentType) {
		return fmt.Errorf("document_type is not allowed: %s", doc.DocumentType)
	}
	if strings.TrimSpace(doc.DocumentID) == "" {
		return errors.New("document_id is required")
	}
	if strings.TrimSpace(doc.DocumentNo) == "" {
		return errors.New("document_no is required")
	}
	if doc.DocumentDate.IsZero() {
		return errors.New("document_date is required")
	}
	if r.config.RequirePartyTrace {
		if strings.TrimSpace(doc.PartyID) == "" {
			return errors.New("party_id is required")
		}
		if strings.TrimSpace(doc.PartyTitle) == "" {
			return errors.New("party_title is required")
		}
		if strings.TrimSpace(doc.PartyTaxNo) == "" {
			return errors.New("party_tax_no is required")
		}
	}
	if doc.NetAmountKurus < 0 {
		return errors.New("net_amount_kurus cannot be negative")
	}
	if doc.TaxAmountKurus < 0 {
		return errors.New("tax_amount_kurus cannot be negative")
	}
	if doc.GrossAmountKurus <= 0 {
		return errors.New("gross_amount_kurus must be positive")
	}
	if doc.NetAmountKurus+doc.TaxAmountKurus != doc.GrossAmountKurus && doc.DocumentType != DocumentTypePaymentCollection && doc.DocumentType != DocumentTypeOpeningBalance {
		return errors.New("net_amount_kurus plus tax_amount_kurus must equal gross_amount_kurus")
	}
	if r.config.RequireTaxTrace && doc.DocumentType != DocumentTypePaymentCollection && doc.DocumentType != DocumentTypeOpeningBalance && doc.TaxRateBps < 0 {
		return errors.New("tax_rate_bps cannot be negative")
	}
	if strings.TrimSpace(doc.CurrencyCode) == "" {
		return errors.New("currency_code is required")
	}
	if doc.CurrencyCode != r.config.DefaultCurrencyCode {
		return errors.New("currency_code mismatch")
	}
	if strings.TrimSpace(doc.SourceSystem) == "" {
		return errors.New("source_system is required")
	}
	if strings.TrimSpace(doc.RequestedBy) == "" {
		return errors.New("requested_by is required")
	}
	if doc.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *VoucherPipelineRuntime) buildSalesInvoiceLines(doc SourceDocument) ([]VoucherLine, error) {
	lines := []VoucherLine{
		line(1, r.mapping.AccountReceivable, "Alıcılar", DirectionDebit, doc.GrossAmountKurus, 0, doc, "", "Satış faturası alacak kaydı"),
		line(2, r.mapping.AccountSales, "Yurt içi satışlar", DirectionCredit, 0, doc.NetAmountKurus, doc, "", "Satış geliri"),
	}

	if doc.TaxAmountKurus > 0 {
		lines = append(lines, line(3, r.mapping.AccountOutputKDV, "Hesaplanan KDV", DirectionCredit, 0, doc.TaxAmountKurus, doc, "OUTPUT_KDV", "Hesaplanan KDV"))
	}

	return lines, nil
}

func (r *VoucherPipelineRuntime) buildPurchaseInvoiceLines(doc SourceDocument) ([]VoucherLine, error) {
	lines := []VoucherLine{
		line(1, r.mapping.AccountInventory, "Ticari mallar", DirectionDebit, doc.NetAmountKurus, 0, doc, "", "Alış mal/hizmet kaydı"),
	}

	nextLine := 2
	if doc.TaxAmountKurus > 0 {
		lines = append(lines, line(nextLine, r.mapping.AccountInputKDV, "İndirilecek KDV", DirectionDebit, doc.TaxAmountKurus, 0, doc, "INPUT_KDV", "İndirilecek KDV"))
		nextLine++
	}

	lines = append(lines, line(nextLine, r.mapping.AccountPayable, "Satıcılar", DirectionCredit, 0, doc.GrossAmountKurus, doc, "", "Satıcı borç kaydı"))
	return lines, nil
}

func (r *VoucherPipelineRuntime) buildPaymentCollectionLines(doc SourceDocument) ([]VoucherLine, error) {
	return []VoucherLine{
		line(1, r.mapping.AccountBank, "Bankalar", DirectionDebit, doc.GrossAmountKurus, 0, doc, "", "Tahsilat banka girişi"),
		line(2, r.mapping.AccountReceivable, "Alıcılar", DirectionCredit, 0, doc.GrossAmountKurus, doc, "", "Cari tahsilat kapama"),
	}, nil
}

func (r *VoucherPipelineRuntime) buildSalesRefundLines(doc SourceDocument) ([]VoucherLine, error) {
	lines := []VoucherLine{
		line(1, r.mapping.AccountSalesReturn, "Satıştan iadeler", DirectionDebit, doc.NetAmountKurus, 0, doc, "", "Satış iadesi"),
	}

	nextLine := 2
	if doc.TaxAmountKurus > 0 {
		lines = append(lines, line(nextLine, r.mapping.AccountOutputKDV, "Hesaplanan KDV ters kayıt", DirectionDebit, doc.TaxAmountKurus, 0, doc, "OUTPUT_KDV_REVERSAL", "Satış iadesi KDV ters kayıt"))
		nextLine++
	}

	lines = append(lines, line(nextLine, r.mapping.AccountReceivable, "Alıcılar", DirectionCredit, 0, doc.GrossAmountKurus, doc, "", "Alıcı iade kapama"))
	return lines, nil
}

func (r *VoucherPipelineRuntime) buildPurchaseRefundLines(doc SourceDocument) ([]VoucherLine, error) {
	lines := []VoucherLine{
		line(1, r.mapping.AccountPayable, "Satıcılar", DirectionDebit, doc.GrossAmountKurus, 0, doc, "", "Satıcı iade kapama"),
		line(2, r.mapping.AccountPurchaseReturn, "Alış iade / stok ters kayıt", DirectionCredit, 0, doc.NetAmountKurus, doc, "", "Alış iadesi"),
	}

	if doc.TaxAmountKurus > 0 {
		lines = append(lines, line(3, r.mapping.AccountInputKDV, "İndirilecek KDV ters kayıt", DirectionCredit, 0, doc.TaxAmountKurus, doc, "INPUT_KDV_REVERSAL", "Alış iadesi KDV ters kayıt"))
	}

	return lines, nil
}

func (r *VoucherPipelineRuntime) buildOpeningBalanceLines(doc SourceDocument) ([]VoucherLine, error) {
	if doc.NetAmountKurus <= 0 {
		return nil, errors.New("opening balance net_amount_kurus must be positive")
	}

	return []VoucherLine{
		line(1, r.mapping.AccountReceivable, "Açılış alıcı bakiyesi", DirectionDebit, doc.NetAmountKurus, 0, doc, "", "Açılış borç bakiyesi"),
		line(2, r.mapping.AccountOpeningBalance, "Açılış fişi denge hesabı", DirectionCredit, 0, doc.NetAmountKurus, doc, "", "Açılış denge kaydı"),
	}, nil
}

func (r *VoucherPipelineRuntime) assembleVoucher(doc SourceDocument, lines []VoucherLine) Voucher {
	var totalDebit int64
	var totalCredit int64

	for _, l := range lines {
		totalDebit += l.DebitAmountKurus
		totalCredit += l.CreditAmountKurus
	}

	balanced := totalDebit == totalCredit

	return Voucher{
		TenantID:         doc.TenantID,
		CorrelationID:    doc.CorrelationID,
		RequestID:        doc.RequestID,
		IdempotencyKey:   doc.IdempotencyKey,
		VoucherID:        fmt.Sprintf("voucher:%s:%s", doc.TenantID, doc.DocumentID),
		VoucherNo:        fmt.Sprintf("TDHP-%s-%s", doc.DocumentNo, doc.DocumentDate.Format("20060102")),
		DocumentType:     doc.DocumentType,
		DocumentID:       doc.DocumentID,
		DocumentNo:       doc.DocumentNo,
		DocumentDate:     doc.DocumentDate,
		CurrencyCode:     doc.CurrencyCode,
		Lines:            lines,
		TotalDebitKurus:  totalDebit,
		TotalCreditKurus: totalCredit,
		Balanced:         balanced,
		Stages: []PipelineStage{
			StageInputValidated,
			StageAccountMapped,
			StageLinesBuilt,
			StageBalanced,
			StagePostingReady,
		},
		AuditTraceID: fmt.Sprintf("audit-trace:%s:%s:%s", doc.TenantID, doc.DocumentType, doc.DocumentID),
		CreatedAt:    time.Now().UTC(),
	}
}

func line(no int, accountCode string, accountName string, direction LineDirection, debit int64, credit int64, doc SourceDocument, taxTraceCode string, description string) VoucherLine {
	return VoucherLine{
		LineNo:            no,
		AccountCode:       accountCode,
		AccountName:       accountName,
		Direction:         direction,
		DebitAmountKurus:  debit,
		CreditAmountKurus: credit,
		DocumentID:        doc.DocumentID,
		DocumentNo:        doc.DocumentNo,
		PartyID:           doc.PartyID,
		PartyTaxNo:        doc.PartyTaxNo,
		TaxTraceCode:      taxTraceCode,
		Description:       description,
	}
}

func (r *VoucherPipelineRuntime) documentTypeAllowed(t DocumentType) bool {
	for _, allowed := range r.config.AllowedDocumentTypes {
		if allowed == t {
			return true
		}
	}
	return false
}

func validateAccountMapping(mapping AccountMapping) error {
	required := map[string]string{
		"account_receivable":      mapping.AccountReceivable,
		"account_sales":           mapping.AccountSales,
		"account_output_kdv":      mapping.AccountOutputKDV,
		"account_inventory":       mapping.AccountInventory,
		"account_input_kdv":       mapping.AccountInputKDV,
		"account_payable":         mapping.AccountPayable,
		"account_bank":            mapping.AccountBank,
		"account_sales_return":    mapping.AccountSalesReturn,
		"account_purchase_return": mapping.AccountPurchaseReturn,
		"account_opening_balance": mapping.AccountOpeningBalance,
	}

	for name, value := range required {
		if strings.TrimSpace(value) == "" {
			return fmt.Errorf("%s is required", name)
		}
	}

	if !strings.HasPrefix(mapping.AccountReceivable, "120") {
		return errors.New("account_receivable must start with 120")
	}
	if !strings.HasPrefix(mapping.AccountSales, "600") {
		return errors.New("account_sales must start with 600")
	}
	if !strings.HasPrefix(mapping.AccountOutputKDV, "391") {
		return errors.New("account_output_kdv must start with 391")
	}
	if !strings.HasPrefix(mapping.AccountInputKDV, "191") {
		return errors.New("account_input_kdv must start with 191")
	}
	if !strings.HasPrefix(mapping.AccountPayable, "320") {
		return errors.New("account_payable must start with 320")
	}
	if !strings.HasPrefix(mapping.AccountBank, "102") {
		return errors.New("account_bank must start with 102")
	}

	return nil
}

func rejectedVoucher(doc SourceDocument, code string, message string) Voucher {
	return Voucher{
		TenantID:            doc.TenantID,
		CorrelationID:       doc.CorrelationID,
		RequestID:           doc.RequestID,
		IdempotencyKey:      doc.IdempotencyKey,
		DocumentType:        doc.DocumentType,
		DocumentID:          doc.DocumentID,
		DocumentNo:          doc.DocumentNo,
		DocumentDate:        doc.DocumentDate,
		CurrencyCode:        doc.CurrencyCode,
		DecisionStatus:      DecisionRejected,
		PostingReady:        false,
		Balanced:            false,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "REAL_VOUCHER_PIPELINE_REJECTED",
		AuditDecisionReason: "source document rejected by real voucher pipeline validation guard",
		CreatedAt:           time.Now().UTC(),
	}
}
