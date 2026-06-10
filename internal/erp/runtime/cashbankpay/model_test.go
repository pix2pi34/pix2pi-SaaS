package cashbankpay

import (
	"errors"
	"testing"
	"time"
)

func validPaymentRequest() PaymentRequest {
	return PaymentRequest{
		Tenant: TenantContext{
			TenantID:  "tenant_7",
			RequestID: "req-123",
			ActorID:   "user-1",
			ActorType: "user",
		},
		Source: SourceDocumentRef{
			SourceModule:       "sales",
			SourceDocumentType: "invoice",
			SourceDocumentID:   "invoice-id-1",
			SourceDocumentNo:   "INV-000001",
		},
		Fiscal: FiscalContext{
			FiscalYear:   2026,
			FiscalPeriod: "2026-04",
			PaymentDate:  time.Date(2026, 4, 26, 0, 0, 0, 0, time.UTC),
		},
		PaymentNo: "PAY-2026-000001",
		Direction: PaymentDirectionInflow,
		Method:    PaymentMethodCash,
		Account: AccountRef{
			AccountID:   "cash-account-1",
			AccountCode: "100.01",
			AccountName: "Merkez Kasa",
			AccountType: AccountTypeCash,
		},
		Counterparty: CounterpartyRef{
			CustomerID: "customer-1",
			Name:       "Test Musteri",
		},
		Money: Money{
			Amount:       120,
			CurrencyCode: "TRY",
			ExchangeRate: 1,
			LocalAmount:  120,
		},
		Description: "Cash payment test",
		Metadata: map[string]string{
			"source": "faz3_10_6a_test",
		},
	}
}

func TestValidatePaymentRequestSuccess(t *testing.T) {
	req := validPaymentRequest()

	if err := ValidatePaymentRequest(req); err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidatePaymentRequestTenantRequired(t *testing.T) {
	req := validPaymentRequest()
	req.Tenant.TenantID = ""

	err := ValidatePaymentRequest(req)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidatePaymentRequestSourceRequired(t *testing.T) {
	req := validPaymentRequest()
	req.Source.SourceDocumentID = ""
	req.Source.SourceDocumentNo = ""

	err := ValidatePaymentRequest(req)
	if !errors.Is(err, ErrSourceDocumentRequired) {
		t.Fatalf("expected ErrSourceDocumentRequired, got %v", err)
	}
}

func TestValidatePaymentRequestPaymentNoRequired(t *testing.T) {
	req := validPaymentRequest()
	req.PaymentNo = ""

	err := ValidatePaymentRequest(req)
	if !errors.Is(err, ErrPaymentNoRequired) {
		t.Fatalf("expected ErrPaymentNoRequired, got %v", err)
	}
}

func TestValidatePaymentRequestDirectionInvalid(t *testing.T) {
	req := validPaymentRequest()
	req.Direction = PaymentDirection("wrong")

	err := ValidatePaymentRequest(req)
	if !errors.Is(err, ErrPaymentDirectionInvalid) {
		t.Fatalf("expected ErrPaymentDirectionInvalid, got %v", err)
	}
}

func TestValidatePaymentRequestMethodInvalid(t *testing.T) {
	req := validPaymentRequest()
	req.Method = PaymentMethod("wrong")

	err := ValidatePaymentRequest(req)
	if !errors.Is(err, ErrPaymentMethodInvalid) {
		t.Fatalf("expected ErrPaymentMethodInvalid, got %v", err)
	}
}

func TestValidatePaymentRequestAccountRequired(t *testing.T) {
	req := validPaymentRequest()
	req.Account.AccountID = ""
	req.Account.AccountCode = ""

	err := ValidatePaymentRequest(req)
	if !errors.Is(err, ErrAccountRefRequired) {
		t.Fatalf("expected ErrAccountRefRequired, got %v", err)
	}
}

func TestValidatePaymentRequestAccountTypeInvalid(t *testing.T) {
	req := validPaymentRequest()
	req.Account.AccountType = AccountType("wrong")

	err := ValidatePaymentRequest(req)
	if !errors.Is(err, ErrAccountTypeInvalid) {
		t.Fatalf("expected ErrAccountTypeInvalid, got %v", err)
	}
}

func TestValidatePaymentRequestAmountInvalid(t *testing.T) {
	req := validPaymentRequest()
	req.Money.Amount = 0

	err := ValidatePaymentRequest(req)
	if !errors.Is(err, ErrAmountInvalid) {
		t.Fatalf("expected ErrAmountInvalid, got %v", err)
	}
}

func TestValidatePaymentRequestCurrencyRequired(t *testing.T) {
	req := validPaymentRequest()
	req.Money.CurrencyCode = ""

	err := ValidatePaymentRequest(req)
	if !errors.Is(err, ErrCurrencyRequired) {
		t.Fatalf("expected ErrCurrencyRequired, got %v", err)
	}
}

func TestValidatePaymentRequestFiscalYearInvalid(t *testing.T) {
	req := validPaymentRequest()
	req.Fiscal.FiscalYear = 1999

	err := ValidatePaymentRequest(req)
	if !errors.Is(err, ErrFiscalYearInvalid) {
		t.Fatalf("expected ErrFiscalYearInvalid, got %v", err)
	}
}

func TestBuildCashBankMovementInflow(t *testing.T) {
	req := validPaymentRequest()

	movement, err := BuildCashBankMovement(req)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if movement.SignedAmount != 120 {
		t.Fatalf("expected signed amount 120, got %v", movement.SignedAmount)
	}

	if movement.Status != PaymentStatusDraft {
		t.Fatalf("expected draft status, got %s", movement.Status)
	}
}

func TestBuildCashBankMovementOutflow(t *testing.T) {
	req := validPaymentRequest()
	req.Direction = PaymentDirectionOutflow
	req.PaymentNo = "PAY-OUT-000001"

	movement, err := BuildCashBankMovement(req)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if movement.SignedAmount != -120 {
		t.Fatalf("expected signed amount -120, got %v", movement.SignedAmount)
	}
}

func TestBuildPaymentDraftSuccess(t *testing.T) {
	req := validPaymentRequest()

	draft, err := BuildPaymentDraft(req)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if draft.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", draft.TenantID)
	}

	if draft.PaymentNo != req.PaymentNo {
		t.Fatalf("expected payment no %s, got %s", req.PaymentNo, draft.PaymentNo)
	}

	if draft.Status != PaymentStatusDraft {
		t.Fatalf("expected draft status, got %s", draft.Status)
	}

	if len(draft.Movements) != 1 {
		t.Fatalf("expected 1 movement, got %d", len(draft.Movements))
	}
}

func TestValidatePaymentDraftSuccess(t *testing.T) {
	req := validPaymentRequest()

	draft, err := BuildPaymentDraft(req)
	if err != nil {
		t.Fatalf("expected draft success, got %v", err)
	}

	if err := ValidatePaymentDraft(draft); err != nil {
		t.Fatalf("expected validate success, got %v", err)
	}
}

func TestBuildPaymentResultSuccess(t *testing.T) {
	req := validPaymentRequest()

	draft, err := BuildPaymentDraft(req)
	if err != nil {
		t.Fatalf("expected draft success, got %v", err)
	}

	draft.Status = PaymentStatusPosted
	draft.Movements[0].Status = PaymentStatusPosted

	result, err := BuildPaymentResult(req, draft, "payment posted")
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if !result.OK {
		t.Fatal("expected OK result")
	}

	if result.TenantID != req.Tenant.TenantID {
		t.Fatalf("expected tenant %s, got %s", req.Tenant.TenantID, result.TenantID)
	}

	if result.RequestID != req.Tenant.RequestID {
		t.Fatalf("expected request_id %s, got %s", req.Tenant.RequestID, result.RequestID)
	}

	if result.Status != PaymentStatusPosted {
		t.Fatalf("expected posted status, got %s", result.Status)
	}

	if result.SignedAmount != 120 {
		t.Fatalf("expected signed amount 120, got %v", result.SignedAmount)
	}

	if result.PostedAt.IsZero() {
		t.Fatal("expected posted_at")
	}
}

func TestBuildPaymentResultStatusInvalid(t *testing.T) {
	req := validPaymentRequest()

	draft, err := BuildPaymentDraft(req)
	if err != nil {
		t.Fatalf("expected draft success, got %v", err)
	}

	_, err = BuildPaymentResult(req, draft, "payment posted")
	if !errors.Is(err, ErrPaymentStatusInvalid) {
		t.Fatalf("expected ErrPaymentStatusInvalid, got %v", err)
	}
}
