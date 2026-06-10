package formatmatrix

import (
	"testing"
	"time"

	postingruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/postingruntime"
)

func validConfig() RuntimeConfig {
	return RuntimeConfig{
		RuntimeEnabled:        true,
		DefaultCurrencyCode:   "TRY",
		RequireAllTargets:     true,
		RequireBalanced:       true,
		RequirePackageHash:    true,
		RequireFiles:          true,
		RequireRows:           true,
		FailOnProviderIssue:   true,
		RequiredTargets:       []TargetSystem{TargetETA, TargetLogo, TargetMikro, TargetZirve},
		RequiredFileMinimum:   3,
		RequiredRowMinimum:    3,
		RequiredAccountPrefix: []string{"120", "191", "320", "391", "600", "610", "102", "153", "500"},
	}
}

func validRequest() MatrixRequest {
	return MatrixRequest{
		TenantID:       "tenant-001",
		CorrelationID:  "corr-matrix-001",
		RequestID:      "req-matrix-001",
		IdempotencyKey: "idem-matrix-001",
		MatrixID:       "format-matrix-001",
		PeriodCode:     "2026-05",
		FiscalYear:     2026,
		Postings:       []postingruntime.PostingEntry{validPosting()},
		RequestedBy:    "format-matrix-test",
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

func newRuntime(t *testing.T) *FormatValidationMatrixRuntime {
	t.Helper()

	runtime, err := NewFormatValidationMatrixRuntime(validConfig())
	if err != nil {
		t.Fatalf("runtime init failed: %v", err)
	}
	return runtime
}

func TestBuildMatrixAllTargetsReady(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.BuildMatrix(validRequest())
	if err != nil {
		t.Fatalf("build matrix failed: %v", err)
	}

	if result.Status != MatrixStatusReady {
		t.Fatalf("expected READY, got %s", result.Status)
	}
	if !result.ReadyForAdapterTests {
		t.Fatal("expected ready for adapter tests")
	}
	if result.PassCount != 4 {
		t.Fatalf("expected 4 pass count, got %d", result.PassCount)
	}
	if result.FailCount != 0 {
		t.Fatalf("expected 0 fail count, got %d", result.FailCount)
	}
	if len(result.TargetResults) != 4 {
		t.Fatalf("expected 4 target results, got %d", len(result.TargetResults))
	}
	if result.MatrixHash == "" {
		t.Fatal("expected matrix hash")
	}
}

func TestBuildMatrixValidatesTargetOrder(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.BuildMatrix(validRequest())
	if err != nil {
		t.Fatalf("build matrix failed: %v", err)
	}

	expected := []TargetSystem{TargetETA, TargetLogo, TargetMikro, TargetZirve}
	for i, target := range expected {
		if result.TargetResults[i].TargetSystem != target {
			t.Fatalf("expected target %s at index %d, got %s", target, i, result.TargetResults[i].TargetSystem)
		}
	}
}

func TestBuildMatrixRejectsInvalidAccountPrefixAcrossProviders(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Postings[0].Lines[0].AccountCode = "999.01"

	result, err := runtime.BuildMatrix(req)
	if err == nil {
		t.Fatal("expected matrix failure")
	}
	if result.Status != MatrixStatusRejected {
		t.Fatalf("expected REJECTED, got %s", result.Status)
	}
	if result.FailCount != 4 {
		t.Fatalf("expected 4 failed targets, got %d", result.FailCount)
	}
	if len(result.Issues) == 0 {
		t.Fatal("expected matrix issues")
	}
}

func TestBuildMatrixRejectsTenantMismatchAcrossProviders(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Postings[0].TenantID = "tenant-002"

	result, err := runtime.BuildMatrix(req)
	if err == nil {
		t.Fatal("expected matrix tenant mismatch failure")
	}
	if result.Status != MatrixStatusRejected {
		t.Fatalf("expected REJECTED, got %s", result.Status)
	}
	if result.FailCount != 4 {
		t.Fatalf("expected 4 failed targets, got %d", result.FailCount)
	}
}

func TestBuildMatrixRejectsMissingPostingHashAcrossProviders(t *testing.T) {
	runtime := newRuntime(t)
	req := validRequest()
	req.Postings[0].PostingHash = ""

	result, err := runtime.BuildMatrix(req)
	if err == nil {
		t.Fatal("expected missing posting hash failure")
	}
	if result.Status != MatrixStatusRejected {
		t.Fatalf("expected REJECTED, got %s", result.Status)
	}
	if result.FailCount != 4 {
		t.Fatalf("expected 4 failed targets, got %d", result.FailCount)
	}
}

func TestValidateMatrixResultDetectsMissingTarget(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.BuildMatrix(validRequest())
	if err != nil {
		t.Fatalf("build matrix failed: %v", err)
	}

	result.TargetResults = result.TargetResults[:3]
	issues := runtime.ValidateMatrixResult(result)
	if len(issues) == 0 {
		t.Fatal("expected missing target issue")
	}
}

func TestValidateMatrixResultDetectsMissingPackageHash(t *testing.T) {
	runtime := newRuntime(t)

	result, err := runtime.BuildMatrix(validRequest())
	if err != nil {
		t.Fatalf("build matrix failed: %v", err)
	}

	result.TargetResults[0].PackageHash = ""
	issues := runtime.ValidateMatrixResult(result)
	if len(issues) == 0 {
		t.Fatal("expected missing package hash issue")
	}
}

func TestRuntimeRejectsMissingTargetsConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RequiredTargets = nil

	_, err := NewFormatValidationMatrixRuntime(cfg)
	if err == nil {
		t.Fatal("expected required targets error")
	}
}

func TestRuntimeRejectsDisabledConfig(t *testing.T) {
	cfg := validConfig()
	cfg.RuntimeEnabled = false

	_, err := NewFormatValidationMatrixRuntime(cfg)
	if err == nil {
		t.Fatal("expected disabled runtime error")
	}
}
