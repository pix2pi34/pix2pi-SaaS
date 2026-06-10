package exportruntime

import (
	"strings"
	"testing"
	"time"

	companypermission "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/accountantportal/companypermission"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:            true,
		DefaultCurrencyCode:       "TRY",
		RequirePermissionDecision: true,
		RequireTenantScope:        true,
		RequireCompanyScope:       true,
		RequireLedgerRows:         true,
		RequireBalancedExport:     true,
		RequireExportHash:         true,
		RequireAuditSubject:       true,
		MaxRows:                   100,
		AllowedFormats:            []ExportFormat{ExportFormatExcel, ExportFormatPDF, ExportFormatTDHP},
	}
}

func validNow() time.Time {
	return time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)
}

func validGrant() companypermission.CompanyPermissionGrant {
	now := validNow()
	return companypermission.CompanyPermissionGrant{
		GrantID:            "grant-001",
		TenantID:           "tenant-accountant-001",
		AccountantFirmID:   "acc-firm-001",
		AccountantUserID:   "acc-user-001",
		AssignmentID:       "assign-001",
		TargetFirmTenantID: "tenant-firm-001",
		TargetCompanyID:    "company-001",
		Role:               companypermission.PortalRoleStaff,
		Permissions: []companypermission.Permission{
			companypermission.PermissionViewFirm,
			companypermission.PermissionViewLedger,
			companypermission.PermissionExportExcel,
			companypermission.PermissionExportPDF,
			companypermission.PermissionExportTDHP,
		},
		ResourceTypes: []companypermission.ResourceType{
			companypermission.ResourceTypeFirm,
			companypermission.ResourceTypeLedger,
			companypermission.ResourceTypeExport,
		},
		Active:     true,
		ValidFrom:  now.Add(-24 * time.Hour),
		ValidUntil: now.Add(30 * 24 * time.Hour),
		GrantedBy:  "acc-owner-001",
		GrantedAt:  now.Add(-24 * time.Hour),
	}
}

func validRows() []LedgerExportRow {
	now := validNow()
	return []LedgerExportRow{
		{
			TenantID:           "tenant-accountant-001",
			TargetFirmTenantID: "tenant-firm-001",
			TargetCompanyID:    "company-001",
			PeriodCode:         "2026-05",
			DocumentNo:         "INV-001",
			DocumentDate:       now,
			AccountCode:        "120.01",
			AccountName:        "Alıcılar",
			DebitKurus:         1200000,
			CreditKurus:        0,
			CurrencyCode:       "TRY",
			Description:        "Alıcı borç kaydı",
			PostingHash:        "posting:001",
			AuditTraceID:       "audit:001",
		},
		{
			TenantID:           "tenant-accountant-001",
			TargetFirmTenantID: "tenant-firm-001",
			TargetCompanyID:    "company-001",
			PeriodCode:         "2026-05",
			DocumentNo:         "INV-001",
			DocumentDate:       now,
			AccountCode:        "600.01",
			AccountName:        "Yurt içi satışlar",
			DebitKurus:         0,
			CreditKurus:        1000000,
			CurrencyCode:       "TRY",
			Description:        "Satış geliri",
			PostingHash:        "posting:002",
			AuditTraceID:       "audit:002",
		},
		{
			TenantID:           "tenant-accountant-001",
			TargetFirmTenantID: "tenant-firm-001",
			TargetCompanyID:    "company-001",
			PeriodCode:         "2026-05",
			DocumentNo:         "INV-001",
			DocumentDate:       now,
			AccountCode:        "391.01.20",
			AccountName:        "Hesaplanan KDV",
			DebitKurus:         0,
			CreditKurus:        200000,
			CurrencyCode:       "TRY",
			Description:        "KDV",
			PostingHash:        "posting:003",
			AuditTraceID:       "audit:003",
		},
	}
}

func validRequest(format ExportFormat) PortalExportRequest {
	return PortalExportRequest{
		TenantID:           "tenant-accountant-001",
		CorrelationID:      "corr-export-001",
		RequestID:          "req-export-001",
		IdempotencyKey:     "idem-export-001",
		ExportID:           "portal-export-001",
		Format:             format,
		AccountantFirmID:   "acc-firm-001",
		AccountantUserID:   "acc-user-001",
		AssignmentID:       "assign-001",
		TargetFirmTenantID: "tenant-firm-001",
		TargetCompanyID:    "company-001",
		TargetCompanyName:  "Pilot Market A.Ş.",
		PeriodCode:         "2026-05",
		FiscalYear:         2026,
		PermissionGrant:    validGrant(),
		LedgerRows:         validRows(),
		RequestedBy:        "portal-export-test",
		RequestedAt:        validNow(),
	}
}

func newRuntime(t *testing.T) *ExcelPDFTDHPExportRuntime {
	t.Helper()

	runtime, err := NewExcelPDFTDHPExportRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func TestExportExcelAllowed(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Export(validRequest(ExportFormatExcel))
	if err != nil {
		t.Fatalf("expected Excel export allowed, got error: %v", err)
	}
	if result.Status != ExportStatusReady {
		t.Fatalf("expected READY, got %s", result.Status)
	}
	if result.File.Format != ExportFormatExcel {
		t.Fatalf("expected Excel file, got %s", result.File.Format)
	}
	if !strings.Contains(result.File.Content, "TARIH;BELGE_NO;HESAP_KODU") {
		t.Fatal("expected Excel CSV header")
	}
	if result.ExportHash == "" {
		t.Fatal("expected export hash")
	}
}

func TestExportPDFAllowed(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Export(validRequest(ExportFormatPDF))
	if err != nil {
		t.Fatalf("expected PDF export allowed, got error: %v", err)
	}
	if result.File.Format != ExportFormatPDF {
		t.Fatalf("expected PDF file, got %s", result.File.Format)
	}
	if !strings.Contains(result.File.Content, "PDF_SIMULATION") {
		t.Fatal("expected PDF simulation content")
	}
}

func TestExportTDHPAllowed(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.Export(validRequest(ExportFormatTDHP))
	if err != nil {
		t.Fatalf("expected TDHP export allowed, got error: %v", err)
	}
	if result.File.Format != ExportFormatTDHP {
		t.Fatalf("expected TDHP file, got %s", result.File.Format)
	}
	if !strings.Contains(result.File.Content, "TDHP|TARIH|BELGE_NO|HESAP") {
		t.Fatal("expected TDHP content header")
	}
}

func TestExportBundleAllFormatsAllowed(t *testing.T) {
	runtime := newRuntime(t)

	base := validRequest(ExportFormatExcel)
	result, err := runtime.ExportBundle(ExportBundleRequest{
		TenantID:       base.TenantID,
		CorrelationID:  "corr-bundle-001",
		RequestID:      "req-bundle-001",
		IdempotencyKey: "idem-bundle-001",
		BundleID:       "bundle-001",
		Formats:        []ExportFormat{ExportFormatTDHP, ExportFormatExcel, ExportFormatPDF},
		BaseRequest:    base,
		RequestedAt:    validNow(),
	})
	if err != nil {
		t.Fatalf("expected bundle allowed, got error: %v", err)
	}
	if result.Status != ExportStatusReady {
		t.Fatalf("expected READY, got %s", result.Status)
	}
	if result.PassCount != 3 {
		t.Fatalf("expected pass count 3, got %d", result.PassCount)
	}
	if result.FailCount != 0 {
		t.Fatalf("expected fail count 0, got %d", result.FailCount)
	}
	if result.BundleHash == "" {
		t.Fatal("expected bundle hash")
	}
	if result.Exports[0].Format != ExportFormatExcel {
		t.Fatalf("expected sorted Excel first, got %s", result.Exports[0].Format)
	}
}

func TestExportRejectsPermissionDenied(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest(ExportFormatPDF)
	req.PermissionGrant.Permissions = []companypermission.Permission{companypermission.PermissionViewFirm}
	req.PermissionGrant.ResourceTypes = []companypermission.ResourceType{companypermission.ResourceTypeFirm}

	result, err := runtime.Export(req)
	if err == nil {
		t.Fatal("expected permission denied")
	}
	if result.Status != ExportStatusRejected {
		t.Fatalf("expected REJECTED, got %s", result.Status)
	}
	if result.ErrorCode != "PERMISSION_DENIED" {
		t.Fatalf("expected PERMISSION_DENIED, got %s", result.ErrorCode)
	}
}

func TestExportRejectsCompanyMismatchGrant(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest(ExportFormatTDHP)
	req.PermissionGrant.TargetCompanyID = "company-other"

	result, err := runtime.Export(req)
	if err == nil {
		t.Fatal("expected company mismatch")
	}
	if result.ErrorCode != "PERMISSION_DENIED" {
		t.Fatalf("expected PERMISSION_DENIED, got %s", result.ErrorCode)
	}
}

func TestExportRejectsUnbalancedRows(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest(ExportFormatExcel)
	req.LedgerRows[1].CreditKurus = 900000

	result, err := runtime.Export(req)
	if err == nil {
		t.Fatal("expected unbalanced export error")
	}
	if result.ErrorCode != "EXPORT_NOT_BALANCED" {
		t.Fatalf("expected EXPORT_NOT_BALANCED, got %s", result.ErrorCode)
	}
}

func TestExportRejectsTenantMismatchRow(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest(ExportFormatExcel)
	req.LedgerRows[0].TenantID = "tenant-other"

	result, err := runtime.Export(req)
	if err == nil {
		t.Fatal("expected row tenant mismatch")
	}
	if result.ErrorCode != "LEDGER_ROWS_INVALID" {
		t.Fatalf("expected LEDGER_ROWS_INVALID, got %s", result.ErrorCode)
	}
}

func TestExportRejectsUnsupportedFormat(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest(ExportFormat("XML"))

	result, err := runtime.Export(req)
	if err == nil {
		t.Fatal("expected unsupported format error")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestExportRejectsTooManyRows(t *testing.T) {
	cfg := validConfig()
	cfg.MaxRows = 1

	runtime, err := NewExcelPDFTDHPExportRuntime(cfg)
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}

	result, err := runtime.Export(validRequest(ExportFormatExcel))
	if err == nil {
		t.Fatal("expected too many rows error")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewExcelPDFTDHPExportRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsMissingFormatsConfig(t *testing.T) {
	cfg := validConfig()
	cfg.AllowedFormats = nil

	_, err := NewExcelPDFTDHPExportRuntime(cfg)
	if err == nil {
		t.Fatal("expected missing formats error")
	}
}
