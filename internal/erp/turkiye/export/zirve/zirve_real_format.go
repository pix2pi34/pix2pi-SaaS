package zirve

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
	TargetSystemZirve TargetSystem = "ZIRVE"
)

type ZirveFormatVersion string

const (
	ZirveFormatV1 ZirveFormatVersion = "ZIRVE_TDHP_V1"
)

type ZirveFileType string

const (
	FileTypeZirveJournalTXT ZirveFileType = "ZIRVE_JOURNAL_TXT"
	FileTypeZirveLedgerTXT  ZirveFileType = "ZIRVE_LEDGER_TXT"
	FileTypeZirveSummaryTXT ZirveFileType = "ZIRVE_SUMMARY_TXT"
)

type ExportStatus string

const (
	ExportStatusReady    ExportStatus = "READY"
	ExportStatusRejected ExportStatus = "REJECTED"
)

type RuntimeConfig struct {
	RuntimeEnabled          bool               `json:"runtime_enabled"`
	TargetSystem            TargetSystem       `json:"target_system"`
	FormatVersion           ZirveFormatVersion `json:"format_version"`
	DefaultCurrencyCode     string             `json:"default_currency_code"`
	Delimiter               string             `json:"delimiter"`
	LineEnding              string             `json:"line_ending"`
	StrictBalanceRequired   bool               `json:"strict_balance_required"`
	RequirePostingHash      bool               `json:"require_posting_hash"`
	RequireAuditTrace       bool               `json:"require_audit_trace"`
	RequireTenantScope      bool               `json:"require_tenant_scope"`
	NormalizeTurkishChars   bool               `json:"normalize_turkish_chars"`
	MaxDescriptionLength    int                `json:"max_description_length"`
	AllowedFileTypes        []ZirveFileType    `json:"allowed_file_types"`
	RequiredAccountPrefixes []string           `json:"required_account_prefixes"`
}

type ZirveExportRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ExportID      string             `json:"export_id"`
	TargetSystem  TargetSystem       `json:"target_system"`
	FormatVersion ZirveFormatVersion `json:"format_version"`

	PeriodCode string `json:"period_code"`
	FiscalYear int    `json:"fiscal_year"`

	Postings []postingruntime.PostingEntry `json:"postings"`

	RequestedBy string    `json:"requested_by"`
	RequestedAt time.Time `json:"requested_at"`
}

type ZirveJournalRow struct {
	TenantID  string `json:"tenant_id"`
	ExportID  string `json:"export_id"`
	PostingID string `json:"posting_id"`
	PostingNo string `json:"posting_no"`
	LineNo    int    `json:"line_no"`

	Tarih       string `json:"tarih"`
	FisNo       string `json:"fis_no"`
	BelgeNo     string `json:"belge_no"`
	HesapKodu   string `json:"hesap_kodu"`
	HesapAdi    string `json:"hesap_adi"`
	Borc        string `json:"borc"`
	Alacak      string `json:"alacak"`
	ParaBirimi  string `json:"para_birimi"`
	Aciklama    string `json:"aciklama"`
	VergiNo     string `json:"vergi_no"`
	PostingHash string `json:"posting_hash"`
}

type ZirveExportFile struct {
	FileType  ZirveFileType `json:"file_type"`
	FileName  string        `json:"file_name"`
	MimeType  string        `json:"mime_type"`
	Content   string        `json:"content"`
	LineCount int           `json:"line_count"`
	FileHash  string        `json:"file_hash"`
}

type ZirveValidationIssue struct {
	Code     string `json:"code"`
	Message  string `json:"message"`
	Severity string `json:"severity"`
}

type ZirveExportPackage struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ExportID      string             `json:"export_id"`
	TargetSystem  TargetSystem       `json:"target_system"`
	FormatVersion ZirveFormatVersion `json:"format_version"`
	PeriodCode    string             `json:"period_code"`
	FiscalYear    int                `json:"fiscal_year"`

	Status ExportStatus `json:"status"`

	JournalRows []ZirveJournalRow      `json:"journal_rows"`
	Files       []ZirveExportFile      `json:"files"`
	Issues      []ZirveValidationIssue `json:"issues"`

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

type ZirveRealFormatRuntime struct {
	config RuntimeConfig
}

func NewZirveRealFormatRuntime(config RuntimeConfig) (*ZirveRealFormatRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("Zirve real format runtime is disabled")
	}
	if config.TargetSystem != TargetSystemZirve {
		return nil, errors.New("target_system must be ZIRVE")
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

	return &ZirveRealFormatRuntime{config: config}, nil
}

func (r *ZirveRealFormatRuntime) BuildPackage(req ZirveExportRequest) (ZirveExportPackage, error) {
	if err := r.validateRequest(req); err != nil {
		return rejectedPackage(req, "VALIDATION_FAILED", err.Error()), err
	}

	rows, totalDebit, totalCredit, err := r.buildJournalRows(req)
	if err != nil {
		return rejectedPackage(req, "ROW_BUILD_FAILED", err.Error()), err
	}

	balanced := totalDebit == totalCredit
	if r.config.StrictBalanceRequired && !balanced {
		return rejectedPackage(req, "ZIRVE_EXPORT_NOT_BALANCED", "Zirve export debit and credit totals are not equal"), errors.New("Zirve export debit and credit totals are not equal")
	}

	files := []ZirveExportFile{
		r.buildJournalFile(req, rows),
		r.buildLedgerFile(req, rows),
		r.buildSummaryFile(req, rows, totalDebit, totalCredit),
	}

	issues := r.validateRows(rows)
	if len(issues) > 0 {
		pkg := rejectedPackage(req, "ZIRVE_VALIDATION_ISSUES", "Zirve export validation issues detected")
		pkg.JournalRows = rows
		pkg.Files = files
		pkg.Issues = issues
		pkg.TotalDebitKurus = totalDebit
		pkg.TotalCreditKurus = totalCredit
		pkg.Balanced = balanced
		pkg.PackageHash = buildPackageHash(req, files, totalDebit, totalCredit)
		return pkg, errors.New("Zirve export validation issues detected")
	}

	return ZirveExportPackage{
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
		AuditAction:         "ZIRVE_REAL_FORMAT_PACKAGE_READY",
		AuditDecisionReason: "posting entries converted to Zirve journal, ledger and summary files",
		CreatedAt:           time.Now().UTC(),
	}, nil
}

func (r *ZirveRealFormatRuntime) ValidatePackage(pkg ZirveExportPackage) []ZirveValidationIssue {
	issues := make([]ZirveValidationIssue, 0)

	if strings.TrimSpace(pkg.TenantID) == "" {
		issues = append(issues, issue("TENANT_ID_MISSING", "tenant_id is required", "BLOCKING"))
	}
	if pkg.TargetSystem != TargetSystemZirve {
		issues = append(issues, issue("TARGET_SYSTEM_INVALID", "target_system must be ZIRVE", "BLOCKING"))
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

func (r *ZirveRealFormatRuntime) buildJournalRows(req ZirveExportRequest) ([]ZirveJournalRow, int64, int64, error) {
	rows := make([]ZirveJournalRow, 0)
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

			rows = append(rows, ZirveJournalRow{
				TenantID:    req.TenantID,
				ExportID:    req.ExportID,
				PostingID:   posting.PostingID,
				PostingNo:   posting.PostingNo,
				LineNo:      line.LineNo,
				Tarih:       posting.DocumentDate.Format("02/01/2006"),
				FisNo:       normalizeZirveField(posting.PostingNo, r.config.NormalizeTurkishChars, 30),
				BelgeNo:     normalizeZirveField(posting.DocumentNo, r.config.NormalizeTurkishChars, 30),
				HesapKodu:   normalizeZirveField(line.AccountCode, false, 32),
				HesapAdi:    normalizeZirveField(line.AccountName, r.config.NormalizeTurkishChars, 80),
				Borc:        formatKurus(line.DebitAmountKurus),
				Alacak:      formatKurus(line.CreditAmountKurus),
				ParaBirimi:  posting.CurrencyCode,
				Aciklama:    normalizeZirveField(line.Description, r.config.NormalizeTurkishChars, r.config.MaxDescriptionLength),
				VergiNo:     normalizeZirveField(line.PartyTaxNo, false, 20),
				PostingHash: posting.PostingHash,
			})
		}
	}

	return rows, totalDebit, totalCredit, nil
}

func (r *ZirveRealFormatRuntime) validateRequest(req ZirveExportRequest) error {
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
	if req.TargetSystem != TargetSystemZirve {
		return errors.New("target_system must be ZIRVE")
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

func (r *ZirveRealFormatRuntime) validatePosting(expectedTenantID string, posting postingruntime.PostingEntry) error {
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

func (r *ZirveRealFormatRuntime) validateRows(rows []ZirveJournalRow) []ZirveValidationIssue {
	issues := make([]ZirveValidationIssue, 0)

	for _, row := range rows {
		if strings.TrimSpace(row.Tarih) == "" {
			issues = append(issues, issue("ROW_DATE_MISSING", "row tarih is required", "BLOCKING"))
		}
		if strings.TrimSpace(row.FisNo) == "" {
			issues = append(issues, issue("ROW_FIS_NO_MISSING", "row fis_no is required", "BLOCKING"))
		}
		if strings.TrimSpace(row.BelgeNo) == "" {
			issues = append(issues, issue("ROW_BELGE_NO_MISSING", "row belge_no is required", "BLOCKING"))
		}
		if strings.TrimSpace(row.HesapKodu) == "" {
			issues = append(issues, issue("ROW_HESAP_KODU_MISSING", "row hesap_kodu is required", "BLOCKING"))
		}
		if !r.accountPrefixAllowed(row.HesapKodu) {
			issues = append(issues, issue("ROW_ACCOUNT_PREFIX_INVALID", "row hesap_kodu prefix is not allowed", "BLOCKING"))
		}
		if strings.TrimSpace(row.ParaBirimi) != r.config.DefaultCurrencyCode {
			issues = append(issues, issue("ROW_CURRENCY_INVALID", "row para_birimi must be TRY", "BLOCKING"))
		}
		if strings.TrimSpace(row.PostingHash) == "" {
			issues = append(issues, issue("ROW_POSTING_HASH_MISSING", "row posting_hash is required", "BLOCKING"))
		}
	}

	return issues
}

func (r *ZirveRealFormatRuntime) accountPrefixAllowed(accountCode string) bool {
	for _, prefix := range r.config.RequiredAccountPrefixes {
		if strings.HasPrefix(accountCode, prefix) {
			return true
		}
	}
	return false
}

func (r *ZirveRealFormatRuntime) buildJournalFile(req ZirveExportRequest, rows []ZirveJournalRow) ZirveExportFile {
	header := []string{"TARIH", "FIS_NO", "SATIR_NO", "BELGE_NO", "HESAP_KODU", "HESAP_ADI", "BORC", "ALACAK", "PARA_BIRIMI", "ACIKLAMA", "VERGI_NO", "POSTING_HASH"}
	lines := []string{strings.Join(header, r.config.Delimiter)}

	for _, row := range rows {
		fields := []string{
			row.Tarih,
			row.FisNo,
			strconv.Itoa(row.LineNo),
			row.BelgeNo,
			row.HesapKodu,
			row.HesapAdi,
			row.Borc,
			row.Alacak,
			row.ParaBirimi,
			row.Aciklama,
			row.VergiNo,
			row.PostingHash,
		}
		lines = append(lines, strings.Join(fields, r.config.Delimiter))
	}

	content := strings.Join(lines, r.config.LineEnding) + r.config.LineEnding
	return ZirveExportFile{
		FileType:  FileTypeZirveJournalTXT,
		FileName:  fmt.Sprintf("%s_ZIRVE_JOURNAL.txt", req.ExportID),
		MimeType:  "text/plain",
		Content:   content,
		LineCount: len(lines),
		FileHash:  buildFileHash(FileTypeZirveJournalTXT, content),
	}
}

func (r *ZirveRealFormatRuntime) buildLedgerFile(req ZirveExportRequest, rows []ZirveJournalRow) ZirveExportFile {
	header := []string{"HESAP_KODU", "HESAP_ADI", "BORC", "ALACAK", "PARA_BIRIMI"}
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
		item, ok := aggs[row.HesapKodu]
		if !ok {
			item = &agg{accountCode: row.HesapKodu, accountName: row.HesapAdi, currency: row.ParaBirimi}
			aggs[row.HesapKodu] = item
		}
		item.debitKurus += parseAmount(row.Borc)
		item.creditKurus += parseAmount(row.Alacak)
	}

	keys := make([]string, 0, len(aggs))
	for key := range aggs {
		keys = append(keys, key)
	}
	sort.Strings(keys)

	for _, key := range keys {
		item := aggs[key]
		lines = append(lines, strings.Join([]string{
			item.accountCode,
			item.accountName,
			formatKurus(item.debitKurus),
			formatKurus(item.creditKurus),
			item.currency,
		}, r.config.Delimiter))
	}

	content := strings.Join(lines, r.config.LineEnding) + r.config.LineEnding
	return ZirveExportFile{
		FileType:  FileTypeZirveLedgerTXT,
		FileName:  fmt.Sprintf("%s_ZIRVE_LEDGER.txt", req.ExportID),
		MimeType:  "text/plain",
		Content:   content,
		LineCount: len(lines),
		FileHash:  buildFileHash(FileTypeZirveLedgerTXT, content),
	}
}

func (r *ZirveRealFormatRuntime) buildSummaryFile(req ZirveExportRequest, rows []ZirveJournalRow, totalDebit int64, totalCredit int64) ZirveExportFile {
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
	return ZirveExportFile{
		FileType:  FileTypeZirveSummaryTXT,
		FileName:  fmt.Sprintf("%s_ZIRVE_SUMMARY.txt", req.ExportID),
		MimeType:  "text/plain",
		Content:   content,
		LineCount: len(lines),
		FileHash:  buildFileHash(FileTypeZirveSummaryTXT, content),
	}
}

func normalizeZirveField(value string, normalizeTurkish bool, maxLength int) string {
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
	kurus := int64(0)
	if len(parts) > 1 {
		decimal := parts[1]
		if len(decimal) > 2 {
			decimal = decimal[:2]
		}
		for len(decimal) < 2 {
			decimal += "0"
		}
		kurus, _ = strconv.ParseInt(decimal, 10, 64)
	}
	return lira*100 + kurus
}

func issue(code string, message string, severity string) ZirveValidationIssue {
	return ZirveValidationIssue{Code: code, Message: message, Severity: severity}
}

func buildFileHash(fileType ZirveFileType, content string) string {
	return fmt.Sprintf("zirve-file:%s:%d:%d", fileType, len(content), len(strings.Split(content, "\n")))
}

func buildPackageHash(req ZirveExportRequest, files []ZirveExportFile, totalDebit int64, totalCredit int64) string {
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
	return "zirve-package:" + strings.Join(parts, ":")
}

func rejectedPackage(req ZirveExportRequest, code string, message string) ZirveExportPackage {
	return ZirveExportPackage{
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
		AuditAction:         "ZIRVE_REAL_FORMAT_PACKAGE_REJECTED",
		AuditDecisionReason: "Zirve format package rejected by validation guard",
		ErrorCode:           code,
		ErrorMessage:        message,
		CreatedAt:           time.Now().UTC(),
	}
}
