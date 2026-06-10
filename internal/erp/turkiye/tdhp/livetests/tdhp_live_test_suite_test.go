package livetests

import (
	"testing"

	audittrace "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/audittrace"
	reconciliationruntime "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/reconciliationruntime"
	voucherpipeline "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/tdhp/voucherpipeline"
)

func TestTDHPLiveSalesInvoiceEndToEnd(t *testing.T) {
	suite, err := NewTDHPLiveTestSuite()
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	result, err := suite.RunSalesInvoiceLiveE2E("sales-001")
	if err != nil {
		t.Fatalf("sales invoice live E2E failed: %v", err)
	}

	if err := result.RequireReady(); err != nil {
		t.Fatalf("sales invoice live result not ready: %v", err)
	}
	if result.AccountCode != "391.01.20" {
		t.Fatalf("expected output KDV account 391.01.20, got %s", result.AccountCode)
	}
}

func TestTDHPLivePurchaseInvoiceEndToEnd(t *testing.T) {
	suite, err := NewTDHPLiveTestSuite()
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	result, err := suite.RunPurchaseInvoiceLiveE2E("purchase-001")
	if err != nil {
		t.Fatalf("purchase invoice live E2E failed: %v", err)
	}

	if err := result.RequireReady(); err != nil {
		t.Fatalf("purchase invoice live result not ready: %v", err)
	}
	if result.AccountCode != "191.01.20" {
		t.Fatalf("expected input KDV account 191.01.20, got %s", result.AccountCode)
	}
}

func TestTDHPLiveAuditTraceExport(t *testing.T) {
	suite, err := NewTDHPLiveTestSuite()
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	if _, err := suite.RunSalesInvoiceLiveE2E("export-001"); err != nil {
		t.Fatalf("sales invoice live E2E failed: %v", err)
	}

	export, err := suite.ExportPostingAuditTrace("export-001")
	if err != nil {
		t.Fatalf("audit trace export failed: %v", err)
	}

	if export.RecordCount != 1 {
		t.Fatalf("expected 1 trace record, got %d", export.RecordCount)
	}
	if export.PostedCount != 1 {
		t.Fatalf("expected posted count 1, got %d", export.PostedCount)
	}
	if export.ExportHash == "" {
		t.Fatal("expected export hash")
	}
}

func TestTDHPLiveDifferenceScenario(t *testing.T) {
	suite, err := NewTDHPLiveTestSuite()
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	result, err := suite.RunDifferenceScenario("diff-001")
	if err != nil {
		t.Fatalf("difference scenario failed: %v", err)
	}

	if result.Status != reconciliationruntime.ReconciliationStatusDifference {
		t.Fatalf("expected DIFFERENCE, got %s", result.Status)
	}
	if result.Matched {
		t.Fatal("expected not matched")
	}
	if !result.ManualReviewReady {
		t.Fatal("expected manual review ready")
	}
	if len(result.Differences) == 0 {
		t.Fatal("expected differences")
	}
}

func TestTDHPLiveRejectsCurrencyMismatchAtVoucherPipeline(t *testing.T) {
	suite, err := NewTDHPLiveTestSuite()
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	doc := sourceDocument("currency-fail-001", voucherpipeline.DocumentTypeSalesInvoice, 1000000, 200000, 1200000)
	doc.CurrencyCode = "USD"

	_, err = suite.Voucher.BuildVoucher(doc)
	if err == nil {
		t.Fatal("expected currency mismatch error")
	}
}

func TestTDHPLiveRejectsInvalidReconciliationWithoutAuditTrace(t *testing.T) {
	suite, err := NewTDHPLiveTestSuite()
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	voucher, err := suite.Voucher.BuildVoucher(sourceDocument("missing-trace-001", voucherpipeline.DocumentTypeSalesInvoice, 1000000, 200000, 1200000))
	if err != nil {
		t.Fatalf("voucher build failed: %v", err)
	}

	posting, err := suite.Posting.PostDocument(postingRequest("missing-trace-001", voucher, "REAL_VOUCHER_PIPELINE"))
	if err != nil {
		t.Fatalf("post document failed: %v", err)
	}

	req := reconciliationRequest("missing-trace-001", posting, audittrace.AuditTraceRecord{})
	req.AuditTrace.TraceID = ""

	_, err = suite.Reconcile.Reconcile(req)
	if err == nil {
		t.Fatal("expected missing audit trace error")
	}
}
