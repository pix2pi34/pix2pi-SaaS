package eta

import (
	"strings"
	"testing"
	"time"

	postingruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/postingruntime"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:          true,
		TargetSystem:            TargetSystemETA,
		FormatVersion:           ETAFormatV1,
		DefaultCurrencyCode:     "TRY",
		Delimiter:               "|",
		LineEnding:              "\n",
		StrictBalanceRequired:   true,
		RequirePostingHash:      true,
		RequireAuditTrace:       true,
		RequireTenantScope:      true,
		NormalizeTurkishChars:   true,
		MaxDescriptionLength:    120,
		AllowedFileTypes:        []ETAFileType{FileTypeJournal, FileTypeLedger, FileTypeSummary},
		RequiredAccountPrefixes: []string{"120", "191", "320", "391", "600", "610", "102", "153", "500"},
	}
}

func validRequest() ETAExportRequest {
	return ETAExportRequest{
		TenantID:       "tenant-001",
		CorrelationID:  "corr-export-001",
		RequestID:      "req-export-001",
		IdempotencyKey: "idem-export-001",
		ExportID:       "eta-export-001",
		TargetSystem:   TargetSystemETA,
		FormatVersion:  ETAFormatV1,
		PeriodCode:     "2026-05",
		FiscalYear:     2026,
		Postings:       []postingruntime.PostingEntry{validPosting()},
		RequestedBy:    "export-test",
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

func newRuntime(t *testing.T) *ETARealFormatRuntime {
	t.Helper()

	runtime, err := NewETARealFormatRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func TestBuildETAPackageReady(t *testing.T) {
	runtime := newRuntime(t)

	pkg, err := runtime.BuildPackage(validRequest())
	if err != nil {
		t.Fatalf("build ETA package failed: %v", err)
	}

	if pkg.Status != ExportStatusReady {
		t.Fatalf("expected READY, got %s", pkg.Status)
	}
	if !pkg.Balanced {
		t.Fatal("expected balanced package")
	}
	if len(pkg.JournalRows) != 3 {
		t.Fatalf("expected 3 journal rows, got %d", len(pkg.JournalRows))
	}
	if len(pkg.Files) != 3 {
		t.Fatalf("expected 3 files, got %d", len(pkg.Files))
	}
	if pkg.PackageHash == "" {
		t.Fatal("expected package hash")
	}
}

func TestETAJournalFileContainsExpectedRows(t *testing.T) {
	runtime := newRuntime(t)

	pkg, err := runtime.BuildPackage(validRequest())
	if err != nil {
		t.Fatalf("build ETA package failed: %v", err)
	}

	journal := pkg.Files[0].Content
	if !strings.Contains(journal, "TARIH|FISNO|SATIR|HESAPKODU") {
		t.Fatal("expected journal header")
	}
	if !strings.Contains(journal, "120.01") {
		t.Fatal("expected 120.01 account")
	}
	if !strings.Contains(journal, "600.01") {
		t.Fatal("expected 600.01 account")
	}
	if !strings.Contains(journal, "391.01.20") {
		t.Fatal("expected 391.01.20 account")
	}
	if !strings.Contains(journal, "12000.00") {
		t.Fatal("expected debit amount 12000.00")
	}
}

func TestETALedgerAndSummaryFilesGenerated(t *testing.T) {
	runtime := newRuntime(t)

	pkg, err := runtime.BuildPackage(validRequest())
	if err != nil {
		t.Fatalf("build ETA package failed: %v", err)
	}

	var ledgerFound bool
	var summaryFound bool

	for _, file := range pkg.Files {
		if file.FileType == FileTypeLedger {
			ledgerFound = true
			if !strings.Contains(file.Content, "HESAPKODU|HESAPADI|BORC|ALACAK|PARA") {
				t.Fatal("expected ledger header")
			}
		}
		if file.FileType == FileTypeSummary {
			summaryFound = true
			if !strings.Contains(file.Content, "BALANCED|true") {
				t.Fatal("expected balanced summary")
			}
		}
	}

	if !ledgerFound {
		t.Fatal("expected ledger file")
	}
	if !summaryFound {
		t.Fatal("expected summary file")
	}
}

func TestValidatePackageRejectsInvalidAccountPrefix(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Postings[0].Lines[0].AccountCode = "999.01"

	pkg, err := runtime.BuildPackage(req)
	if err == nil {
		t.Fatal("expected validation issue error")
	}
	if pkg.Status != ExportStatusRejected {
		t.Fatalf("expected REJECTED, got %s", pkg.Status)
	}
	if len(pkg.Issues) == 0 {
		t.Fatal("expected validation issues")
	}
}

func TestBuildPackageRejectsTenantMismatch(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Postings[0].TenantID = "tenant-002"

	pkg, err := runtime.BuildPackage(req)
	if err == nil {
		t.Fatal("expected tenant mismatch error")
	}
	if pkg.ErrorCode != "ROW_BUILD_FAILED" {
		t.Fatalf("expected ROW_BUILD_FAILED, got %s", pkg.ErrorCode)
	}
}

func TestBuildPackageRejectsUnbalancedPosting(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Postings[0].Balanced = false

	pkg, err := runtime.BuildPackage(req)
	if err == nil {
		t.Fatal("expected unbalanced posting error")
	}
	if pkg.ErrorCode != "ROW_BUILD_FAILED" {
		t.Fatalf("expected ROW_BUILD_FAILED, got %s", pkg.ErrorCode)
	}
}

func TestBuildPackageRejectsMissingPostingHash(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Postings[0].PostingHash = ""

	pkg, err := runtime.BuildPackage(req)
	if err == nil {
		t.Fatal("expected missing posting hash error")
	}
	if pkg.ErrorCode != "ROW_BUILD_FAILED" {
		t.Fatalf("expected ROW_BUILD_FAILED, got %s", pkg.ErrorCode)
	}
}

func TestNormalizeTurkishCharacters(t *testing.T) {
	got := normalizeETAField("Çalışma Şirketi İğdır Ürün", true, 100)
	if strings.ContainsAny(got, "ÇçŞşĞğÜüÖöİı") {
		t.Fatalf("expected normalized ASCII, got %s", got)
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewETARealFormatRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}
