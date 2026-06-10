package exportruntime

import (
	"errors"
	"fmt"
	"sort"
	"strconv"
	"strings"
	"time"

	companypermission "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/accountantportal/companypermission"
)

type ExportFormat string

const (
	ExportFormatExcel ExportFormat = "EXCEL"
	ExportFormatPDF   ExportFormat = "PDF"
	ExportFormatTDHP  ExportFormat = "TDHP"
)

type ExportStatus string

const (
	ExportStatusReady    ExportStatus = "READY"
	ExportStatusRejected ExportStatus = "REJECTED"
)

type RuntimeConfig struct {
	RuntimeEnabled            bool           `json:"runtime_enabled"`
	DefaultCurrencyCode       string         `json:"default_currency_code"`
	RequirePermissionDecision bool           `json:"require_permission_decision"`
	RequireTenantScope        bool           `json:"require_tenant_scope"`
	RequireCompanyScope       bool           `json:"require_company_scope"`
	RequireLedgerRows         bool           `json:"require_ledger_rows"`
	RequireBalancedExport     bool           `json:"require_balanced_export"`
	RequireExportHash         bool           `json:"require_export_hash"`
	RequireAuditSubject       bool           `json:"require_audit_subject"`
	MaxRows                   int            `json:"max_rows"`
	AllowedFormats            []ExportFormat `json:"allowed_formats"`
}

type LedgerExportRow struct {
	TenantID           string `json:"tenant_id"`
	TargetFirmTenantID string `json:"target_firm_tenant_id"`
	TargetCompanyID    string `json:"target_company_id"`

	PeriodCode   string    `json:"period_code"`
	DocumentNo   string    `json:"document_no"`
	DocumentDate time.Time `json:"document_date"`

	AccountCode string `json:"account_code"`
	AccountName string `json:"account_name"`

	DebitKurus  int64 `json:"debit_kurus"`
	CreditKurus int64 `json:"credit_kurus"`

	CurrencyCode string `json:"currency_code"`
	Description  string `json:"description"`
	PostingHash  string `json:"posting_hash"`
	AuditTraceID string `json:"audit_trace_id"`
}

type PortalExportRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ExportID string       `json:"export_id"`
	Format   ExportFormat `json:"format"`

	AccountantFirmID   string `json:"accountant_firm_id"`
	AccountantUserID   string `json:"accountant_user_id"`
	AssignmentID       string `json:"assignment_id"`
	TargetFirmTenantID string `json:"target_firm_tenant_id"`
	TargetCompanyID    string `json:"target_company_id"`
	TargetCompanyName  string `json:"target_company_name"`

	PeriodCode string `json:"period_code"`
	FiscalYear int    `json:"fiscal_year"`

	PermissionGrant companypermission.CompanyPermissionGrant `json:"permission_grant"`
	LedgerRows      []LedgerExportRow                        `json:"ledger_rows"`

	RequestedBy string    `json:"requested_by"`
	RequestedAt time.Time `json:"requested_at"`
}

type PortalExportFile struct {
	Format   ExportFormat `json:"format"`
	FileName string       `json:"file_name"`
	MimeType string       `json:"mime_type"`
	Content  string       `json:"content"`
	RowCount int          `json:"row_count"`
	FileHash string       `json:"file_hash"`
}

type PortalExportResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	ExportID string       `json:"export_id"`
	Format   ExportFormat `json:"format"`

	AccountantFirmID   string `json:"accountant_firm_id"`
	AccountantUserID   string `json:"accountant_user_id"`
	AssignmentID       string `json:"assignment_id"`
	TargetFirmTenantID string `json:"target_firm_tenant_id"`
	TargetCompanyID    string `json:"target_company_id"`

	Status ExportStatus `json:"status"`

	PermissionDecision companypermission.EnforcementDecision `json:"permission_decision"`
	File               PortalExportFile                      `json:"file"`

	TotalDebitKurus  int64 `json:"total_debit_kurus"`
	TotalCreditKurus int64 `json:"total_credit_kurus"`
	Balanced         bool  `json:"balanced"`

	ExportHash string `json:"export_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CreatedAt           time.Time `json:"created_at"`
}

type ExportBundleRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	BundleID string         `json:"bundle_id"`
	Formats  []ExportFormat `json:"formats"`

	BaseRequest PortalExportRequest `json:"base_request"`

	RequestedAt time.Time `json:"requested_at"`
}

type ExportBundleResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	BundleID string `json:"bundle_id"`

	Status ExportStatus `json:"status"`

	Exports []PortalExportResult `json:"exports"`

	PassCount int `json:"pass_count"`
	FailCount int `json:"fail_count"`

	BundleHash string `json:"bundle_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CreatedAt           time.Time `json:"created_at"`
}

type ExcelPDFTDHPExportRuntime struct {
	config            RuntimeConfig
	permissionRuntime *companypermission.CompanyPermissionEnforcementRuntime
}

func NewExcelPDFTDHPExportRuntime(config RuntimeConfig) (*ExcelPDFTDHPExportRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("excel/pdf/tdhp export runtime is disabled")
	}
	if strings.TrimSpace(config.DefaultCurrencyCode) == "" {
		return nil, errors.New("default_currency_code is required")
	}
	if config.MaxRows <= 0 {
		return nil, errors.New("max_rows must be positive")
	}
	if len(config.AllowedFormats) == 0 {
		return nil, errors.New("allowed_formats are required")
	}

	permissionRuntime, err := companypermission.NewCompanyPermissionEnforcementRuntime(defaultPermissionConfig())
	if err != nil {
		return nil, err
	}

	return &ExcelPDFTDHPExportRuntime{
		config:            config,
		permissionRuntime: permissionRuntime,
	}, nil
}

func (r *ExcelPDFTDHPExportRuntime) Export(req PortalExportRequest) (PortalExportResult, error) {
	if err := r.validateRequest(req); err != nil {
		return r.reject(req, companypermission.EnforcementDecision{}, "VALIDATION_FAILED", err.Error()), err
	}

	permissionDecision, err := r.permissionRuntime.Enforce(companypermission.EnforcementRequest{
		TenantID:           req.TenantID,
		CorrelationID:      req.CorrelationID,
		RequestID:          req.RequestID,
		IdempotencyKey:     req.IdempotencyKey + ":permission",
		AccountantFirmID:   req.AccountantFirmID,
		AccountantUserID:   req.AccountantUserID,
		AssignmentID:       req.AssignmentID,
		TargetFirmTenantID: req.TargetFirmTenantID,
		TargetCompanyID:    req.TargetCompanyID,
		ResourceType:       companypermission.ResourceTypeExport,
		RequiredPermission: r.permissionForFormat(req.Format),
		AuditSubject:       r.auditSubject(req),
		Grant:              req.PermissionGrant,
		RequestedAt:        req.RequestedAt,
	})
	if err != nil || !permissionDecision.Allowed {
		if err == nil {
			err = errors.New("permission decision denied")
		}
		return r.reject(req, permissionDecision, "PERMISSION_DENIED", err.Error()), err
	}

	totalDebit, totalCredit, err := r.validateRows(req)
	if err != nil {
		return r.reject(req, permissionDecision, "LEDGER_ROWS_INVALID", err.Error()), err
	}

	balanced := totalDebit == totalCredit
	if r.config.RequireBalancedExport && !balanced {
		err := errors.New("export debit and credit totals must match")
		return r.reject(req, permissionDecision, "EXPORT_NOT_BALANCED", err.Error()), err
	}

	file, err := r.buildFile(req)
	if err != nil {
		return r.reject(req, permissionDecision, "EXPORT_FILE_BUILD_FAILED", err.Error()), err
	}

	exportHash := buildExportHash(req, file, totalDebit, totalCredit)
	if r.config.RequireExportHash && exportHash == "" {
		err := errors.New("export_hash is required")
		return r.reject(req, permissionDecision, "EXPORT_HASH_MISSING", err.Error()), err
	}

	return PortalExportResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		ExportID:            req.ExportID,
		Format:              req.Format,
		AccountantFirmID:    req.AccountantFirmID,
		AccountantUserID:    req.AccountantUserID,
		AssignmentID:        req.AssignmentID,
		TargetFirmTenantID:  req.TargetFirmTenantID,
		TargetCompanyID:     req.TargetCompanyID,
		Status:              ExportStatusReady,
		PermissionDecision:  permissionDecision,
		File:                file,
		TotalDebitKurus:     totalDebit,
		TotalCreditKurus:    totalCredit,
		Balanced:            balanced,
		ExportHash:          exportHash,
		AuditAction:         "ACCOUNTANT_PORTAL_EXPORT_READY",
		AuditDecisionReason: "permission enforced Excel/PDF/TDHP export file generated",
		CreatedAt:           time.Now().UTC(),
	}, nil
}

func (r *ExcelPDFTDHPExportRuntime) ExportBundle(req ExportBundleRequest) (ExportBundleResult, error) {
	if err := r.validateBundleRequest(req); err != nil {
		return rejectedBundle(req, "VALIDATION_FAILED", err.Error()), err
	}

	formats := append([]ExportFormat(nil), req.Formats...)
	sort.SliceStable(formats, func(i int, j int) bool {
		return formatOrder(formats[i]) < formatOrder(formats[j])
	})

	results := make([]PortalExportResult, 0, len(formats))
	passCount := 0
	failCount := 0

	for _, format := range formats {
		itemReq := req.BaseRequest
		itemReq.Format = format
		itemReq.ExportID = req.BundleID + "-" + strings.ToLower(string(format))
		itemReq.IdempotencyKey = req.IdempotencyKey + ":" + strings.ToLower(string(format))

		result, err := r.Export(itemReq)
		results = append(results, result)
		if err != nil || result.Status != ExportStatusReady {
			failCount++
			continue
		}
		passCount++
	}

	status := ExportStatusReady
	auditAction := "ACCOUNTANT_PORTAL_EXPORT_BUNDLE_READY"
	auditReason := "all requested accountant portal export formats generated"
	if failCount > 0 {
		status = ExportStatusRejected
		auditAction = "ACCOUNTANT_PORTAL_EXPORT_BUNDLE_REJECTED"
		auditReason = "one or more requested accountant portal export formats failed"
	}

	result := ExportBundleResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		BundleID:            req.BundleID,
		Status:              status,
		Exports:             results,
		PassCount:           passCount,
		FailCount:           failCount,
		BundleHash:          buildBundleHash(req, results),
		AuditAction:         auditAction,
		AuditDecisionReason: auditReason,
		CreatedAt:           time.Now().UTC(),
	}

	if status != ExportStatusReady {
		result.ErrorCode = "EXPORT_BUNDLE_FAILED"
		result.ErrorMessage = "export bundle contains failed exports"
		return result, errors.New("export bundle contains failed exports")
	}

	return result, nil
}

func (r *ExcelPDFTDHPExportRuntime) validateRequest(req PortalExportRequest) error {
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
	if !r.formatAllowed(req.Format) {
		return errors.New("export format is not allowed")
	}
	if strings.TrimSpace(req.AccountantFirmID) == "" {
		return errors.New("accountant_firm_id is required")
	}
	if strings.TrimSpace(req.AccountantUserID) == "" {
		return errors.New("accountant_user_id is required")
	}
	if strings.TrimSpace(req.AssignmentID) == "" {
		return errors.New("assignment_id is required")
	}
	if strings.TrimSpace(req.TargetFirmTenantID) == "" {
		return errors.New("target_firm_tenant_id is required")
	}
	if strings.TrimSpace(req.TargetCompanyID) == "" {
		return errors.New("target_company_id is required")
	}
	if strings.TrimSpace(req.TargetCompanyName) == "" {
		return errors.New("target_company_name is required")
	}
	if strings.TrimSpace(req.PeriodCode) == "" {
		return errors.New("period_code is required")
	}
	if req.FiscalYear <= 2000 {
		return errors.New("fiscal_year is invalid")
	}
	if r.config.RequireLedgerRows && len(req.LedgerRows) == 0 {
		return errors.New("ledger_rows are required")
	}
	if len(req.LedgerRows) > r.config.MaxRows {
		return errors.New("ledger_rows exceed max_rows")
	}
	if strings.TrimSpace(req.RequestedBy) == "" {
		return errors.New("requested_by is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *ExcelPDFTDHPExportRuntime) validateBundleRequest(req ExportBundleRequest) error {
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
	if strings.TrimSpace(req.BundleID) == "" {
		return errors.New("bundle_id is required")
	}
	if len(req.Formats) == 0 {
		return errors.New("formats are required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (r *ExcelPDFTDHPExportRuntime) validateRows(req PortalExportRequest) (int64, int64, error) {
	var totalDebit int64
	var totalCredit int64

	for _, row := range req.LedgerRows {
		if r.config.RequireTenantScope && row.TenantID != req.TenantID {
			return 0, 0, errors.New("ledger row tenant_id mismatch")
		}
		if r.config.RequireTenantScope && row.TargetFirmTenantID != req.TargetFirmTenantID {
			return 0, 0, errors.New("ledger row target_firm_tenant_id mismatch")
		}
		if r.config.RequireCompanyScope && row.TargetCompanyID != req.TargetCompanyID {
			return 0, 0, errors.New("ledger row target_company_id mismatch")
		}
		if strings.TrimSpace(row.PeriodCode) != req.PeriodCode {
			return 0, 0, errors.New("ledger row period_code mismatch")
		}
		if strings.TrimSpace(row.DocumentNo) == "" {
			return 0, 0, errors.New("ledger row document_no is required")
		}
		if row.DocumentDate.IsZero() {
			return 0, 0, errors.New("ledger row document_date is required")
		}
		if strings.TrimSpace(row.AccountCode) == "" {
			return 0, 0, errors.New("ledger row account_code is required")
		}
		if strings.TrimSpace(row.AccountName) == "" {
			return 0, 0, errors.New("ledger row account_name is required")
		}
		if row.DebitKurus < 0 || row.CreditKurus < 0 {
			return 0, 0, errors.New("ledger row debit/credit cannot be negative")
		}
		if row.DebitKurus == 0 && row.CreditKurus == 0 {
			return 0, 0, errors.New("ledger row debit or credit amount is required")
		}
		if row.DebitKurus > 0 && row.CreditKurus > 0 {
			return 0, 0, errors.New("ledger row cannot have both debit and credit")
		}
		if row.CurrencyCode != r.config.DefaultCurrencyCode {
			return 0, 0, errors.New("ledger row currency_code mismatch")
		}
		if strings.TrimSpace(row.PostingHash) == "" {
			return 0, 0, errors.New("ledger row posting_hash is required")
		}
		if strings.TrimSpace(row.AuditTraceID) == "" {
			return 0, 0, errors.New("ledger row audit_trace_id is required")
		}

		totalDebit += row.DebitKurus
		totalCredit += row.CreditKurus
	}

	return totalDebit, totalCredit, nil
}

func (r *ExcelPDFTDHPExportRuntime) buildFile(req PortalExportRequest) (PortalExportFile, error) {
	switch req.Format {
	case ExportFormatExcel:
		return r.buildExcelFile(req), nil
	case ExportFormatPDF:
		return r.buildPDFFile(req), nil
	case ExportFormatTDHP:
		return r.buildTDHPFile(req), nil
	default:
		return PortalExportFile{}, errors.New("unsupported export format")
	}
}

func (r *ExcelPDFTDHPExportRuntime) buildExcelFile(req PortalExportRequest) PortalExportFile {
	header := []string{"TARIH", "BELGE_NO", "HESAP_KODU", "HESAP_ADI", "BORC", "ALACAK", "PARA_BIRIMI", "ACIKLAMA", "POSTING_HASH"}
	lines := []string{strings.Join(header, ";")}

	for _, row := range req.LedgerRows {
		lines = append(lines, strings.Join([]string{
			row.DocumentDate.Format("2006-01-02"),
			normalizeField(row.DocumentNo),
			normalizeField(row.AccountCode),
			normalizeField(row.AccountName),
			formatKurus(row.DebitKurus),
			formatKurus(row.CreditKurus),
			row.CurrencyCode,
			normalizeField(row.Description),
			row.PostingHash,
		}, ";"))
	}

	content := strings.Join(lines, "\n") + "\n"
	return PortalExportFile{
		Format:   ExportFormatExcel,
		FileName: fmt.Sprintf("%s_%s_EXCEL.csv", req.TargetCompanyID, req.PeriodCode),
		MimeType: "text/csv",
		Content:  content,
		RowCount: len(req.LedgerRows),
		FileHash: buildFileHash(ExportFormatExcel, content),
	}
}

func (r *ExcelPDFTDHPExportRuntime) buildPDFFile(req PortalExportRequest) PortalExportFile {
	lines := []string{
		"PDF_SIMULATION",
		"COMPANY=" + normalizeField(req.TargetCompanyName),
		"PERIOD=" + req.PeriodCode,
		"FISCAL_YEAR=" + strconv.Itoa(req.FiscalYear),
		"ROWS=" + strconv.Itoa(len(req.LedgerRows)),
	}

	var totalDebit int64
	var totalCredit int64
	for _, row := range req.LedgerRows {
		totalDebit += row.DebitKurus
		totalCredit += row.CreditKurus
		lines = append(lines, strings.Join([]string{
			row.DocumentDate.Format("2006-01-02"),
			row.DocumentNo,
			row.AccountCode,
			row.AccountName,
			formatKurus(row.DebitKurus),
			formatKurus(row.CreditKurus),
			row.CurrencyCode,
		}, "|"))
	}

	lines = append(lines, "TOTAL_DEBIT="+formatKurus(totalDebit))
	lines = append(lines, "TOTAL_CREDIT="+formatKurus(totalCredit))

	content := strings.Join(lines, "\n") + "\n"
	return PortalExportFile{
		Format:   ExportFormatPDF,
		FileName: fmt.Sprintf("%s_%s_PDF.txt", req.TargetCompanyID, req.PeriodCode),
		MimeType: "text/plain",
		Content:  content,
		RowCount: len(req.LedgerRows),
		FileHash: buildFileHash(ExportFormatPDF, content),
	}
}

func (r *ExcelPDFTDHPExportRuntime) buildTDHPFile(req PortalExportRequest) PortalExportFile {
	header := []string{"TDHP", "TARIH", "BELGE_NO", "HESAP", "BORC", "ALACAK", "IZ_HASH"}
	lines := []string{strings.Join(header, "|")}

	for _, row := range req.LedgerRows {
		lines = append(lines, strings.Join([]string{
			"TDHP",
			row.DocumentDate.Format("2006-01-02"),
			normalizeField(row.DocumentNo),
			normalizeField(row.AccountCode),
			formatKurus(row.DebitKurus),
			formatKurus(row.CreditKurus),
			row.PostingHash,
		}, "|"))
	}

	content := strings.Join(lines, "\n") + "\n"
	return PortalExportFile{
		Format:   ExportFormatTDHP,
		FileName: fmt.Sprintf("%s_%s_TDHP.txt", req.TargetCompanyID, req.PeriodCode),
		MimeType: "text/plain",
		Content:  content,
		RowCount: len(req.LedgerRows),
		FileHash: buildFileHash(ExportFormatTDHP, content),
	}
}

func (r *ExcelPDFTDHPExportRuntime) permissionForFormat(format ExportFormat) companypermission.Permission {
	switch format {
	case ExportFormatExcel:
		return companypermission.PermissionExportExcel
	case ExportFormatPDF:
		return companypermission.PermissionExportPDF
	case ExportFormatTDHP:
		return companypermission.PermissionExportTDHP
	default:
		return companypermission.PermissionExportTDHP
	}
}

func (r *ExcelPDFTDHPExportRuntime) auditSubject(req PortalExportRequest) string {
	return req.TargetCompanyID + ":" + strings.ToLower(string(req.Format)) + ":" + req.PeriodCode
}

func (r *ExcelPDFTDHPExportRuntime) formatAllowed(format ExportFormat) bool {
	for _, allowed := range r.config.AllowedFormats {
		if allowed == format {
			return true
		}
	}
	return false
}

func (r *ExcelPDFTDHPExportRuntime) reject(req PortalExportRequest, decision companypermission.EnforcementDecision, code string, message string) PortalExportResult {
	return PortalExportResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		ExportID:            req.ExportID,
		Format:              req.Format,
		AccountantFirmID:    req.AccountantFirmID,
		AccountantUserID:    req.AccountantUserID,
		AssignmentID:        req.AssignmentID,
		TargetFirmTenantID:  req.TargetFirmTenantID,
		TargetCompanyID:     req.TargetCompanyID,
		Status:              ExportStatusRejected,
		PermissionDecision:  decision,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "ACCOUNTANT_PORTAL_EXPORT_REJECTED",
		AuditDecisionReason: "Excel/PDF/TDHP export rejected by runtime guard",
		CreatedAt:           time.Now().UTC(),
	}
}

func formatOrder(format ExportFormat) int {
	switch format {
	case ExportFormatExcel:
		return 1
	case ExportFormatPDF:
		return 2
	case ExportFormatTDHP:
		return 3
	default:
		return 99
	}
}

func normalizeField(value string) string {
	value = strings.TrimSpace(value)
	value = strings.ReplaceAll(value, "\n", " ")
	value = strings.ReplaceAll(value, "\r", " ")
	value = strings.ReplaceAll(value, ";", ",")
	value = strings.ReplaceAll(value, "|", "/")
	return strings.Join(strings.Fields(value), " ")
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

func buildFileHash(format ExportFormat, content string) string {
	return fmt.Sprintf("portal-export-file:%s:%d:%d", format, len(content), strings.Count(content, "\n"))
}

func buildExportHash(req PortalExportRequest, file PortalExportFile, totalDebit int64, totalCredit int64) string {
	parts := []string{
		req.TenantID,
		req.ExportID,
		string(req.Format),
		req.TargetCompanyID,
		req.PeriodCode,
		strconv.FormatInt(totalDebit, 10),
		strconv.FormatInt(totalCredit, 10),
		file.FileHash,
	}
	return "portal-export:" + strings.Join(parts, ":")
}

func buildBundleHash(req ExportBundleRequest, results []PortalExportResult) string {
	parts := []string{
		req.TenantID,
		req.BundleID,
		fmt.Sprintf("exports:%d", len(results)),
	}
	for _, result := range results {
		parts = append(parts, result.ExportHash)
	}
	return "portal-export-bundle:" + strings.Join(parts, ":")
}

func rejectedBundle(req ExportBundleRequest, code string, message string) ExportBundleResult {
	return ExportBundleResult{
		TenantID:            req.TenantID,
		CorrelationID:       req.CorrelationID,
		RequestID:           req.RequestID,
		IdempotencyKey:      req.IdempotencyKey,
		BundleID:            req.BundleID,
		Status:              ExportStatusRejected,
		ErrorCode:           code,
		ErrorMessage:        message,
		AuditAction:         "ACCOUNTANT_PORTAL_EXPORT_BUNDLE_REJECTED",
		AuditDecisionReason: "export bundle rejected by validation guard",
		CreatedAt:           time.Now().UTC(),
	}
}

func defaultPermissionConfig() companypermission.RuntimeConfig {
	return companypermission.RuntimeConfig{
		RuntimeEnabled:            true,
		RequireTenantScope:        true,
		RequireCompanyScope:       true,
		RequireAssignmentScope:    true,
		RequireResourcePermission: true,
		RequireRolePermissionMap:  true,
		RequireExplicitGrant:      true,
		RequireAuditSubject:       true,
		AllowSuperAdminOverride:   false,
		RequiredPermissions: []companypermission.Permission{
			companypermission.PermissionViewFirm,
			companypermission.PermissionViewLedger,
			companypermission.PermissionExportExcel,
			companypermission.PermissionExportPDF,
			companypermission.PermissionExportTDHP,
			companypermission.PermissionManageAssignment,
			companypermission.PermissionViewSubscription,
		},
		AllowedRoles: []companypermission.PortalRole{
			companypermission.PortalRoleOwner,
			companypermission.PortalRoleStaff,
			companypermission.PortalRoleReadOnly,
			companypermission.PortalRoleSuperAdmin,
		},
		AllowedResourceTypes: []companypermission.ResourceType{
			companypermission.ResourceTypeFirm,
			companypermission.ResourceTypeLedger,
			companypermission.ResourceTypeExport,
			companypermission.ResourceTypeAssignment,
			companypermission.ResourceTypeSubscription,
		},
	}
}
