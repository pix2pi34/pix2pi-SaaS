package adaptertests

import (
	"errors"
	"fmt"
	"time"

	eta "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/export/eta"
	formatmatrix "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/export/formatmatrix"
	logo "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/export/logo"
	mikro "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/export/mikro"
	zirve "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/export/zirve"
	postingruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/postingruntime"
)

type ExportAdapterTestStatus string

const (
	ExportAdapterTestStatusPass ExportAdapterTestStatus = "PASS"
	ExportAdapterTestStatusFail ExportAdapterTestStatus = "FAIL"
)

type RuntimeConfig struct {
	RuntimeEnabled       bool     `json:"runtime_enabled"`
	DefaultCurrencyCode  string   `json:"default_currency_code"`
	RequiredAdapters     []string `json:"required_adapters"`
	RequireMatrixPass    bool     `json:"require_matrix_pass"`
	RequireFileCount     int      `json:"require_file_count"`
	RequireRowCount      int      `json:"require_row_count"`
	RequirePackageHash   bool     `json:"require_package_hash"`
	RequireNegativeTests bool     `json:"require_negative_tests"`
}

type AdapterTestRequest struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	SuiteID    string `json:"suite_id"`
	PeriodCode string `json:"period_code"`
	FiscalYear int    `json:"fiscal_year"`

	Postings []postingruntime.PostingEntry `json:"postings"`

	RequestedBy string    `json:"requested_by"`
	RequestedAt time.Time `json:"requested_at"`
}

type AdapterResult struct {
	AdapterName string                  `json:"adapter_name"`
	Status      ExportAdapterTestStatus `json:"status"`

	ExportID      string `json:"export_id"`
	FormatVersion string `json:"format_version"`

	FileCount int `json:"file_count"`
	RowCount  int `json:"row_count"`

	Balanced bool `json:"balanced"`

	TotalDebitKurus  int64 `json:"total_debit_kurus"`
	TotalCreditKurus int64 `json:"total_credit_kurus"`

	PackageHash string `json:"package_hash"`

	ErrorCode    string `json:"error_code"`
	ErrorMessage string `json:"error_message"`
}

type NegativeTestResult struct {
	Name    string                  `json:"name"`
	Status  ExportAdapterTestStatus `json:"status"`
	Target  string                  `json:"target"`
	Message string                  `json:"message"`
}

type AdapterSuiteResult struct {
	TenantID       string `json:"tenant_id"`
	CorrelationID  string `json:"correlation_id"`
	RequestID      string `json:"request_id"`
	IdempotencyKey string `json:"idempotency_key"`

	SuiteID    string `json:"suite_id"`
	PeriodCode string `json:"period_code"`
	FiscalYear int    `json:"fiscal_year"`

	Status ExportAdapterTestStatus `json:"status"`

	AdapterResults      []AdapterResult           `json:"adapter_results"`
	MatrixResult        formatmatrix.MatrixResult `json:"matrix_result"`
	NegativeTestResults []NegativeTestResult      `json:"negative_test_results"`

	PassCount int `json:"pass_count"`
	FailCount int `json:"fail_count"`

	ReadyForExportFamilyClosure bool `json:"ready_for_export_family_closure"`

	SuiteHash string `json:"suite_hash"`

	AuditAction         string    `json:"audit_action"`
	AuditDecisionReason string    `json:"audit_decision_reason"`
	ErrorCode           string    `json:"error_code"`
	ErrorMessage        string    `json:"error_message"`
	CreatedAt           time.Time `json:"created_at"`
}

type ExportAdapterTestSuite struct {
	config RuntimeConfig
}

func NewExportAdapterTestSuite(config RuntimeConfig) (*ExportAdapterTestSuite, error) {
	if !config.RuntimeEnabled {
		return nil, errors.New("export adapter test suite is disabled")
	}
	if config.DefaultCurrencyCode == "" {
		return nil, errors.New("default_currency_code is required")
	}
	if len(config.RequiredAdapters) == 0 {
		return nil, errors.New("required_adapters are required")
	}
	if config.RequireFileCount <= 0 {
		return nil, errors.New("require_file_count must be positive")
	}
	if config.RequireRowCount <= 0 {
		return nil, errors.New("require_row_count must be positive")
	}

	return &ExportAdapterTestSuite{config: config}, nil
}

func (s *ExportAdapterTestSuite) RunAll(req AdapterTestRequest) (AdapterSuiteResult, error) {
	if err := s.validateRequest(req); err != nil {
		return rejectedSuite(req, "VALIDATION_FAILED", err.Error()), err
	}

	adapterResults := []AdapterResult{
		s.runETA(req),
		s.runLogo(req),
		s.runMikro(req),
		s.runZirve(req),
	}

	matrixRuntime, err := formatmatrix.NewFormatValidationMatrixRuntime(matrixConfig())
	if err != nil {
		return rejectedSuite(req, "MATRIX_RUNTIME_INIT_FAILED", err.Error()), err
	}

	matrixResult, matrixErr := matrixRuntime.BuildMatrix(formatmatrix.MatrixRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey + ":matrix",
		MatrixID:       req.SuiteID + "-matrix",
		PeriodCode:     req.PeriodCode,
		FiscalYear:     req.FiscalYear,
		Postings:       req.Postings,
		RequestedBy:    req.RequestedBy,
		RequestedAt:    req.RequestedAt,
	})

	negativeResults := s.runNegativeTests(req)

	passCount := 0
	failCount := 0

	for _, result := range adapterResults {
		if result.Status == ExportAdapterTestStatusPass {
			passCount++
		} else {
			failCount++
		}
	}

	if matrixErr == nil && matrixResult.Status == formatmatrix.MatrixStatusReady && matrixResult.ReadyForAdapterTests {
		passCount++
	} else {
		failCount++
	}

	for _, result := range negativeResults {
		if result.Status == ExportAdapterTestStatusPass {
			passCount++
		} else {
			failCount++
		}
	}

	status := ExportAdapterTestStatusPass
	readyForClosure := true
	auditAction := "EXPORT_ADAPTER_TESTS_PASS"
	auditDecisionReason := "ETA, Logo, Mikro, Zirve and format matrix adapter tests passed"

	if failCount > 0 {
		status = ExportAdapterTestStatusFail
		readyForClosure = false
		auditAction = "EXPORT_ADAPTER_TESTS_FAIL"
		auditDecisionReason = "one or more export adapter tests failed"
	}

	result := AdapterSuiteResult{
		TenantID:                    req.TenantID,
		CorrelationID:               req.CorrelationID,
		RequestID:                   req.RequestID,
		IdempotencyKey:              req.IdempotencyKey,
		SuiteID:                     req.SuiteID,
		PeriodCode:                  req.PeriodCode,
		FiscalYear:                  req.FiscalYear,
		Status:                      status,
		AdapterResults:              adapterResults,
		MatrixResult:                matrixResult,
		NegativeTestResults:         negativeResults,
		PassCount:                   passCount,
		FailCount:                   failCount,
		ReadyForExportFamilyClosure: readyForClosure,
		SuiteHash:                   buildSuiteHash(req, adapterResults, matrixResult, negativeResults),
		AuditAction:                 auditAction,
		AuditDecisionReason:         auditDecisionReason,
		CreatedAt:                   time.Now().UTC(),
	}

	if status != ExportAdapterTestStatusPass {
		result.ErrorCode = "EXPORT_ADAPTER_TESTS_FAILED"
		result.ErrorMessage = "export adapter tests failed"
		return result, errors.New("export adapter tests failed")
	}

	return result, nil
}

func (s *ExportAdapterTestSuite) runETA(req AdapterTestRequest) AdapterResult {
	runtime, err := eta.NewETARealFormatRuntime(etaConfig())
	if err != nil {
		return adapterError("ETA", "RUNTIME_INIT_FAILED", err)
	}

	pkg, err := runtime.BuildPackage(eta.ETAExportRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey + ":eta",
		ExportID:       req.SuiteID + "-eta",
		TargetSystem:   eta.TargetSystemETA,
		FormatVersion:  eta.ETAFormatV1,
		PeriodCode:     req.PeriodCode,
		FiscalYear:     req.FiscalYear,
		Postings:       req.Postings,
		RequestedBy:    req.RequestedBy,
		RequestedAt:    req.RequestedAt,
	})

	result := AdapterResult{
		AdapterName:      "ETA",
		ExportID:         pkg.ExportID,
		FormatVersion:    string(pkg.FormatVersion),
		FileCount:        len(pkg.Files),
		RowCount:         len(pkg.JournalRows),
		Balanced:         pkg.Balanced,
		TotalDebitKurus:  pkg.TotalDebitKurus,
		TotalCreditKurus: pkg.TotalCreditKurus,
		PackageHash:      pkg.PackageHash,
	}

	if err != nil {
		result.Status = ExportAdapterTestStatusFail
		result.ErrorCode = pkg.ErrorCode
		result.ErrorMessage = err.Error()
		return result
	}

	if err := s.validateAdapterResult(result); err != nil {
		result.Status = ExportAdapterTestStatusFail
		result.ErrorCode = "ADAPTER_RESULT_INVALID"
		result.ErrorMessage = err.Error()
		return result
	}

	result.Status = ExportAdapterTestStatusPass
	return result
}

func (s *ExportAdapterTestSuite) runLogo(req AdapterTestRequest) AdapterResult {
	runtime, err := logo.NewLogoRealFormatRuntime(logoConfig())
	if err != nil {
		return adapterError("LOGO", "RUNTIME_INIT_FAILED", err)
	}

	pkg, err := runtime.BuildPackage(logo.LogoExportRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey + ":logo",
		ExportID:       req.SuiteID + "-logo",
		TargetSystem:   logo.TargetSystemLogo,
		FormatVersion:  logo.LogoFormatV1,
		PeriodCode:     req.PeriodCode,
		FiscalYear:     req.FiscalYear,
		Postings:       req.Postings,
		RequestedBy:    req.RequestedBy,
		RequestedAt:    req.RequestedAt,
	})

	result := AdapterResult{
		AdapterName:      "LOGO",
		ExportID:         pkg.ExportID,
		FormatVersion:    string(pkg.FormatVersion),
		FileCount:        len(pkg.Files),
		RowCount:         len(pkg.JournalRows),
		Balanced:         pkg.Balanced,
		TotalDebitKurus:  pkg.TotalDebitKurus,
		TotalCreditKurus: pkg.TotalCreditKurus,
		PackageHash:      pkg.PackageHash,
	}

	if err != nil {
		result.Status = ExportAdapterTestStatusFail
		result.ErrorCode = pkg.ErrorCode
		result.ErrorMessage = err.Error()
		return result
	}

	if err := s.validateAdapterResult(result); err != nil {
		result.Status = ExportAdapterTestStatusFail
		result.ErrorCode = "ADAPTER_RESULT_INVALID"
		result.ErrorMessage = err.Error()
		return result
	}

	result.Status = ExportAdapterTestStatusPass
	return result
}

func (s *ExportAdapterTestSuite) runMikro(req AdapterTestRequest) AdapterResult {
	runtime, err := mikro.NewMikroRealFormatRuntime(mikroConfig())
	if err != nil {
		return adapterError("MIKRO", "RUNTIME_INIT_FAILED", err)
	}

	pkg, err := runtime.BuildPackage(mikro.MikroExportRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey + ":mikro",
		ExportID:       req.SuiteID + "-mikro",
		TargetSystem:   mikro.TargetSystemMikro,
		FormatVersion:  mikro.MikroFormatV1,
		PeriodCode:     req.PeriodCode,
		FiscalYear:     req.FiscalYear,
		Postings:       req.Postings,
		RequestedBy:    req.RequestedBy,
		RequestedAt:    req.RequestedAt,
	})

	result := AdapterResult{
		AdapterName:      "MIKRO",
		ExportID:         pkg.ExportID,
		FormatVersion:    string(pkg.FormatVersion),
		FileCount:        len(pkg.Files),
		RowCount:         len(pkg.JournalRows),
		Balanced:         pkg.Balanced,
		TotalDebitKurus:  pkg.TotalDebitKurus,
		TotalCreditKurus: pkg.TotalCreditKurus,
		PackageHash:      pkg.PackageHash,
	}

	if err != nil {
		result.Status = ExportAdapterTestStatusFail
		result.ErrorCode = pkg.ErrorCode
		result.ErrorMessage = err.Error()
		return result
	}

	if err := s.validateAdapterResult(result); err != nil {
		result.Status = ExportAdapterTestStatusFail
		result.ErrorCode = "ADAPTER_RESULT_INVALID"
		result.ErrorMessage = err.Error()
		return result
	}

	result.Status = ExportAdapterTestStatusPass
	return result
}

func (s *ExportAdapterTestSuite) runZirve(req AdapterTestRequest) AdapterResult {
	runtime, err := zirve.NewZirveRealFormatRuntime(zirveConfig())
	if err != nil {
		return adapterError("ZIRVE", "RUNTIME_INIT_FAILED", err)
	}

	pkg, err := runtime.BuildPackage(zirve.ZirveExportRequest{
		TenantID:       req.TenantID,
		CorrelationID:  req.CorrelationID,
		RequestID:      req.RequestID,
		IdempotencyKey: req.IdempotencyKey + ":zirve",
		ExportID:       req.SuiteID + "-zirve",
		TargetSystem:   zirve.TargetSystemZirve,
		FormatVersion:  zirve.ZirveFormatV1,
		PeriodCode:     req.PeriodCode,
		FiscalYear:     req.FiscalYear,
		Postings:       req.Postings,
		RequestedBy:    req.RequestedBy,
		RequestedAt:    req.RequestedAt,
	})

	result := AdapterResult{
		AdapterName:      "ZIRVE",
		ExportID:         pkg.ExportID,
		FormatVersion:    string(pkg.FormatVersion),
		FileCount:        len(pkg.Files),
		RowCount:         len(pkg.JournalRows),
		Balanced:         pkg.Balanced,
		TotalDebitKurus:  pkg.TotalDebitKurus,
		TotalCreditKurus: pkg.TotalCreditKurus,
		PackageHash:      pkg.PackageHash,
	}

	if err != nil {
		result.Status = ExportAdapterTestStatusFail
		result.ErrorCode = pkg.ErrorCode
		result.ErrorMessage = err.Error()
		return result
	}

	if err := s.validateAdapterResult(result); err != nil {
		result.Status = ExportAdapterTestStatusFail
		result.ErrorCode = "ADAPTER_RESULT_INVALID"
		result.ErrorMessage = err.Error()
		return result
	}

	result.Status = ExportAdapterTestStatusPass
	return result
}

func (s *ExportAdapterTestSuite) runNegativeTests(req AdapterTestRequest) []NegativeTestResult {
	results := []NegativeTestResult{
		s.runInvalidAccountPrefixNegative(req),
		s.runTenantMismatchNegative(req),
		s.runMissingPostingHashNegative(req),
	}

	return results
}

func (s *ExportAdapterTestSuite) runInvalidAccountPrefixNegative(req AdapterTestRequest) NegativeTestResult {
	badReq := cloneRequest(req)
	badReq.Postings[0].Lines[0].AccountCode = "999.01"

	matrixRuntime, err := formatmatrix.NewFormatValidationMatrixRuntime(matrixConfig())
	if err != nil {
		return negativeFail("INVALID_ACCOUNT_PREFIX", "MATRIX", err.Error())
	}

	result, err := matrixRuntime.BuildMatrix(formatmatrix.MatrixRequest{
		TenantID:       badReq.TenantID,
		CorrelationID:  badReq.CorrelationID,
		RequestID:      badReq.RequestID,
		IdempotencyKey: badReq.IdempotencyKey + ":negative-account-prefix",
		MatrixID:       badReq.SuiteID + "-negative-account-prefix",
		PeriodCode:     badReq.PeriodCode,
		FiscalYear:     badReq.FiscalYear,
		Postings:       badReq.Postings,
		RequestedBy:    badReq.RequestedBy,
		RequestedAt:    badReq.RequestedAt,
	})

	if err == nil {
		return negativeFail("INVALID_ACCOUNT_PREFIX", "MATRIX", "expected matrix failure")
	}
	if result.Status != formatmatrix.MatrixStatusRejected {
		return negativeFail("INVALID_ACCOUNT_PREFIX", "MATRIX", "expected rejected matrix")
	}
	if result.FailCount != 4 {
		return negativeFail("INVALID_ACCOUNT_PREFIX", "MATRIX", fmt.Sprintf("expected 4 failed targets, got %d", result.FailCount))
	}

	return NegativeTestResult{Name: "INVALID_ACCOUNT_PREFIX", Target: "MATRIX", Status: ExportAdapterTestStatusPass, Message: "invalid account prefix rejected across all adapters"}
}

func (s *ExportAdapterTestSuite) runTenantMismatchNegative(req AdapterTestRequest) NegativeTestResult {
	badReq := cloneRequest(req)
	badReq.Postings[0].TenantID = "tenant-other"

	matrixRuntime, err := formatmatrix.NewFormatValidationMatrixRuntime(matrixConfig())
	if err != nil {
		return negativeFail("TENANT_MISMATCH", "MATRIX", err.Error())
	}

	result, err := matrixRuntime.BuildMatrix(formatmatrix.MatrixRequest{
		TenantID:       badReq.TenantID,
		CorrelationID:  badReq.CorrelationID,
		RequestID:      badReq.RequestID,
		IdempotencyKey: badReq.IdempotencyKey + ":negative-tenant",
		MatrixID:       badReq.SuiteID + "-negative-tenant",
		PeriodCode:     badReq.PeriodCode,
		FiscalYear:     badReq.FiscalYear,
		Postings:       badReq.Postings,
		RequestedBy:    badReq.RequestedBy,
		RequestedAt:    badReq.RequestedAt,
	})

	if err == nil {
		return negativeFail("TENANT_MISMATCH", "MATRIX", "expected matrix failure")
	}
	if result.Status != formatmatrix.MatrixStatusRejected {
		return negativeFail("TENANT_MISMATCH", "MATRIX", "expected rejected matrix")
	}
	if result.FailCount != 4 {
		return negativeFail("TENANT_MISMATCH", "MATRIX", fmt.Sprintf("expected 4 failed targets, got %d", result.FailCount))
	}

	return NegativeTestResult{Name: "TENANT_MISMATCH", Target: "MATRIX", Status: ExportAdapterTestStatusPass, Message: "tenant mismatch rejected across all adapters"}
}

func (s *ExportAdapterTestSuite) runMissingPostingHashNegative(req AdapterTestRequest) NegativeTestResult {
	badReq := cloneRequest(req)
	badReq.Postings[0].PostingHash = ""

	matrixRuntime, err := formatmatrix.NewFormatValidationMatrixRuntime(matrixConfig())
	if err != nil {
		return negativeFail("MISSING_POSTING_HASH", "MATRIX", err.Error())
	}

	result, err := matrixRuntime.BuildMatrix(formatmatrix.MatrixRequest{
		TenantID:       badReq.TenantID,
		CorrelationID:  badReq.CorrelationID,
		RequestID:      badReq.RequestID,
		IdempotencyKey: badReq.IdempotencyKey + ":negative-hash",
		MatrixID:       badReq.SuiteID + "-negative-hash",
		PeriodCode:     badReq.PeriodCode,
		FiscalYear:     badReq.FiscalYear,
		Postings:       badReq.Postings,
		RequestedBy:    badReq.RequestedBy,
		RequestedAt:    badReq.RequestedAt,
	})

	if err == nil {
		return negativeFail("MISSING_POSTING_HASH", "MATRIX", "expected matrix failure")
	}
	if result.Status != formatmatrix.MatrixStatusRejected {
		return negativeFail("MISSING_POSTING_HASH", "MATRIX", "expected rejected matrix")
	}
	if result.FailCount != 4 {
		return negativeFail("MISSING_POSTING_HASH", "MATRIX", fmt.Sprintf("expected 4 failed targets, got %d", result.FailCount))
	}

	return NegativeTestResult{Name: "MISSING_POSTING_HASH", Target: "MATRIX", Status: ExportAdapterTestStatusPass, Message: "missing posting hash rejected across all adapters"}
}

func (s *ExportAdapterTestSuite) validateRequest(req AdapterTestRequest) error {
	if req.TenantID == "" {
		return errors.New("tenant_id is required")
	}
	if req.CorrelationID == "" {
		return errors.New("correlation_id is required")
	}
	if req.RequestID == "" {
		return errors.New("request_id is required")
	}
	if req.IdempotencyKey == "" {
		return errors.New("idempotency_key is required")
	}
	if req.SuiteID == "" {
		return errors.New("suite_id is required")
	}
	if req.PeriodCode == "" {
		return errors.New("period_code is required")
	}
	if req.FiscalYear <= 2000 {
		return errors.New("fiscal_year is invalid")
	}
	if len(req.Postings) == 0 {
		return errors.New("postings are required")
	}
	if req.RequestedBy == "" {
		return errors.New("requested_by is required")
	}
	if req.RequestedAt.IsZero() {
		return errors.New("requested_at is required")
	}
	return nil
}

func (s *ExportAdapterTestSuite) validateAdapterResult(result AdapterResult) error {
	if result.FileCount < s.config.RequireFileCount {
		return errors.New("adapter file count below required minimum")
	}
	if result.RowCount < s.config.RequireRowCount {
		return errors.New("adapter row count below required minimum")
	}
	if !result.Balanced {
		return errors.New("adapter package must be balanced")
	}
	if result.TotalDebitKurus != result.TotalCreditKurus {
		return errors.New("adapter debit and credit totals must match")
	}
	if s.config.RequirePackageHash && result.PackageHash == "" {
		return errors.New("adapter package hash is required")
	}
	return nil
}

func adapterError(adapter string, code string, err error) AdapterResult {
	return AdapterResult{
		AdapterName:  adapter,
		Status:       ExportAdapterTestStatusFail,
		ErrorCode:    code,
		ErrorMessage: err.Error(),
	}
}

func negativeFail(name string, target string, message string) NegativeTestResult {
	return NegativeTestResult{Name: name, Target: target, Status: ExportAdapterTestStatusFail, Message: message}
}

func rejectedSuite(req AdapterTestRequest, code string, message string) AdapterSuiteResult {
	return AdapterSuiteResult{
		TenantID:                    req.TenantID,
		CorrelationID:               req.CorrelationID,
		RequestID:                   req.RequestID,
		IdempotencyKey:              req.IdempotencyKey,
		SuiteID:                     req.SuiteID,
		PeriodCode:                  req.PeriodCode,
		FiscalYear:                  req.FiscalYear,
		Status:                      ExportAdapterTestStatusFail,
		ReadyForExportFamilyClosure: false,
		AuditAction:                 "EXPORT_ADAPTER_TESTS_REJECTED",
		AuditDecisionReason:         "export adapter test suite rejected by validation guard",
		ErrorCode:                   code,
		ErrorMessage:                message,
		CreatedAt:                   time.Now().UTC(),
	}
}

func cloneRequest(req AdapterTestRequest) AdapterTestRequest {
	cloned := req
	cloned.Postings = append([]postingruntime.PostingEntry(nil), req.Postings...)

	for i := range cloned.Postings {
		cloned.Postings[i].Lines = append([]postingruntime.PostingLine(nil), req.Postings[i].Lines...)
	}

	return cloned
}

func buildSuiteHash(req AdapterTestRequest, adapters []AdapterResult, matrix formatmatrix.MatrixResult, negatives []NegativeTestResult) string {
	parts := []string{req.TenantID, req.SuiteID, req.PeriodCode, matrix.MatrixHash}

	for _, adapter := range adapters {
		parts = append(parts, adapter.AdapterName, string(adapter.Status), adapter.PackageHash)
	}
	for _, negative := range negatives {
		parts = append(parts, negative.Name, string(negative.Status))
	}

	return "export-adapter-suite:" + joinParts(parts)
}

func joinParts(parts []string) string {
	out := ""
	for i, part := range parts {
		if i > 0 {
			out += ":"
		}
		out += part
	}
	return out
}

func etaConfig() eta.RuntimeConfig {
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

func logoConfig() logo.RuntimeConfig {
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

func mikroConfig() mikro.RuntimeConfig {
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

func zirveConfig() zirve.RuntimeConfig {
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

func matrixConfig() formatmatrix.RuntimeConfig {
	return formatmatrix.RuntimeConfig{
		RuntimeEnabled:        true,
		DefaultCurrencyCode:   "TRY",
		RequireAllTargets:     true,
		RequireBalanced:       true,
		RequirePackageHash:    true,
		RequireFiles:          true,
		RequireRows:           true,
		FailOnProviderIssue:   true,
		RequiredTargets:       []formatmatrix.TargetSystem{formatmatrix.TargetETA, formatmatrix.TargetLogo, formatmatrix.TargetMikro, formatmatrix.TargetZirve},
		RequiredFileMinimum:   3,
		RequiredRowMinimum:    3,
		RequiredAccountPrefix: []string{"120", "191", "320", "391", "600", "610", "102", "153", "500"},
	}
}
