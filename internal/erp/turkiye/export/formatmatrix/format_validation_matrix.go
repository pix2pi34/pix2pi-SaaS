package formatmatrix

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"

	eta "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/export/eta"
	logo "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/export/logo"
	mikro "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/export/mikro"
	zirve "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/export/zirve"
	postingruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/postingruntime"
)

type TargetSystem string

const (
	TargetETA   TargetSystem = "ETA"
	TargetLogo  TargetSystem = "LOGO"
	TargetMikro TargetSystem = "MIKRO"
	TargetZirve TargetSystem = "ZIRVE"
)

type MatrixStatus string

const (
	MatrixStatusReady    MatrixStatus = "READY"
	MatrixStatusRejected MatrixStatus = "REJECTED"
)

type TargetStatus string

const (
	TargetStatusPass TargetStatus = "PASS"
	TargetStatusFail TargetStatus = "FAIL"
)

type RuntimeConfig struct {
	RuntimeEnabled        bool           `json:"runtime_enabled"`
	DefaultCurrencyCode   string         `json:"default_currency_code"`
	RequireAllTargets     bool           `json:"require_all_targets"`
	RequireBalanced       bool           `json:"require_balanced"`
	RequirePackageHash    bool           `json:"require_package_hash"`
	RequireFiles          bool           `json:"require_files"`
	RequireRows           bool           `json:"require_rows"`
	FailOnProviderIssue   bool           `json:"fail_on_provider_issue"`
	RequiredTargets       []TargetSystem `json:"required_targets"`
	RequiredFileMinimum   int            `json:"required_file_minimum"`
	RequiredRowMinimum    int            `json:"required_row_minimum"`
	RequiredAccountPrefix []string       `json:"required_account_prefix"`
}

type MatrixRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	MatrixID   string `json:"matrix_id"`
	PeriodCode string `json:"period_code"`
	FiscalYear int    `json:"fiscal_year"`

	Postings []postingruntime.PostingEntry `json:"postings"`

	RequestedBy string    `json:"requested_by"`
	RequestedAt time.Time `json:"requested_at"`
}

type TargetCheckResult struct {
	TargetSystem TargetSystem `json:"target_system"`
	Status       TargetStatus `json:"status"`

	ExportID      string `json:"export_id"`
	FormatVersion string `json:"format_version"`

	FileCount  int `json:"file_count"`
	RowCount   int `json:"row_count"`
	IssueCount int `json:"issue_count"`

	TotalDebitKurus  int64 `json:"total_debit_kurus"`
	TotalCreditKurus int64 `json:"total_credit_kurus"`
	Balanced         bool  `json:"balanced"`

	PackageHash string `json:"package_hash"`

	ErrorCode    string `json:"error_code"`
	ErrorMessage string `json:"error_message"`
}

type MatrixIssue struct {
	TargetSystem TargetSystem `json:"target_system"`
	Code         string       `json:"code"`
	Message      string       `json:"message"`
	Severity     string       `json:"severity"`
}

type MatrixResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	MatrixID   string `json:"matrix_id"`
	PeriodCode string `json:"period_code"`
	FiscalYear int    `json:"fiscal_year"`

	Status MatrixStatus `json:"status"`

	TargetResults []TargetCheckResult `json:"target_results"`
	Issues        []MatrixIssue       `json:"issues"`

	PassCount int `json:"pass_count"`
	FailCount int `json:"fail_count"`

	ReadyForAdapterTests bool `json:"ready_for_adapter_tests"`

	MatrixHash string `json:"matrix_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CreatedAt           time.Time `json:"created_at"`
}

type FormatValidationMatrixRuntime struct {
	config RuntimeConfig
}

func NewFormatValidationMatrixRuntime(config RuntimeConfig) (*FormatValidationMatrixRuntime, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("format validation matrix runtime is disabled")
	}
	if strings.TrimSpace(config.DefaultCurrencyCode) == "" {
		return nil, errors.New("default_currency_code is required")
	}
	if len(config.RequiredTargets) == 0 {
		return nil, errors.New("required_targets are required")
	}
	if config.RequiredFileMinimum <= 0 {
		return nil, errors.New("required_file_minimum must be positive")
	}
	if config.RequiredRowMinimum <= 0 {
		return nil, errors.New("required_row_minimum must be positive")
	}
	if len(config.RequiredAccountPrefix) == 0 {
		return nil, errors.New("required_account_prefix is required")
	}

	return &FormatValidationMatrixRuntime{config: config}, nil
}

func (r *FormatValidationMatrixRuntime) BuildMatrix(req MatrixRequest) (MatrixResult, error) {
	if err := r.validateRequest(req); err != nil {
		return rejectedMatrix(req, "VALIDATION_FAILED", err.Error()), err
	}

	targets := r.sortedTargets()
	targetResults := make([]TargetCheckResult, 0, len(targets))
	issues := make([]MatrixIssue, 0)

	for _, target := range targets {
		result, targetIssues := r.runTargetValidation(req, target)
		targetResults = append(targetResults, result)
		issues = append(issues, targetIssues...)
	}

	passCount := 0
	failCount := 0
	for _, result := range targetResults {
		if result.Status == TargetStatusPass {
			passCount++
		} else {
			failCount++
		}
	}

	status := MatrixStatusReady
	readyForAdapterTests := true
	auditAction := "FORMAT_VALIDATION_MATRIX_READY"
	auditDecisionReason := "all provider export formats passed matrix validation"

	if failCount > 0 || len(issues) > 0 {
		status = MatrixStatusRejected
		readyForAdapterTests = false
		auditAction = "FORMAT_VALIDATION_MATRIX_REJECTED"
		auditDecisionReason = "one or more provider export formats failed matrix validation"
	}

	result := MatrixResult{
		TenantID:             req.TenantID,
		CorrelationID:        req.CorrelationID,
		RequestID:            req.RequestID,
		IdempotencyKey:       req.IdempotencyKey,
		MatrixID:             req.MatrixID,
		PeriodCode:           req.PeriodCode,
		FiscalYear:           req.FiscalYear,
		Status:               status,
		TargetResults:        targetResults,
		Issues:               issues,
		PassCount:            passCount,
		FailCount:            failCount,
		ReadyForAdapterTests: readyForAdapterTests,
		MatrixHash:           buildMatrixHash(req, targetResults, issues),
		AuditAction:          auditAction,
		AuditDecisionReason:  auditDecisionReason,
		CreatedAt:            time.Now().UTC(),
	}

	if status != MatrixStatusReady {
		result.ErrorCode = "FORMAT_MATRIX_FAILED"
		result.ErrorMessage = "format validation matrix failed"
		return result, errors.New("format validation matrix failed")
	}

	return result, nil
}

func (r *FormatValidationMatrixRuntime) ValidateMatrixResult(result MatrixResult) []MatrixIssue {
	issues := make([]MatrixIssue, 0)

	if strings.TrimSpace(result.TenantID) == "" {
		issues = append(issues, matrixIssue("", "TENANT_ID_MISSING", "tenant_id is required", "BLOCKING"))
	}
	if strings.TrimSpace(result.MatrixID) == "" {
		issues = append(issues, matrixIssue("", "MATRIX_ID_MISSING", "matrix_id is required", "BLOCKING"))
	}
	if strings.TrimSpace(result.MatrixHash) == "" {
		issues = append(issues, matrixIssue("", "MATRIX_HASH_MISSING", "matrix_hash is required", "BLOCKING"))
	}
	if r.config.RequireAllTargets && len(result.TargetResults) != len(r.config.RequiredTargets) {
		issues = append(issues, matrixIssue("", "TARGET_COUNT_MISMATCH", "all required targets must be present", "BLOCKING"))
	}

	seenTargets := make(map[TargetSystem]bool)
	for _, targetResult := range result.TargetResults {
		seenTargets[targetResult.TargetSystem] = true
		issues = append(issues, r.validateTargetResult(targetResult)...)
	}

	for _, required := range r.config.RequiredTargets {
		if !seenTargets[required] {
			issues = append(issues, matrixIssue(required, "TARGET_MISSING", "required target is missing", "BLOCKING"))
		}
	}

	return issues
}

func (r *FormatValidationMatrixRuntime) runTargetValidation(req MatrixRequest, target TargetSystem) (TargetCheckResult, []MatrixIssue) {
	switch target {
	case TargetETA:
		return r.runETA(req)
	case TargetLogo:
		return r.runLogo(req)
	case TargetMikro:
		return r.runMikro(req)
	case TargetZirve:
		return r.runZirve(req)
	default:
		result := TargetCheckResult{
			TargetSystem: target,
			Status:       TargetStatusFail,
			ErrorCode:    "UNKNOWN_TARGET",
			ErrorMessage: "unknown target system",
		}
		return result, []MatrixIssue{matrixIssue(target, "UNKNOWN_TARGET", "unknown target system", "BLOCKING")}
	}
}

func (r *FormatValidationMatrixRuntime) runETA(req MatrixRequest) (TargetCheckResult, []MatrixIssue) {
	runtime, err := eta.NewETARealFormatRuntime(defaultETAConfig())
	if err != nil {
		return targetRuntimeError(TargetETA, err), []MatrixIssue{matrixIssue(TargetETA, "RUNTIME_INIT_FAILED", err.Error(), "BLOCKING")}
	}

	pkg, buildErr := runtime.BuildPackage(eta.ETAExportRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey + ":eta",
		ExportID:       req.MatrixID + "-eta",
		TargetSystem:   eta.TargetSystemETA,
		FormatVersion:  eta.ETAFormatV1,
		PeriodCode:     req.PeriodCode,
		FiscalYear:     req.FiscalYear,
		Postings:       req.Postings,
		RequestedBy:    req.RequestedBy,
		RequestedAt:    req.RequestedAt,
	})

	result := TargetCheckResult{
		TargetSystem:     TargetETA,
		ExportID:         pkg.ExportID,
		FormatVersion:    string(pkg.FormatVersion),
		FileCount:        len(pkg.Files),
		RowCount:         len(pkg.JournalRows),
		IssueCount:       len(pkg.Issues),
		TotalDebitKurus:  pkg.TotalDebitKurus,
		TotalCreditKurus: pkg.TotalCreditKurus,
		Balanced:         pkg.Balanced,
		PackageHash:      pkg.PackageHash,
	}

	issues := r.convertETAIssues(pkg.Issues)
	if buildErr != nil {
		result.Status = TargetStatusFail
		result.ErrorCode = pkg.ErrorCode
		result.ErrorMessage = buildErr.Error()
		issues = append(issues, matrixIssue(TargetETA, "BUILD_PACKAGE_FAILED", buildErr.Error(), "BLOCKING"))
		return result, issues
	}

	issues = append(issues, r.validateTargetResult(result)...)
	if len(issues) > 0 {
		result.Status = TargetStatusFail
		result.IssueCount = len(issues)
		return result, issues
	}

	result.Status = TargetStatusPass
	return result, nil
}

func (r *FormatValidationMatrixRuntime) runLogo(req MatrixRequest) (TargetCheckResult, []MatrixIssue) {
	runtime, err := logo.NewLogoRealFormatRuntime(defaultLogoConfig())
	if err != nil {
		return targetRuntimeError(TargetLogo, err), []MatrixIssue{matrixIssue(TargetLogo, "RUNTIME_INIT_FAILED", err.Error(), "BLOCKING")}
	}

	pkg, buildErr := runtime.BuildPackage(logo.LogoExportRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey + ":logo",
		ExportID:       req.MatrixID + "-logo",
		TargetSystem:   logo.TargetSystemLogo,
		FormatVersion:  logo.LogoFormatV1,
		PeriodCode:     req.PeriodCode,
		FiscalYear:     req.FiscalYear,
		Postings:       req.Postings,
		RequestedBy:    req.RequestedBy,
		RequestedAt:    req.RequestedAt,
	})

	result := TargetCheckResult{
		TargetSystem:     TargetLogo,
		ExportID:         pkg.ExportID,
		FormatVersion:    string(pkg.FormatVersion),
		FileCount:        len(pkg.Files),
		RowCount:         len(pkg.JournalRows),
		IssueCount:       len(pkg.Issues),
		TotalDebitKurus:  pkg.TotalDebitKurus,
		TotalCreditKurus: pkg.TotalCreditKurus,
		Balanced:         pkg.Balanced,
		PackageHash:      pkg.PackageHash,
	}

	issues := r.convertLogoIssues(pkg.Issues)
	if buildErr != nil {
		result.Status = TargetStatusFail
		result.ErrorCode = pkg.ErrorCode
		result.ErrorMessage = buildErr.Error()
		issues = append(issues, matrixIssue(TargetLogo, "BUILD_PACKAGE_FAILED", buildErr.Error(), "BLOCKING"))
		return result, issues
	}

	issues = append(issues, r.validateTargetResult(result)...)
	if len(issues) > 0 {
		result.Status = TargetStatusFail
		result.IssueCount = len(issues)
		return result, issues
	}

	result.Status = TargetStatusPass
	return result, nil
}

func (r *FormatValidationMatrixRuntime) runMikro(req MatrixRequest) (TargetCheckResult, []MatrixIssue) {
	runtime, err := mikro.NewMikroRealFormatRuntime(defaultMikroConfig())
	if err != nil {
		return targetRuntimeError(TargetMikro, err), []MatrixIssue{matrixIssue(TargetMikro, "RUNTIME_INIT_FAILED", err.Error(), "BLOCKING")}
	}

	pkg, buildErr := runtime.BuildPackage(mikro.MikroExportRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey + ":mikro",
		ExportID:       req.MatrixID + "-mikro",
		TargetSystem:   mikro.TargetSystemMikro,
		FormatVersion:  mikro.MikroFormatV1,
		PeriodCode:     req.PeriodCode,
		FiscalYear:     req.FiscalYear,
		Postings:       req.Postings,
		RequestedBy:    req.RequestedBy,
		RequestedAt:    req.RequestedAt,
	})

	result := TargetCheckResult{
		TargetSystem:     TargetMikro,
		ExportID:         pkg.ExportID,
		FormatVersion:    string(pkg.FormatVersion),
		FileCount:        len(pkg.Files),
		RowCount:         len(pkg.JournalRows),
		IssueCount:       len(pkg.Issues),
		TotalDebitKurus:  pkg.TotalDebitKurus,
		TotalCreditKurus: pkg.TotalCreditKurus,
		Balanced:         pkg.Balanced,
		PackageHash:      pkg.PackageHash,
	}

	issues := r.convertMikroIssues(pkg.Issues)
	if buildErr != nil {
		result.Status = TargetStatusFail
		result.ErrorCode = pkg.ErrorCode
		result.ErrorMessage = buildErr.Error()
		issues = append(issues, matrixIssue(TargetMikro, "BUILD_PACKAGE_FAILED", buildErr.Error(), "BLOCKING"))
		return result, issues
	}

	issues = append(issues, r.validateTargetResult(result)...)
	if len(issues) > 0 {
		result.Status = TargetStatusFail
		result.IssueCount = len(issues)
		return result, issues
	}

	result.Status = TargetStatusPass
	return result, nil
}

func (r *FormatValidationMatrixRuntime) runZirve(req MatrixRequest) (TargetCheckResult, []MatrixIssue) {
	runtime, err := zirve.NewZirveRealFormatRuntime(defaultZirveConfig())
	if err != nil {
		return targetRuntimeError(TargetZirve, err), []MatrixIssue{matrixIssue(TargetZirve, "RUNTIME_INIT_FAILED", err.Error(), "BLOCKING")}
	}

	pkg, buildErr := runtime.BuildPackage(zirve.ZirveExportRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey + ":zirve",
		ExportID:       req.MatrixID + "-zirve",
		TargetSystem:   zirve.TargetSystemZirve,
		FormatVersion:  zirve.ZirveFormatV1,
		PeriodCode:     req.PeriodCode,
		FiscalYear:     req.FiscalYear,
		Postings:       req.Postings,
		RequestedBy:    req.RequestedBy,
		RequestedAt:    req.RequestedAt,
	})

	result := TargetCheckResult{
		TargetSystem:     TargetZirve,
		ExportID:         pkg.ExportID,
		FormatVersion:    string(pkg.FormatVersion),
		FileCount:        len(pkg.Files),
		RowCount:         len(pkg.JournalRows),
		IssueCount:       len(pkg.Issues),
		TotalDebitKurus:  pkg.TotalDebitKurus,
		TotalCreditKurus: pkg.TotalCreditKurus,
		Balanced:         pkg.Balanced,
		PackageHash:      pkg.PackageHash,
	}

	issues := r.convertZirveIssues(pkg.Issues)
	if buildErr != nil {
		result.Status = TargetStatusFail
		result.ErrorCode = pkg.ErrorCode
		result.ErrorMessage = buildErr.Error()
		issues = append(issues, matrixIssue(TargetZirve, "BUILD_PACKAGE_FAILED", buildErr.Error(), "BLOCKING"))
		return result, issues
	}

	issues = append(issues, r.validateTargetResult(result)...)
	if len(issues) > 0 {
		result.Status = TargetStatusFail
		result.IssueCount = len(issues)
		return result, issues
	}

	result.Status = TargetStatusPass
	return result, nil
}

func (r *FormatValidationMatrixRuntime) validateRequest(req MatrixRequest) error {
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
	if strings.TrimSpace(req.MatrixID) == "" {
		return errors.New("matrix_id is required")
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

func (r *FormatValidationMatrixRuntime) validateTargetResult(result TargetCheckResult) []MatrixIssue {
	issues := make([]MatrixIssue, 0)

	if r.config.RequireFiles && result.FileCount < r.config.RequiredFileMinimum {
		issues = append(issues, matrixIssue(result.TargetSystem, "FILE_COUNT_TOO_LOW", "target export file count is below minimum", "BLOCKING"))
	}
	if r.config.RequireRows && result.RowCount < r.config.RequiredRowMinimum {
		issues = append(issues, matrixIssue(result.TargetSystem, "ROW_COUNT_TOO_LOW", "target export row count is below minimum", "BLOCKING"))
	}
	if r.config.RequireBalanced && !result.Balanced {
		issues = append(issues, matrixIssue(result.TargetSystem, "PACKAGE_NOT_BALANCED", "target package must be balanced", "BLOCKING"))
	}
	if r.config.RequirePackageHash && strings.TrimSpace(result.PackageHash) == "" {
		issues = append(issues, matrixIssue(result.TargetSystem, "PACKAGE_HASH_MISSING", "target package hash is required", "BLOCKING"))
	}
	if result.TotalDebitKurus != result.TotalCreditKurus {
		issues = append(issues, matrixIssue(result.TargetSystem, "TOTAL_MISMATCH", "target debit and credit totals must match", "BLOCKING"))
	}

	return issues
}

func (r *FormatValidationMatrixRuntime) sortedTargets() []TargetSystem {
	targets := append([]TargetSystem(nil), r.config.RequiredTargets...)
	sort.SliceStable(targets, func(i int, j int) bool {
		return targetOrder(targets[i]) < targetOrder(targets[j])
	})
	return targets
}

func targetOrder(target TargetSystem) int {
	switch target {
	case TargetETA:
		return 1
	case TargetLogo:
		return 2
	case TargetMikro:
		return 3
	case TargetZirve:
		return 4
	default:
		return 99
	}
}

func (r *FormatValidationMatrixRuntime) convertETAIssues(items []eta.ETAValidationIssue) []MatrixIssue {
	issues := make([]MatrixIssue, 0, len(items))
	for _, item := range items {
		issues = append(issues, matrixIssue(TargetETA, item.Code, item.Message, item.Severity))
	}
	return issues
}

func (r *FormatValidationMatrixRuntime) convertLogoIssues(items []logo.LogoValidationIssue) []MatrixIssue {
	issues := make([]MatrixIssue, 0, len(items))
	for _, item := range items {
		issues = append(issues, matrixIssue(TargetLogo, item.Code, item.Message, item.Severity))
	}
	return issues
}

func (r *FormatValidationMatrixRuntime) convertMikroIssues(items []mikro.MikroValidationIssue) []MatrixIssue {
	issues := make([]MatrixIssue, 0, len(items))
	for _, item := range items {
		issues = append(issues, matrixIssue(TargetMikro, item.Code, item.Message, item.Severity))
	}
	return issues
}

func (r *FormatValidationMatrixRuntime) convertZirveIssues(items []zirve.ZirveValidationIssue) []MatrixIssue {
	issues := make([]MatrixIssue, 0, len(items))
	for _, item := range items {
		issues = append(issues, matrixIssue(TargetZirve, item.Code, item.Message, item.Severity))
	}
	return issues
}

func matrixIssue(target TargetSystem, code string, message string, severity string) MatrixIssue {
	return MatrixIssue{TargetSystem: target, Code: code, Message: message, Severity: severity}
}

func targetRuntimeError(target TargetSystem, err error) TargetCheckResult {
	return TargetCheckResult{
		TargetSystem: target,
		Status:       TargetStatusFail,
		ErrorCode:    "RUNTIME_INIT_FAILED",
		ErrorMessage: err.Error(),
	}
}

func rejectedMatrix(req MatrixRequest, code string, message string) MatrixResult {
	return MatrixResult{
		TenantID:             req.TenantID,
		CorrelationID:        req.CorrelationID,
		RequestID:            req.RequestID,
		IdempotencyKey:       req.IdempotencyKey,
		MatrixID:             req.MatrixID,
		PeriodCode:           req.PeriodCode,
		FiscalYear:           req.FiscalYear,
		Status:               MatrixStatusRejected,
		ReadyForAdapterTests: false,
		AuditAction:          "FORMAT_VALIDATION_MATRIX_REJECTED",
		AuditDecisionReason:  "matrix request rejected by validation guard",
		ErrorCode:            code,
		ErrorMessage:         message,
		CreatedAt:            time.Now().UTC(),
	}
}

func buildMatrixHash(req MatrixRequest, targets []TargetCheckResult, issues []MatrixIssue) string {
	parts := []string{req.TenantID, req.MatrixID, req.PeriodCode, fmt.Sprintf("%d", req.FiscalYear)}
	for _, target := range targets {
		parts = append(parts, string(target.TargetSystem), string(target.Status), target.PackageHash)
	}
	parts = append(parts, fmt.Sprintf("issues:%d", len(issues)))
	return "format-matrix:" + strings.Join(parts, ":")
}

func defaultETAConfig() eta.RuntimeConfig {
	return eta.RuntimeConfig{
		RuntimeEnabled:          true,
		TargetSystem:            eta.TargetSystemETA,
		FormatVersion:           eta.ETAFormatV1,
		DefaultCurrencyCode:     "TRY",
		Delimiter:               "|",
		LineEnding:              "\n",
		StrictBalanceRequired:   true,
		RequirePostingHash:      true,
		RequireAuditTrace:       true,
		RequireTenantScope:      true,
		NormalizeTurkishChars:   true,
		MaxDescriptionLength:    120,
		AllowedFileTypes:        []eta.ETAFileType{eta.FileTypeJournal, eta.FileTypeLedger, eta.FileTypeSummary},
		RequiredAccountPrefixes: []string{"120", "191", "320", "391", "600", "610", "102", "153", "500"},
	}
}

func defaultLogoConfig() logo.RuntimeConfig {
	return logo.RuntimeConfig{
		RuntimeEnabled:          true,
		TargetSystem:            logo.TargetSystemLogo,
		FormatVersion:           logo.LogoFormatV1,
		DefaultCurrencyCode:     "TRY",
		Delimiter:               ";",
		LineEnding:              "\n",
		StrictBalanceRequired:   true,
		RequirePostingHash:      true,
		RequireAuditTrace:       true,
		RequireTenantScope:      true,
		NormalizeTurkishChars:   true,
		MaxDescriptionLength:    120,
		AllowedFileTypes:        []logo.LogoFileType{logo.FileTypeLogoJournalCSV, logo.FileTypeLogoLedgerCSV, logo.FileTypeLogoSummaryTXT},
		RequiredAccountPrefixes: []string{"120", "191", "320", "391", "600", "610", "102", "153", "500"},
	}
}

func defaultMikroConfig() mikro.RuntimeConfig {
	return mikro.RuntimeConfig{
		RuntimeEnabled:          true,
		TargetSystem:            mikro.TargetSystemMikro,
		FormatVersion:           mikro.MikroFormatV1,
		DefaultCurrencyCode:     "TRY",
		Delimiter:               ";",
		LineEnding:              "\n",
		StrictBalanceRequired:   true,
		RequirePostingHash:      true,
		RequireAuditTrace:       true,
		RequireTenantScope:      true,
		NormalizeTurkishChars:   true,
		MaxDescriptionLength:    120,
		AllowedFileTypes:        []mikro.MikroFileType{mikro.FileTypeMikroJournalCSV, mikro.FileTypeMikroLedgerCSV, mikro.FileTypeMikroSummaryTXT},
		RequiredAccountPrefixes: []string{"120", "191", "320", "391", "600", "610", "102", "153", "500"},
	}
}

func defaultZirveConfig() zirve.RuntimeConfig {
	return zirve.RuntimeConfig{
		RuntimeEnabled:          true,
		TargetSystem:            zirve.TargetSystemZirve,
		FormatVersion:           zirve.ZirveFormatV1,
		DefaultCurrencyCode:     "TRY",
		Delimiter:               "|",
		LineEnding:              "\n",
		StrictBalanceRequired:   true,
		RequirePostingHash:      true,
		RequireAuditTrace:       true,
		RequireTenantScope:      true,
		NormalizeTurkishChars:   true,
		MaxDescriptionLength:    120,
		AllowedFileTypes:        []zirve.ZirveFileType{zirve.FileTypeZirveJournalTXT, zirve.FileTypeZirveLedgerTXT, zirve.FileTypeZirveSummaryTXT},
		RequiredAccountPrefixes: []string{"120", "191", "320", "391", "600", "610", "102", "153", "500"},
	}
}
