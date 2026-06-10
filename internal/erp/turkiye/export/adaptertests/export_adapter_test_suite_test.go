package adaptertests

import (
	"testing"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/export/formatmatrix"
	postingruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/postingruntime"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:       true,
		DefaultCurrencyCode:  "TRY",
		RequiredAdapters:     []string{"ETA", "LOGO", "MIKRO", "ZIRVE"},
		RequireMatrixPass:    true,
		RequireFileCount:     3,
		RequireRowCount:      3,
		RequirePackageHash:   true,
		RequireNegativeTests: true,
	}
}

func validRequest() AdapterTestRequest {
	return AdapterTestRequest{
		TenantID:       "tenant-001",
		CorrelationID:  "corr-export-adapter-tests-001",
		RequestID:      "req-export-adapter-tests-001",
		IdempotencyKey: "idem-export-adapter-tests-001",
		SuiteID:        "export-adapter-suite-001",
		PeriodCode:     "2026-05",
		FiscalYear:     2026,
		Postings:       []postingruntime.PostingEntry{validPosting()},
		RequestedBy:    "export-adapter-test-suite",
		RequestedAt:    time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC),
	}
}

func validPosting() postingruntime.PostingEntry {
	now := time.Date(2026, 5, 7, 12, 0, 0, 0, time.UTC)

	return postingruntime.PostingEntry{
		TenantID:       "tenant-001",
		CorrelationID:  "corr-posting-001",
		RequestID:      "req-posting-001",
		IdempotencyKey: "idem-posting-001",
		PostingID:      "posting-001",
		PostingNo:      "POST-TDHP-INV-001",
		PostingSource:  postingruntime.SourceVoucherPipeline,
		Status:         postingruntime.PostingStatusPosted,
		VoucherID:      "voucher-001",
		VoucherNo:      "TDHP-INV-001",
		DocumentType:   "SALES_INVOICE",
		DocumentID:     "invoice-001",
		DocumentNo:     "INV-001",
		DocumentDate:   now,
		CurrencyCode:   "TRY",
		Lines: []postingruntime.PostingLine{
			{
				PostingLineID:     "posting-001:1",
				LineNo:            1,
				AccountCode:       "120.01",
				AccountName:       "Alıcılar",
				DebitAmountKurus:  1200000,
				CreditAmountKurus: 0,
				DocumentID:        "invoice-001",
				DocumentNo:        "INV-001",
				PartyID:           "party-001",
				PartyTaxNo:        "1234567890",
				Description:       "Alıcı borç kaydı",
			},
			{
				PostingLineID:     "posting-001:2",
				LineNo:            2,
				AccountCode:       "600.01",
				AccountName:       "Yurt içi satışlar",
				DebitAmountKurus:  0,
				CreditAmountKurus: 1000000,
				DocumentID:        "invoice-001",
				DocumentNo:        "INV-001",
				PartyID:           "party-001",
				PartyTaxNo:        "1234567890",
				Description:       "Satış geliri",
			},
			{
				PostingLineID:     "posting-001:3",
				LineNo:            3,
				AccountCode:       "391.01.20",
				AccountName:       "Hesaplanan KDV",
				DebitAmountKurus:  0,
				CreditAmountKurus: 200000,
				DocumentID:        "invoice-001",
				DocumentNo:        "INV-001",
				PartyID:           "party-001",
				PartyTaxNo:        "1234567890",
				TaxTraceCode:      "OUTPUT_KDV",
				Description:       "Hesaplanan KDV",
			},
		},
		TotalDebitKurus:     1200000,
		TotalCreditKurus:    1200000,
		Balanced:            true,
		PostingReady:        true,
		LedgerReady:         true,
		AuditTraceID:        "posting-audit:tenant-001:posting-001",
		PostingHash:         "posting:tenant-001:posting-001:1200000:1200000:3",
		AuditAction:         "DOCUMENT_BASED_POSTING_POSTED",
		AuditDecisionReason: "voucher posted to append-only ledger repository",
		PostedBy:            "posting-runtime-test",
		PostedAt:            now,
		CreatedAt:           now,
	}
}

func newSuite(t *testing.T) *ExportAdapterTestSuite {
	t.Helper()

	suite, err := NewExportAdapterTestSuite(validConfig())
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}
	return suite
}

func TestExportAdapterSuiteAllProvidersPass(t *testing.T) {
	suite := newSuite(t)

	result, err := suite.RunAll(validRequest())
	if err != nil {
		t.Fatalf("export adapter suite failed: %v", err)
	}

	if result.Status != ExportAdapterTestStatusPass {
		t.Fatalf("expected PASS, got %s", result.Status)
	}
	if !result.ReadyForExportFamilyClosure {
		t.Fatal("expected ready for export family closure")
	}
	if len(result.AdapterResults) != 4 {
		t.Fatalf("expected 4 adapter results, got %d", len(result.AdapterResults))
	}
	if result.MatrixResult.Status != formatmatrix.MatrixStatusReady {
		t.Fatalf("expected matrix ready, got %s", result.MatrixResult.Status)
	}
	if result.PassCount != 8 {
		t.Fatalf("expected pass count 8, got %d", result.PassCount)
	}
	if result.FailCount != 0 {
		t.Fatalf("expected fail count 0, got %d", result.FailCount)
	}
	if result.SuiteHash == "" {
		t.Fatal("expected suite hash")
	}
}

func TestExportAdapterSuiteAdapterOutputsHaveFilesRowsAndHashes(t *testing.T) {
	suite := newSuite(t)

	result, err := suite.RunAll(validRequest())
	if err != nil {
		t.Fatalf("export adapter suite failed: %v", err)
	}

	for _, adapter := range result.AdapterResults {
		if adapter.FileCount != 3 {
			t.Fatalf("%s expected 3 files, got %d", adapter.AdapterName, adapter.FileCount)
		}
		if adapter.RowCount != 3 {
			t.Fatalf("%s expected 3 rows, got %d", adapter.AdapterName, adapter.RowCount)
		}
		if adapter.PackageHash == "" {
			t.Fatalf("%s expected package hash", adapter.AdapterName)
		}
		if !adapter.Balanced {
			t.Fatalf("%s expected balanced package", adapter.AdapterName)
		}
		if adapter.TotalDebitKurus != adapter.TotalCreditKurus {
			t.Fatalf("%s expected debit/credit total match", adapter.AdapterName)
		}
	}
}

func TestExportAdapterSuiteNegativeTestsPass(t *testing.T) {
	suite := newSuite(t)

	result, err := suite.RunAll(validRequest())
	if err != nil {
		t.Fatalf("export adapter suite failed: %v", err)
	}

	if len(result.NegativeTestResults) != 3 {
		t.Fatalf("expected 3 negative tests, got %d", len(result.NegativeTestResults))
	}

	for _, item := range result.NegativeTestResults {
		if item.Status != ExportAdapterTestStatusPass {
			t.Fatalf("negative test %s expected PASS, got %s: %s", item.Name, item.Status, item.Message)
		}
	}
}

func TestExportAdapterSuiteRejectsInvalidAccountPrefix(t *testing.T) {
	suite := newSuite(t)
	req := validRequest()
	req.Postings[0].Lines[0].AccountCode = "999.01"

	result, err := suite.RunAll(req)
	if err == nil {
		t.Fatal("expected suite failure")
	}
	if result.Status != ExportAdapterTestStatusFail {
		t.Fatalf("expected FAIL, got %s", result.Status)
	}
	if result.ReadyForExportFamilyClosure {
		t.Fatal("expected not ready for closure")
	}
}

func TestExportAdapterSuiteRejectsTenantMismatch(t *testing.T) {
	suite := newSuite(t)
	req := validRequest()
	req.Postings[0].TenantID = "tenant-other"

	result, err := suite.RunAll(req)
	if err == nil {
		t.Fatal("expected suite failure")
	}
	if result.Status != ExportAdapterTestStatusFail {
		t.Fatalf("expected FAIL, got %s", result.Status)
	}
}

func TestExportAdapterSuiteRejectsMissingPostingHash(t *testing.T) {
	suite := newSuite(t)
	req := validRequest()
	req.Postings[0].PostingHash = ""

	result, err := suite.RunAll(req)
	if err == nil {
		t.Fatal("expected suite failure")
	}
	if result.Status != ExportAdapterTestStatusFail {
		t.Fatalf("expected FAIL, got %s", result.Status)
	}
}

func TestExportAdapterSuiteRejectsMissingPostings(t *testing.T) {
	suite := newSuite(t)
	req := validRequest()
	req.Postings = nil

	result, err := suite.RunAll(req)
	if err == nil {
		t.Fatal("expected missing postings error")
	}
	if result.ErrorCode != "VALIDATION_FAILED" {
		t.Fatalf("expected VALIDATION_FAILED, got %s", result.ErrorCode)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewExportAdapterTestSuite(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}

func TestRuntimeRejectsMissingAdaptersConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RequiredAdapters = nil

	_, err := NewExportAdapterTestSuite(cfg)
	if err == nil {
		t.Fatal("expected missing adapters error")
	}
}
