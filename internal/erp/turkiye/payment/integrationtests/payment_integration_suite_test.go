package integrationtests

import (
	"testing"

	bank "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/payment/bankcollection"
	payerr "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/payment/errorretry"
	audit "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/payment/integrationaudit"
	pos "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/payment/pos"
	recon "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/payment/reconciliation"
	refund "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/payment/refundcancel"
	status "github.com/divrigili/pix2pi-SaaS/internal/erp/turkiye/payment/statussync"
)

func TestPaymentIntegrationE2EPOSSaleStatusRefundReconciliationAndAudit(t *testing.T) {
	suite, err := NewPaymentIntegrationSuite()
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	saleResponse, err := suite.POSProviderRuntime.Sale(POSSaleRequest())
	if err != nil {
		t.Fatalf("POS sale failed: %v", err)
	}
	if saleResponse.DecisionStatus != pos.DecisionAllowed {
		t.Fatalf("expected POS sale allowed, got %s", saleResponse.DecisionStatus)
	}
	if saleResponse.TransactionStatus != pos.TransactionSold {
		t.Fatalf("expected POS transaction sold, got %s", saleResponse.TransactionStatus)
	}

	statusResponse, err := suite.PaymentStatusSyncRuntime.HandleWebhook(
		PaymentStatusWebhookFromPOS(saleResponse.ProviderTxnID),
		status.CanonicalStatusAuthorized,
	)
	if err != nil {
		t.Fatalf("payment status webhook failed: %v", err)
	}
	if statusResponse.NewStatus != status.CanonicalStatusPaid {
		t.Fatalf("expected canonical PAID, got %s", statusResponse.NewStatus)
	}
	if !statusResponse.PaymentCompleted {
		t.Fatal("expected payment completed")
	}

	refundQueued, err := suite.RefundCancelRuntime.PrepareRefund(RefundRequest(saleResponse.ProviderTxnID))
	if err != nil {
		t.Fatalf("prepare refund failed: %v", err)
	}
	if refundQueued.DecisionStatus != refund.DecisionQueued {
		t.Fatalf("expected refund queued, got %s", refundQueued.DecisionStatus)
	}

	refundAccepted, err := suite.RefundCancelRuntime.RegisterRefundAccepted(RefundRequest(saleResponse.ProviderTxnID))
	if err != nil {
		t.Fatalf("register refund accepted failed: %v", err)
	}
	if refundAccepted.LifecycleStatus != refund.LifecycleRefundAccepted {
		t.Fatalf("expected refund accepted, got %s", refundAccepted.LifecycleStatus)
	}

	refundReconciliation, err := suite.ReconciliationRuntime.ReconcileRefundReversal(
		RefundReconciliationRequest(saleResponse.ProviderTxnID),
	)
	if err != nil {
		t.Fatalf("refund reversal reconciliation failed: %v", err)
	}
	if refundReconciliation.DecisionStatus != recon.DecisionMatched {
		t.Fatalf("expected refund reconciliation matched, got %s", refundReconciliation.DecisionStatus)
	}
	if !refundReconciliation.LedgerPostingReady {
		t.Fatal("expected refund reconciliation ledger posting ready")
	}

	retryDecision, err := suite.PaymentErrorRetryRuntime.HandleProviderError(RetryablePaymentErrorEvent())
	if err != nil {
		t.Fatalf("payment error retry handling failed: %v", err)
	}
	if retryDecision.DecisionStatus != payerr.DecisionRetryScheduled {
		t.Fatalf("expected retry scheduled, got %s", retryDecision.DecisionStatus)
	}

	auditResult, err := suite.IntegrationAuditRuntime.EvaluateEvidenceBundle(ReadyAuditBundle())
	if err != nil {
		t.Fatalf("audit bundle evaluation failed: %v", err)
	}
	if auditResult.DecisionStatus != audit.DecisionReady {
		t.Fatalf("expected audit ready, got %s", auditResult.DecisionStatus)
	}
	if !auditResult.ReadyForClosure {
		t.Fatal("expected audit ready for closure")
	}
}

func TestPaymentIntegrationE2EBankCollectionReconciliationAndStatusSync(t *testing.T) {
	suite, err := NewPaymentIntegrationSuite()
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	registerResponse, err := suite.BankCollectionRuntime.RegisterBankTransfer(BankCollectionRequest())
	if err != nil {
		t.Fatalf("register bank transfer failed: %v", err)
	}
	if registerResponse.DecisionStatus != bank.DecisionAccepted {
		t.Fatalf("expected bank transfer accepted, got %s", registerResponse.DecisionStatus)
	}

	matchResponse, err := suite.BankCollectionRuntime.MatchBankStatement(BankCollectionRequest())
	if err != nil {
		t.Fatalf("match bank statement failed: %v", err)
	}
	if matchResponse.DecisionStatus != bank.DecisionMatched {
		t.Fatalf("expected bank statement matched, got %s", matchResponse.DecisionStatus)
	}

	reconcileResponse, err := suite.BankCollectionRuntime.ReconcileCollection(BankCollectionRequest())
	if err != nil {
		t.Fatalf("bank collection reconcile failed: %v", err)
	}
	if reconcileResponse.CollectionStatus != bank.CollectionReconciled {
		t.Fatalf("expected bank collection reconciled, got %s", reconcileResponse.CollectionStatus)
	}

	bankRecon, err := suite.ReconciliationRuntime.ReconcileBankStatement(BankReconciliationRequest())
	if err != nil {
		t.Fatalf("bank statement reconciliation runtime failed: %v", err)
	}
	if bankRecon.DecisionStatus != recon.DecisionMatched {
		t.Fatalf("expected reconciliation matched, got %s", bankRecon.DecisionStatus)
	}
	if !bankRecon.PaymentClosureReady {
		t.Fatal("expected payment closure ready")
	}

	statusResult, err := suite.PaymentStatusSyncRuntime.HandleManualRecheck(
		BankManualStatusRecheck(),
		status.CanonicalStatusMatched,
	)
	if err != nil {
		t.Fatalf("manual status recheck failed: %v", err)
	}
	if statusResult.NewStatus != status.CanonicalStatusReconciled {
		t.Fatalf("expected reconciled status, got %s", statusResult.NewStatus)
	}
	if !statusResult.ReconciliationCompleted {
		t.Fatal("expected reconciliation completed")
	}
}

func TestPaymentIntegrationE2EFailurePathsProtectClosure(t *testing.T) {
	suite, err := NewPaymentIntegrationSuite()
	if err != nil {
		t.Fatalf("suite init failed: %v", err)
	}

	invalidPOS := POSSaleRequest()
	invalidPOS.MaskedCardPAN = "4508123412341234"

	posResult, err := suite.POSProviderRuntime.Sale(invalidPOS)
	if err == nil {
		t.Fatal("expected invalid POS masked PAN error")
	}
	if posResult.DecisionStatus != pos.DecisionDenied {
		t.Fatalf("expected POS denied, got %s", posResult.DecisionStatus)
	}

	badReconReq := BankReconciliationRequest()
	badReconReq.ActualAmountKurus = 151000

	reconResult, err := suite.ReconciliationRuntime.ReconcileBankStatement(badReconReq)
	if err != nil {
		t.Fatalf("difference reconciliation should not hard fail: %v", err)
	}
	if reconResult.DecisionStatus != recon.DecisionDifferenceReview {
		t.Fatalf("expected difference review, got %s", reconResult.DecisionStatus)
	}
	if !reconResult.ManualReviewRequired {
		t.Fatal("expected manual review required")
	}

	bundle := ReadyAuditBundle()
	bundle.Events = bundle.Events[:len(bundle.Events)-1]

	auditResult, err := suite.IntegrationAuditRuntime.EvaluateEvidenceBundle(bundle)
	if err == nil {
		t.Fatal("expected missing audit scope error")
	}
	if auditResult.ErrorCode != "REQUIRED_AUDIT_SCOPE_MISSING" {
		t.Fatalf("expected REQUIRED_AUDIT_SCOPE_MISSING, got %s", auditResult.ErrorCode)
	}
	if auditResult.ReadyForClosure {
		t.Fatal("expected not ready for closure")
	}
}
