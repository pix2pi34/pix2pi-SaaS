package eta

import (
	"errors"
	"fmt"
	"sort"
	"strconv"
	"strings"
	"time"
	"unicode"

	postingruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/postingruntime"
)

type TargetSystem string

const (
	TargetSystemETA TargetSystem = "ETA"
)

type ETAFormatVersion string

const (
	ETAFormatV1 ETAFormatVersion = "ETA_TDHP_V1"
)

type ETAFileType string

const (
	FileTypeJournal ETAFileType = "ETA_JOURNAL_TXT"
	FileTypeLedger  ETAFileType = "ETA_LEDGER_TXT"
	FileTypeSummary ETAFileType = "ETA_SUMMARY_TXT"
)

type ExportStatus string

const (
	ExportStatusReady    ExportStatus = "READY"
	ExportStatusRejected ExportStatus = "REJECTED"
)

type RuntimeConfig struct {
	RuntimeEnabled          bool             `json:"runtime_enabled"`
	TargetSystem            TargetSystem     `json:"target_system"`
	FormatVersion           ETAFormatVersion `json:"format_version"`
	DefaultCurrencyCode     string           `json:"default_currency_code"`
	Delimiter               string           `json:"delimiter"`
	LineEnding              string           `json:"line_ending"`
	StrictBalanceRequired   bool             `json:"strict_balance_required"`
	RequirePostingHash      bool             `json:"require_posting_hash"`
	RequireAuditTrace       bool             `json:"require_audit_trace"`
	RequireTenantScope      bool             `json:"require_tenant_scope"`
	NormalizeTurkishChars   bool             `json:"normalize_turkish_chars"`
	MaxDescriptionLength    int              `json:"max_description_length"`
	AllowedFileTypes        []ETAFileType    `json:"allowed_file_types"`
	RequiredAccountPrefixes []string         `json:"required_account_prefixes"`
}

type ETAExportRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ExportID      string           `json:"export_id"`
	TargetSystem  TargetSystem     `json:"target_system"`
	FormatVersion ETAFormatVersion `json:"format_version"`

	PeriodCode string `json:"period_code"`
	FiscalYear int    `json:"fiscal_year"`

	Postings []postingruntime.PostingEntry `json:"postings"`

	RequestedBy string    `json:"requested_by"`
	RequestedAt time.Time `json:"requested_at"`
}

type ETAJournalRow struct {
	TenantID  string `json:"tenant_id"`
	ExportID  string `json:"export_id"`
	PostingID string `json:"posting_id"`
	PostingNo string `json:"posting_no"`
	LineNo    int    `json:"line_no"`

	Date        string `json:"date"`
	DocumentNo  string `json:"document_no"`
	AccountCode string `json:"account_code"`
	AccountName string `json:"account_name"`
	Debit       string `json:"debit"`
	Credit      string `json:"credit"`
	Currency    string `json:"currency"`
	Description string `json:"description"`
	PartyTaxNo  string `json:"party_tax_no"`
	PostingHash string `json:"posting_hash"`
}

type ETAExportFile struct {
	FileType  ETAFileType `json:"file_type"`
	FileName  string      `json:"file_name"`
	MimeType  string      `json:"mime_type"`
	Content   string      `json:"content"`
	LineCount int         `json:"line_count"`
	FileHash  string      `json:"file_hash"`
}

type ETAValidationIssue struct {
	Code     string `json:"code"`
	Message  string `json:"message"`
	Severity string `json:"severity"`
}

type ETAExportPackage struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ExportID      string           `json:"export_id"`
	TargetSystem  TargetSystem     `json:"target_system"`
	FormatVersion ETAFormatVersion `json:"format_version"`
	PeriodCode    string           `json:"period_code"`
	FiscalYear    int              `json:"fiscal_year"`

	Status ExportStatus `json:"status"`

	JournalRows []ETAJournalRow      `json:"journal_rows"`
	Files       []ETAExportFile      `json:"files"`
	Issues      []ETAValidationIssue `json:"issues"`

	TotalDebitKurus  int64 `json:"total_debit_kurus"`
	TotalCreditKurus int64 `json:"total_credit_kurus"`
	Balanced         bool  `json:"balanced"`

	PackageHash string `json:"package_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CreatedAt           time.Time `json:"created_at"`
}

type ETARealFormatRuntime struct {
	config RuntimeConfig
}

func NewETARealFormatRuntime(config RuntimeConfig) (*ETARealFormatRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("ETA real format runtime is disabled")
	}
	if config.TargetSystem != TargetSystemETA {
		return nil, errors.New("target_system must be ETA")
	}
	if strings.TrimSpace(string(config.FormatVersion)) == "" {
		return nil, errors.New("format_version is required")
	}
	if strings.TrimSpace(config.DefaultCurrencyCode) == "" {
		return nil, errors.New("default_currency_code is required")
	}
	if strings.TrimSpace(config.Delimiter) == "" {
		return nil, errors.New("delimiter is required")
	}
	if config.LineEnding == "" {
		return nil, errors.New("line_ending is required")
	}
	if config.MaxDescriptionLength <= 0 {
		return nil, errors.New("max_description_length must be positive")
	}
	if len(config.AllowedFileTypes) == 0 {
		return nil, errors.New("allowed_file_types are required")
	}
	if len(config.RequiredAccountPrefixes) == 0 {
		return nil, errors.New("required_account_prefixes are required")
	}

	return &ETARealFormatRuntime{config: config}, nil
}

func (r *ETARealFormatRuntime) BuildPackage(req ETAExportRequest) (ETAExportPackage, error) {
	if err := r.validateRequest(req); err != nil {
		return rejectedPackage(req, "VALIDATION_FAILED", err.Error()), err
	}

	rows, totalDebit, totalCredit, err := r.buildJournalRows(req)
	if err != nil {
		return rejectedPackage(req, "ROW_BUILD_FAILED", err.Error()), err
	}

	balanced := totalDebit == totalCredit
	if r.config.StrictBalanceRequired && !balanced {
		return rejectedPackage(req, "ETA_EXPORT_NOT_BALANCED", "ETA export debit and credit totals are not equal"), errors.New("ETA export debit and credit totals are not equal")
	}

	files := []ETAExportFile{
		r.buildJournalFile(req, rows),
		r.buildLedgerFile(req, rows),
		r.buildSummaryFile(req, rows, totalDebit, totalCredit),
	}

	issues := r.validateRows(rows)
	if len(issues) > 0 {
		pkg := rejectedPackage(req, "ETA_VALIDATION_ISSUES", "ETA export validation issues detected")
		pkg.JournalRows = rows
		pkg.Files = files
		pkg.Issues = issues
		pkg.TotalDebitKurus = totalDebit
		pkg.TotalCreditKurus = totalCredit
		pkg.Balanced = balanced
		pkg.PackageHash = buildPackageHash(req, files, totalDebit, totalCredit)
		return pkg, errors.New("ETA export validation issues detected")
	}

	return ETAExportPackage{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		ExportID:            req.ExportID,
		TargetSystem:        req.TargetSystem,
		FormatVersion:       req.FormatVersion,
		PeriodCode:          req.PeriodCode,
		FiscalYear:          req.FiscalYear,
		Status:              ExportStatusReady,
		JournalRows:         rows,
		Files:               files,
		TotalDebitKurus:     totalDebit,
		TotalCreditKurus:    totalCredit,
		Balanced:            balanced,
		PackageHash:         buildPackageHash(req, files, totalDebit, totalCredit),
		AuditAction:         "ETA_REAL_FORMAT_PACKAGE_READY",
		AuditDecisionReason: "posting entries converted to ETA journal, ledger and summary files",
		CreatedAt:           time.Now().UTC(),
	}, nil
}

func (r *ETARealFormatRuntime) ValidatePackage(pkg ETAExportPackage) []ETAValidationIssue {
	issues := make([]ETAValidationIssue, 0)

	if strings.TrimSpace(pkg.TenantID) == "" {
		issues = append(issues, issue("TENANT_ID_MISSING", "tenant_id is required", "BLOCKING"))
	}
	if pkg.TargetSystem != TargetSystemETA {
		issues = append(issues, issue("TARGET_SYSTEM_INVALID", "target_system must be ETA", "BLOCKING"))
	}
	if pkg.FormatVersion != r.config.FormatVersion {
		issues = append(issues, issue("FORMAT_VERSION_MISMATCH", "format_version mismatch", "BLOCKING"))
	}
	if len(pkg.Files) == 0 {
		issues = append(issues, issue("FILES_MISSING", "export files are required", "BLOCKING"))
	}
	if len(pkg.JournalRows) == 0 {
		issues = append(issues, issue("ROWS_MISSING", "journal rows are required", "BLOCKING"))
	}
	if r.config.StrictBalanceRequired && !pkg.Balanced {
		issues = append(issues, issue("PACKAGE_NOT_BALANCED", "package must be balanced", "BLOCKING"))
	}
	if strings.TrimSpace(pkg.PackageHash) == "" {
		issues = append(issues, issue("PACKAGE_HASH_MISSING", "package_hash is required", "BLOCKING"))
	}

	issues = append(issues, r.validateRows(pkg.JournalRows)...)
	return issues
}

func (r *ETARealFormatRuntime) buildJournalRows(req ETAExportRequest) ([]ETAJournalRow, int64, int64, error) {
	rows := make([]ETAJournalRow, 0)
	var totalDebit int64
	var totalCredit int64

	postings := append([]postingruntime.PostingEntry(nil), req.Postings...)
	sort.SliceStable(postings, func(i int, j int) bool {
		if postings[i].DocumentDate.Equal(postings[j].DocumentDate) {
			return postings[i].PostingNo < postings[j].PostingNo
		}
		return postings[i].DocumentDate.Before(postings[j].DocumentDate)
	})

	for _, posting := range postings {
		if err := r.validatePosting(req.TenantID, posting); err != nil {
			return nil, 0, 0, err
		}

		for _, line := range posting.Lines {
			if line.DebitAmountKurus < 0 || line.CreditAmountKurus < 0 {
				return nil, 0, 0, errors.New("posting line debit/credit cannot be negative")
			}
			if line.DebitAmountKurus == 0 && line.CreditAmountKurus == 0 {
				return nil, 0, 0, errors.New("posting line debit or credit amount is required")
			}
			if line.DebitAmountKurus > 0 && line.CreditAmountKurus > 0 {
				return nil, 0, 0, errors.New("posting line cannot have both debit and credit")
			}
			if strings.TrimSpace(line.AccountCode) == "" {
				return nil, 0, 0, errors.New("posting line account_code is required")
			}

			totalDebit += line.DebitAmountKurus
			totalCredit += line.CreditAmountKurus

			row := ETAJournalRow{
				TenantID:    req.TenantID,
				ExportID:    req.ExportID,
				PostingID:   posting.PostingID,
				PostingNo:   posting.PostingNo,
				LineNo:      line.LineNo,
				Date:        posting.DocumentDate.Format("20060102"),
				DocumentNo:  normalizeETAField(posting.DocumentNo, r.config.NormalizeTurkishChars, 30),
				AccountCode: normalizeETAField(line.AccountCode, false, 32),
				AccountName: normalizeETAField(line.AccountName, r.config.NormalizeTurkishChars, 80),
				Debit:       formatKurus(line.DebitAmountKurus),
				Credit:      formatKurus(line.CreditAmountKurus),
				Currency:    posting.CurrencyCode,
				Description: normalizeETAField(line.Description, r.config.NormalizeTurkishChars, r.config.MaxDescriptionLength),
				PartyTaxNo:  normalizeETAField(line.PartyTaxNo, false, 20),
				PostingHash: posting.PostingHash,
			}

			rows = append(rows, row)
		}
	}

	return rows, totalDebit, totalCredit, nil
}

func (r *ETARealFormatRuntime) validateRequest(req ETAExportRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return errors.New("tenant_id is required")
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return errors.New("correlation_id is required")
	}
	if strings.TrimSpace(req.RequestID) == "" {
		return errors.New("request_id is required")
	}
	if strings.TrimSpace(req.IdempotencyKey) == "" {
		return errors.New("idempotency_key is required")
	}
	if strings.TrimSpace(req.ExportID) == "" {
		return errors.New("export_id is required")
	}
	if req.TargetSystem != TargetSystemETA {
		return errors.New("target_system must be ETA")
	}
	if req.FormatVersion != r.config.FormatVersion {
		return errors.New("format_version mismatch")
	}
	if strings.TrimSpace(req.PeriodCode) == "" {
		return errors.New("period_code is required")
	}
	if req.FiscalYear <= 2000 {
		return errors.New("fiscal_year is invalid")
	}
	if len(req.Postings) == 0 {
		return errors.New("postings are required")
	}
	if strings.TrimSpace(req.RequestedBy) == "" {
		return errors.New("requested_by is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *ETARealFormatRuntime) validatePosting(expectedTenantID string, posting postingruntime.PostingEntry) error {
	if r.config.RequireTenantScope && posting.TenantID != expectedTenantID {
		return errors.New("posting tenant_id mismatch")
	}
	if strings.TrimSpace(posting.PostingID) == "" {
		return errors.New("posting_id is required")
	}
	if strings.TrimSpace(posting.PostingNo) == "" {
		return errors.New("posting_no is required")
	}
	if strings.TrimSpace(posting.DocumentID) == "" {
		return errors.New("document_id is required")
	}
	if strings.TrimSpace(posting.DocumentNo) == "" {
		return errors.New("document_no is required")
	}
	if posting.DocumentDate.IsZero() {
		return errors.New("document_date is required")
	}
	if posting.CurrencyCode != r.config.DefaultCurrencyCode {
		return errors.New("posting currency_code mismatch")
	}
	if r.config.StrictBalanceRequired && !posting.Balanced {
		return errors.New("posting balanced is required")
	}
	if posting.TotalDebitKurus != posting.TotalCreditKurus {
		return errors.New("posting debit and credit totals must match")
	}
	if len(posting.Lines) == 0 {
		return errors.New("posting lines are required")
	}
	if r.config.RequirePostingHash && strings.TrimSpace(posting.PostingHash) == "" {
		return errors.New("posting_hash is required")
	}
	if r.config.RequireAuditTrace && strings.TrimSpace(posting.AuditTraceID) == "" {
		return errors.New("audit_trace_id is required")
	}
	return nil
}

func (r *ETARealFormatRuntime) validateRows(rows []ETAJournalRow) []ETAValidationIssue {
	issues := make([]ETAValidationIssue, 0)

	for _, row := range rows {
		if strings.TrimSpace(row.Date) == "" {
			issues = append(issues, issue("ROW_DATE_MISSING", "row date is required", "BLOCKING"))
		}
		if strings.TrimSpace(row.DocumentNo) == "" {
			issues = append(issues, issue("ROW_DOCUMENT_NO_MISSING", "row document_no is required", "BLOCKING"))
		}
		if strings.TrimSpace(row.AccountCode) == "" {
			issues = append(issues, issue("ROW_ACCOUNT_CODE_MISSING", "row account_code is required", "BLOCKING"))
		}
		if !r.accountPrefixAllowed(row.AccountCode) {
			issues = append(issues, issue("ROW_ACCOUNT_PREFIX_INVALID", "row account_code prefix is not allowed", "BLOCKING"))
		}
		if strings.TrimSpace(row.Currency) != r.config.DefaultCurrencyCode {
			issues = append(issues, issue("ROW_CURRENCY_INVALID", "row currency must be TRY", "BLOCKING"))
		}
		if strings.TrimSpace(row.PostingHash) == "" {
			issues = append(issues, issue("ROW_POSTING_HASH_MISSING", "row posting_hash is required", "BLOCKING"))
		}
	}

	return issues
}

func (r *ETARealFormatRuntime) accountPrefixAllowed(accountCode string) bool {
	for _, prefix := range r.config.RequiredAccountPrefixes {
		if strings.HasPrefix(accountCode, prefix) {
			return true
		}
	}
	return false
}

func (r *ETARealFormatRuntime) buildJournalFile(req ETAExportRequest, rows []ETAJournalRow) ETAExportFile {
	header := []string{"TARIH", "FISNO", "SATIR", "HESAPKODU", "HESAPADI", "BORC", "ALACAK", "PARA", "ACIKLAMA", "VKN", "HASH"}
	lines := []string{strings.Join(header, r.config.Delimiter)}

	for _, row := range rows {
		fields := []string{
			row.Date,
			row.PostingNo,
			strconv.Itoa(row.LineNo),
			row.AccountCode,
			row.AccountName,
			row.Debit,
			row.Credit,
			row.Currency,
			row.Description,
			row.PartyTaxNo,
			row.PostingHash,
		}
		lines = append(lines, strings.Join(fields, r.config.Delimiter))
	}

	content := strings.Join(lines, r.config.LineEnding) + r.config.LineEnding
	return ETAExportFile{
		FileType:  FileTypeJournal,
		FileName:  fmt.Sprintf("%s_ETA_JOURNAL.txt", req.ExportID),
		MimeType:  "text/plain",
		Content:   content,
		LineCount: len(lines),
		FileHash:  buildFileHash(FileTypeJournal, content),
	}
}

func (r *ETARealFormatRuntime) buildLedgerFile(req ETAExportRequest, rows []ETAJournalRow) ETAExportFile {
	header := []string{"HESAPKODU", "HESAPADI", "BORC", "ALACAK", "PARA"}
	lines := []string{strings.Join(header, r.config.Delimiter)}

	type agg struct {
		accountCode string
		accountName string
		debitKurus  int64
		creditKurus int64
		currency    string
	}

	aggs := make(map[string]*agg)
	for _, row := range rows {
		item, ok := aggs[row.AccountCode]
		if !ok {
			item = &agg{accountCode: row.AccountCode, accountName: row.AccountName, currency: row.Currency}
			aggs[row.AccountCode] = item
		}
		item.debitKurus += parseAmount(row.Debit)
		item.creditKurus += parseAmount(row.Credit)
	}

	keys := make([]string, 0, len(aggs))
	for key := range aggs {
		keys = append(keys, key)
	}
	sort.Strings(keys)

	for _, key := range keys {
		item := aggs[key]
		fields := []string{
			item.accountCode,
			item.accountName,
			formatKurus(item.debitKurus),
			formatKurus(item.creditKurus),
			item.currency,
		}
		lines = append(lines, strings.Join(fields, r.config.Delimiter))
	}

	content := strings.Join(lines, r.config.LineEnding) + r.config.LineEnding
	return ETAExportFile{
		FileType:  FileTypeLedger,
		FileName:  fmt.Sprintf("%s_ETA_LEDGER.txt", req.ExportID),
		MimeType:  "text/plain",
		Content:   content,
		LineCount: len(lines),
		FileHash:  buildFileHash(FileTypeLedger, content),
	}
}

func (r *ETARealFormatRuntime) buildSummaryFile(req ETAExportRequest, rows []ETAJournalRow, totalDebit int64, totalCredit int64) ETAExportFile {
	lines := []string{
		"KEY" + r.config.Delimiter + "VALUE",
		"TARGET_SYSTEM" + r.config.Delimiter + string(req.TargetSystem),
		"FORMAT_VERSION" + r.config.Delimiter + string(req.FormatVersion),
		"EXPORT_ID" + r.config.Delimiter + req.ExportID,
		"PERIOD_CODE" + r.config.Delimiter + req.PeriodCode,
		"FISCAL_YEAR" + r.config.Delimiter + strconv.Itoa(req.FiscalYear),
		"ROW_COUNT" + r.config.Delimiter + strconv.Itoa(len(rows)),
		"TOTAL_DEBIT" + r.config.Delimiter + formatKurus(totalDebit),
		"TOTAL_CREDIT" + r.config.Delimiter + formatKurus(totalCredit),
		"BALANCED" + r.config.Delimiter + strconv.FormatBool(totalDebit == totalCredit),
	}

	content := strings.Join(lines, r.config.LineEnding) + r.config.LineEnding
	return ETAExportFile{
		FileType:  FileTypeSummary,
		FileName:  fmt.Sprintf("%s_ETA_SUMMARY.txt", req.ExportID),
		MimeType:  "text/plain",
		Content:   content,
		LineCount: len(lines),
		FileHash:  buildFileHash(FileTypeSummary, content),
	}
}

func normalizeETAField(value string, normalizeTurkish bool, maxLength int) string {
	value = strings.TrimSpace(value)
	value = strings.ReplaceAll(value, "\n", " ")
	value = strings.ReplaceAll(value, "\r", " ")
	value = strings.ReplaceAll(value, "|", "/")
	value = strings.Join(strings.Fields(value), " ")

	if normalizeTurkish {
		value = normalizeTurkishASCII(value)
	}

	if maxLength > 0 && len([]rune(value)) > maxLength {
		runes := []rune(value)
		value = string(runes[:maxLength])
	}

	return value
}

func normalizeTurkishASCII(value string) string {
	replacer := strings.NewReplacer(
		"ç", "c", "Ç", "C",
		"ğ", "g", "Ğ", "G",
		"ı", "i", "I", "I",
		"İ", "I",
		"ö", "o", "Ö", "O",
		"ş", "s", "Ş", "S",
		"ü", "u", "Ü", "U",
	)
	return strings.Map(func(r rune) rune {
		replaced := replacer.Replace(string(r))
		rs := []rune(replaced)
		if len(rs) == 1 {
			if rs[0] > unicode.MaxASCII {
				return -1
			}
			return rs[0]
		}
		return r
	}, value)
}

func formatKurus(kurus int64) string {
	sign := ""
	if kurus < 0 {
		sign = "-"
		kurus = -kurus
	}
	lira := kurus / 100
	remainder := kurus % 100
	return fmt.Sprintf("%s%d.%02d", sign, lira, remainder)
}

func parseAmount(value string) int64 {
	value = strings.TrimSpace(value)
	if value == "" {
		return 0
	}

	parts := strings.Split(value, ".")
	lira, _ := strconv.ParseInt(parts[0], 10, 64)
	kuruş := int64(0)
	if len(parts) > 1 {
		decimal := parts[1]
		if len(decimal) > 2 {
			decimal = decimal[:2]
		}
		for len(decimal) < 2 {
			decimal += "0"
		}
		kuruş, _ = strconv.ParseInt(decimal, 10, 64)
	}
	return lira*100 + kuruş
}

func issue(code string, message string, severity string) ETAValidationIssue {
	return ETAValidationIssue{Code: code, Message: message, Severity: severity}
}

func buildFileHash(fileType ETAFileType, content string) string {
	return fmt.Sprintf("eta-file:%s:%d:%d", fileType, len(content), len(strings.Split(content, "\n")))
}

func buildPackageHash(req ETAExportRequest, files []ETAExportFile, totalDebit int64, totalCredit int64) string {
	parts := []string{
		string(req.TargetSystem),
		string(req.FormatVersion),
		req.ExportID,
		req.PeriodCode,
		strconv.Itoa(req.FiscalYear),
		strconv.FormatInt(totalDebit, 10),
		strconv.FormatInt(totalCredit, 10),
	}
	for _, file := range files {
		parts = append(parts, file.FileHash)
	}
	return "eta-package:" + strings.Join(parts, ":")
}

func rejectedPackage(req ETAExportRequest, code string, message string) ETAExportPackage {
	return ETAExportPackage{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		ExportID:            req.ExportID,
		TargetSystem:        req.TargetSystem,
		FormatVersion:       req.FormatVersion,
		PeriodCode:          req.PeriodCode,
		FiscalYear:          req.FiscalYear,
		Status:              ExportStatusRejected,
		Balanced:            false,
		AuditAction:         "ETA_REAL_FORMAT_PACKAGE_REJECTED",
		AuditDecisionReason: "ETA format package rejected by validation guard",
		ErrorCode:           code,
		ErrorMessage:        message,
		CreatedAt:           time.Now().UTC(),
	}
}
