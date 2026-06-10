package purchaseinvoice

import (
	"math"
	"strings"
	"time"
)

type InvoiceStatus string

const (
	InvoiceStatusDraft     InvoiceStatus = "draft"
	InvoiceStatusPosted    InvoiceStatus = "posted"
	InvoiceStatusCancelled InvoiceStatus = "cancelled"
	InvoiceStatusReversed  InvoiceStatus = "reversed"
)

type TenantContext struct {
	TenantID  string
	RequestID string
	ActorID   string
	ActorType string
}

type FiscalContext struct {
	FiscalYear   int
	FiscalPeriod string
	InvoiceDate  time.Time
	PostingDate  time.Time
}

type VendorRef struct {
	PartyID    string
	VendorID   string
	VendorCode string
	VendorName string
	TaxNo      string
	TaxOffice  string
}

type ItemRef struct {
	ItemID    string
	ProductID string
	UnitID    string

	ItemCode string
	ItemName string
	UnitCode string
}

type MoneyContext struct {
	CurrencyCode string
	ExchangeRate float64
}

type PurchaseInvoiceLineRequest struct {
	LineNo int

	Item ItemRef

	Quantity       float64
	UnitPrice      float64
	DiscountAmount float64

	TaxCode string
	TaxRate float64

	Description string
}

type PurchaseInvoiceRequest struct {
	Tenant TenantContext
	Fiscal FiscalContext

	InvoiceNo string

	Vendor VendorRef
	Money  MoneyContext

	Lines []PurchaseInvoiceLineRequest

	Description string
	Metadata    map[string]string
}

type PurchaseInvoiceLineDraft struct {
	LineNo int

	Item ItemRef

	Quantity  float64
	UnitPrice float64

	GrossLineAmount float64
	DiscountAmount  float64
	TaxableAmount   float64

	TaxCode   string
	TaxRate   float64
	TaxAmount float64

	LineTotalAmount float64

	LocalGrossLineAmount float64
	LocalDiscountAmount  float64
	LocalTaxableAmount   float64
	LocalTaxAmount       float64
	LocalLineTotalAmount float64

	Description string
}

type PurchaseInvoiceDraft struct {
	TenantID string

	InvoiceNo string
	Status    InvoiceStatus

	Fiscal FiscalContext

	Vendor VendorRef
	Money  MoneyContext

	TotalGrossAmount    float64
	TotalDiscountAmount float64
	TotalTaxableAmount  float64
	TotalTaxAmount      float64
	TotalInvoiceAmount  float64

	LocalTotalGrossAmount    float64
	LocalTotalDiscountAmount float64
	LocalTotalTaxableAmount  float64
	LocalTotalTaxAmount      float64
	LocalTotalInvoiceAmount  float64

	Description string

	Lines []PurchaseInvoiceLineDraft
}

type PurchaseInvoiceResult struct {
	OK bool

	TenantID  string
	RequestID string

	InvoiceNo string
	Status    InvoiceStatus

	Fiscal FiscalContext
	Vendor VendorRef
	Money  MoneyContext

	TotalGrossAmount    float64
	TotalDiscountAmount float64
	TotalTaxableAmount  float64
	TotalTaxAmount      float64
	TotalInvoiceAmount  float64

	LineCount int

	PostedAt time.Time
	Message  string
}

func ValidateTenantContext(ctx TenantContext) error {
	if strings.TrimSpace(ctx.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(ctx.RequestID) == "" {
		return ErrRequestIDRequired
	}

	if strings.TrimSpace(ctx.ActorID) == "" {
		return ErrActorRequired
	}

	return nil
}

func ValidateFiscalContext(ctx FiscalContext) error {
	if ctx.FiscalYear < 2000 || ctx.FiscalYear > 2100 {
		return ErrFiscalYearInvalid
	}

	if strings.TrimSpace(ctx.FiscalPeriod) == "" {
		return ErrFiscalPeriodRequired
	}

	if ctx.InvoiceDate.IsZero() {
		return ErrInvoiceDateRequired
	}

	if ctx.PostingDate.IsZero() {
		return ErrPostingDateRequired
	}

	return nil
}

func ValidateVendorRef(vendor VendorRef) error {
	if strings.TrimSpace(vendor.VendorID) == "" &&
		strings.TrimSpace(vendor.VendorCode) == "" &&
		strings.TrimSpace(vendor.VendorName) == "" {
		return ErrVendorRequired
	}

	return nil
}

func ValidateMoneyContext(money MoneyContext) error {
	if strings.TrimSpace(money.CurrencyCode) == "" {
		return ErrCurrencyRequired
	}

	if money.ExchangeRate <= 0 {
		return ErrExchangeRateInvalid
	}

	return nil
}

func ValidateItemRef(item ItemRef) error {
	if strings.TrimSpace(item.ItemID) == "" &&
		strings.TrimSpace(item.ProductID) == "" &&
		strings.TrimSpace(item.ItemCode) == "" &&
		strings.TrimSpace(item.ItemName) == "" {
		return ErrItemRequired
	}

	return nil
}

func ValidatePurchaseInvoiceLineRequest(line PurchaseInvoiceLineRequest) error {
	if err := ValidateItemRef(line.Item); err != nil {
		return err
	}

	if line.Quantity <= 0 {
		return ErrQuantityInvalid
	}

	if line.UnitPrice < 0 {
		return ErrUnitPriceInvalid
	}

	if line.DiscountAmount < 0 {
		return ErrDiscountInvalid
	}

	grossLineAmount := roundAmount(line.Quantity * line.UnitPrice)
	if line.DiscountAmount > grossLineAmount {
		return ErrDiscountInvalid
	}

	if strings.TrimSpace(line.TaxCode) == "" {
		return ErrTaxCodeRequired
	}

	if line.TaxRate < 0 || line.TaxRate > 100 {
		return ErrTaxRateInvalid
	}

	return nil
}

func ValidatePurchaseInvoiceRequest(req PurchaseInvoiceRequest) error {
	if err := ValidateTenantContext(req.Tenant); err != nil {
		return err
	}

	if err := ValidateFiscalContext(req.Fiscal); err != nil {
		return err
	}

	if strings.TrimSpace(req.InvoiceNo) == "" {
		return ErrInvoiceNoRequired
	}

	if err := ValidateVendorRef(req.Vendor); err != nil {
		return err
	}

	if err := ValidateMoneyContext(req.Money); err != nil {
		return err
	}

	if len(req.Lines) < 1 {
		return ErrInvoiceLineCountInvalid
	}

	for _, line := range req.Lines {
		if err := ValidatePurchaseInvoiceLineRequest(line); err != nil {
			return err
		}
	}

	return nil
}

func ValidatePurchaseInvoiceDraft(draft PurchaseInvoiceDraft) error {
	if strings.TrimSpace(draft.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(draft.InvoiceNo) == "" {
		return ErrInvoiceNoRequired
	}

	if !isValidInvoiceStatus(draft.Status) {
		return ErrInvoiceStatusInvalid
	}

	if err := ValidateFiscalContext(draft.Fiscal); err != nil {
		return err
	}

	if err := ValidateVendorRef(draft.Vendor); err != nil {
		return err
	}

	if err := ValidateMoneyContext(draft.Money); err != nil {
		return err
	}

	if len(draft.Lines) < 1 {
		return ErrInvoiceLineCountInvalid
	}

	if draft.TotalInvoiceAmount <= 0 || draft.LocalTotalInvoiceAmount <= 0 {
		return ErrInvoiceTotalInvalid
	}

	return nil
}

func BuildPurchaseInvoiceLineDraft(line PurchaseInvoiceLineRequest, money MoneyContext) (PurchaseInvoiceLineDraft, error) {
	if err := ValidatePurchaseInvoiceLineRequest(line); err != nil {
		return PurchaseInvoiceLineDraft{}, err
	}

	if err := ValidateMoneyContext(money); err != nil {
		return PurchaseInvoiceLineDraft{}, err
	}

	grossLineAmount := roundAmount(line.Quantity * line.UnitPrice)
	discountAmount := roundAmount(line.DiscountAmount)
	taxableAmount := roundAmount(grossLineAmount - discountAmount)
	taxAmount := roundAmount(taxableAmount * line.TaxRate / 100)
	lineTotalAmount := roundAmount(taxableAmount + taxAmount)

	exchangeRate := money.ExchangeRate

	return PurchaseInvoiceLineDraft{
		LineNo:    line.LineNo,
		Item:      line.Item,
		Quantity:  roundQuantity(line.Quantity),
		UnitPrice: roundAmount(line.UnitPrice),

		GrossLineAmount: grossLineAmount,
		DiscountAmount:  discountAmount,
		TaxableAmount:   taxableAmount,

		TaxCode:   strings.TrimSpace(line.TaxCode),
		TaxRate:   line.TaxRate,
		TaxAmount: taxAmount,

		LineTotalAmount: lineTotalAmount,

		LocalGrossLineAmount: roundAmount(grossLineAmount * exchangeRate),
		LocalDiscountAmount:  roundAmount(discountAmount * exchangeRate),
		LocalTaxableAmount:   roundAmount(taxableAmount * exchangeRate),
		LocalTaxAmount:       roundAmount(taxAmount * exchangeRate),
		LocalLineTotalAmount: roundAmount(lineTotalAmount * exchangeRate),

		Description: line.Description,
	}, nil
}

func BuildPurchaseInvoiceDraft(req PurchaseInvoiceRequest) (PurchaseInvoiceDraft, error) {
	if err := ValidatePurchaseInvoiceRequest(req); err != nil {
		return PurchaseInvoiceDraft{}, err
	}

	lines := make([]PurchaseInvoiceLineDraft, 0, len(req.Lines))

	var totalGross float64
	var totalDiscount float64
	var totalTaxable float64
	var totalTax float64
	var totalInvoice float64

	var localTotalGross float64
	var localTotalDiscount float64
	var localTotalTaxable float64
	var localTotalTax float64
	var localTotalInvoice float64

	for _, lineReq := range req.Lines {
		line, err := BuildPurchaseInvoiceLineDraft(lineReq, req.Money)
		if err != nil {
			return PurchaseInvoiceDraft{}, err
		}

		lines = append(lines, line)

		totalGross += line.GrossLineAmount
		totalDiscount += line.DiscountAmount
		totalTaxable += line.TaxableAmount
		totalTax += line.TaxAmount
		totalInvoice += line.LineTotalAmount

		localTotalGross += line.LocalGrossLineAmount
		localTotalDiscount += line.LocalDiscountAmount
		localTotalTaxable += line.LocalTaxableAmount
		localTotalTax += line.LocalTaxAmount
		localTotalInvoice += line.LocalLineTotalAmount
	}

	return PurchaseInvoiceDraft{
		TenantID:  req.Tenant.TenantID,
		InvoiceNo: req.InvoiceNo,
		Status:    InvoiceStatusDraft,

		Fiscal: req.Fiscal,

		Vendor: req.Vendor,
		Money: MoneyContext{
			CurrencyCode: strings.ToUpper(strings.TrimSpace(req.Money.CurrencyCode)),
			ExchangeRate: req.Money.ExchangeRate,
		},

		TotalGrossAmount:    roundAmount(totalGross),
		TotalDiscountAmount: roundAmount(totalDiscount),
		TotalTaxableAmount:  roundAmount(totalTaxable),
		TotalTaxAmount:      roundAmount(totalTax),
		TotalInvoiceAmount:  roundAmount(totalInvoice),

		LocalTotalGrossAmount:    roundAmount(localTotalGross),
		LocalTotalDiscountAmount: roundAmount(localTotalDiscount),
		LocalTotalTaxableAmount:  roundAmount(localTotalTaxable),
		LocalTotalTaxAmount:      roundAmount(localTotalTax),
		LocalTotalInvoiceAmount:  roundAmount(localTotalInvoice),

		Description: req.Description,
		Lines:       lines,
	}, nil
}

func BuildPurchaseInvoiceResult(req PurchaseInvoiceRequest, draft PurchaseInvoiceDraft, message string) (PurchaseInvoiceResult, error) {
	if err := ValidatePurchaseInvoiceRequest(req); err != nil {
		return PurchaseInvoiceResult{}, err
	}

	if err := ValidatePurchaseInvoiceDraft(draft); err != nil {
		return PurchaseInvoiceResult{}, err
	}

	if draft.Status != InvoiceStatusPosted {
		return PurchaseInvoiceResult{}, ErrInvoiceStatusInvalid
	}

	return PurchaseInvoiceResult{
		OK: true,

		TenantID:  req.Tenant.TenantID,
		RequestID: req.Tenant.RequestID,

		InvoiceNo: draft.InvoiceNo,
		Status:    InvoiceStatusPosted,

		Fiscal: draft.Fiscal,
		Vendor: draft.Vendor,
		Money:  draft.Money,

		TotalGrossAmount:    draft.TotalGrossAmount,
		TotalDiscountAmount: draft.TotalDiscountAmount,
		TotalTaxableAmount:  draft.TotalTaxableAmount,
		TotalTaxAmount:      draft.TotalTaxAmount,
		TotalInvoiceAmount:  draft.TotalInvoiceAmount,

		LineCount: len(draft.Lines),

		PostedAt: time.Now().UTC(),
		Message:  message,
	}, nil
}

func isValidInvoiceStatus(status InvoiceStatus) bool {
	switch status {
	case InvoiceStatusDraft, InvoiceStatusPosted, InvoiceStatusCancelled, InvoiceStatusReversed:
		return true
	default:
		return false
	}
}

func roundAmount(value float64) float64 {
	return math.Round(value*100) / 100
}

func roundQuantity(value float64) float64 {
	return math.Round(value*10000) / 10000
}
