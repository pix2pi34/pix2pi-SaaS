package procurement

import (
	"strings"
	"time"
)

type PurchaseOrderStatus string

const (
	PurchaseOrderStatusDraft             PurchaseOrderStatus = "draft"
	PurchaseOrderStatusConfirmed         PurchaseOrderStatus = "confirmed"
	PurchaseOrderStatusPartiallyReceived PurchaseOrderStatus = "partially_received"
	PurchaseOrderStatusReceived          PurchaseOrderStatus = "received"
	PurchaseOrderStatusPartiallyInvoiced PurchaseOrderStatus = "partially_invoiced"
	PurchaseOrderStatusInvoiced          PurchaseOrderStatus = "invoiced"
	PurchaseOrderStatusCancelled         PurchaseOrderStatus = "cancelled"
	PurchaseOrderStatusClosed            PurchaseOrderStatus = "closed"
)

type PurchaseReceiptStatus string

const (
	PurchaseReceiptStatusDraft     PurchaseReceiptStatus = "draft"
	PurchaseReceiptStatusReceived  PurchaseReceiptStatus = "received"
	PurchaseReceiptStatusCancelled PurchaseReceiptStatus = "cancelled"
	PurchaseReceiptStatusReturned  PurchaseReceiptStatus = "returned"
)

type PurchaseInvoiceStatus string

const (
	PurchaseInvoiceStatusDraft         PurchaseInvoiceStatus = "draft"
	PurchaseInvoiceStatusReceived      PurchaseInvoiceStatus = "received"
	PurchaseInvoiceStatusPartiallyPaid PurchaseInvoiceStatus = "partially_paid"
	PurchaseInvoiceStatusPaid          PurchaseInvoiceStatus = "paid"
	PurchaseInvoiceStatusCancelled     PurchaseInvoiceStatus = "cancelled"
	PurchaseInvoiceStatusVoid          PurchaseInvoiceStatus = "void"
)

type ProcurementLineStatus string

const (
	ProcurementLineStatusActive    ProcurementLineStatus = "active"
	ProcurementLineStatusCancelled ProcurementLineStatus = "cancelled"
	ProcurementLineStatusClosed    ProcurementLineStatus = "closed"
	ProcurementLineStatusReturned  ProcurementLineStatus = "returned"
	ProcurementLineStatusDeleted   ProcurementLineStatus = "deleted"
)

type PurchaseInvoiceType string

const (
	PurchaseInvoiceTypePurchase PurchaseInvoiceType = "purchase"
	PurchaseInvoiceTypeReturn   PurchaseInvoiceType = "return"
	PurchaseInvoiceTypeProforma PurchaseInvoiceType = "proforma"
)

type PurchaseEDocumentStatus string

const (
	PurchaseEDocumentStatusNone      PurchaseEDocumentStatus = "none"
	PurchaseEDocumentStatusPending   PurchaseEDocumentStatus = "pending"
	PurchaseEDocumentStatusReceived  PurchaseEDocumentStatus = "received"
	PurchaseEDocumentStatusAccepted  PurchaseEDocumentStatus = "accepted"
	PurchaseEDocumentStatusRejected  PurchaseEDocumentStatus = "rejected"
	PurchaseEDocumentStatusCancelled PurchaseEDocumentStatus = "cancelled"
)

type PurchaseOrder struct {
	PurchaseOrderID     string
	TenantID            string
	PurchaseOrderNo     string
	VendorID            string
	PartyID             string
	DocumentDate        time.Time
	ExpectedReceiptDate *time.Time
	CurrencyCode        string
	ExchangeRate        float64
	SubtotalAmount      float64
	DiscountAmount      float64
	VATAmount           float64
	TotalAmount         float64
	Status              PurchaseOrderStatus
	Note                string
	CreatedAt           time.Time
	UpdatedAt           time.Time
	DeletedAt           *time.Time
	CreatedBy           string
	UpdatedBy           string
}

type PurchaseOrderLine struct {
	PurchaseOrderLineID string
	TenantID            string
	PurchaseOrderID     string
	LineNo              int
	ItemID              string
	ProductID           string
	UnitID              string
	Description         string
	Quantity            float64
	ReceivedQuantity    float64
	InvoicedQuantity    float64
	UnitCost            float64
	DiscountRate        float64
	DiscountAmount      float64
	VATRate             float64
	VATAmount           float64
	LineTotal           float64
	Status              ProcurementLineStatus
	CreatedAt           time.Time
	UpdatedAt           time.Time
	DeletedAt           *time.Time
	CreatedBy           string
	UpdatedBy           string
}

type PurchaseReceipt struct {
	PurchaseReceiptID string
	TenantID          string
	PurchaseReceiptNo string
	PurchaseOrderID   string
	VendorID          string
	PartyID           string
	WarehouseID       string
	DocumentDate      time.Time
	ReceiptDate       *time.Time
	Status            PurchaseReceiptStatus
	Note              string
	CreatedAt         time.Time
	UpdatedAt         time.Time
	DeletedAt         *time.Time
	CreatedBy         string
	UpdatedBy         string
}

type PurchaseReceiptLine struct {
	PurchaseReceiptLineID string
	TenantID              string
	PurchaseReceiptID     string
	PurchaseOrderLineID   string
	LineNo                int
	ItemID                string
	ProductID             string
	UnitID                string
	Description           string
	Quantity              float64
	Status                ProcurementLineStatus
	CreatedAt             time.Time
	UpdatedAt             time.Time
	DeletedAt             *time.Time
	CreatedBy             string
	UpdatedBy             string
}

type PurchaseInvoice struct {
	PurchaseInvoiceID string
	TenantID          string
	PurchaseInvoiceNo string
	VendorInvoiceNo   string
	PurchaseOrderID   string
	PurchaseReceiptID string
	VendorID          string
	PartyID           string
	InvoiceType       PurchaseInvoiceType
	DocumentDate      time.Time
	DueDate           *time.Time
	CurrencyCode      string
	ExchangeRate      float64
	SubtotalAmount    float64
	DiscountAmount    float64
	VATAmount         float64
	TotalAmount       float64
	PaidAmount        float64
	RemainingAmount   float64
	EDocumentStatus   PurchaseEDocumentStatus
	Status            PurchaseInvoiceStatus
	Note              string
	CreatedAt         time.Time
	UpdatedAt         time.Time
	DeletedAt         *time.Time
	CreatedBy         string
	UpdatedBy         string
}

type PurchaseInvoiceLine struct {
	PurchaseInvoiceLineID string
	TenantID              string
	PurchaseInvoiceID     string
	PurchaseOrderLineID   string
	PurchaseReceiptLineID string
	LineNo                int
	ItemID                string
	ProductID             string
	UnitID                string
	Description           string
	Quantity              float64
	UnitCost              float64
	DiscountRate          float64
	DiscountAmount        float64
	VATRate               float64
	VATAmount             float64
	LineTotal             float64
	Status                ProcurementLineStatus
	CreatedAt             time.Time
	UpdatedAt             time.Time
	DeletedAt             *time.Time
	CreatedBy             string
	UpdatedBy             string
}

type CreatePurchaseOrderInput struct {
	TenantID            string
	PurchaseOrderNo     string
	VendorID            string
	PartyID             string
	DocumentDate        time.Time
	ExpectedReceiptDate *time.Time
	CurrencyCode        string
	ExchangeRate        float64
	SubtotalAmount      float64
	DiscountAmount      float64
	VATAmount           float64
	TotalAmount         float64
	Note                string
	CreatedBy           string
}

type CreatePurchaseOrderLineInput struct {
	TenantID         string
	PurchaseOrderID  string
	LineNo           int
	ItemID           string
	ProductID        string
	UnitID           string
	Description      string
	Quantity         float64
	ReceivedQuantity float64
	InvoicedQuantity float64
	UnitCost         float64
	DiscountRate     float64
	DiscountAmount   float64
	VATRate          float64
	VATAmount        float64
	LineTotal        float64
	CreatedBy        string
}

type CreatePurchaseReceiptInput struct {
	TenantID          string
	PurchaseReceiptNo string
	PurchaseOrderID   string
	VendorID          string
	PartyID           string
	WarehouseID       string
	DocumentDate      time.Time
	ReceiptDate       *time.Time
	Note              string
	CreatedBy         string
}

type CreatePurchaseReceiptLineInput struct {
	TenantID            string
	PurchaseReceiptID   string
	PurchaseOrderLineID string
	LineNo              int
	ItemID              string
	ProductID           string
	UnitID              string
	Description         string
	Quantity            float64
	CreatedBy           string
}

type CreatePurchaseInvoiceInput struct {
	TenantID          string
	PurchaseInvoiceNo string
	VendorInvoiceNo   string
	PurchaseOrderID   string
	PurchaseReceiptID string
	VendorID          string
	PartyID           string
	InvoiceType       PurchaseInvoiceType
	DocumentDate      time.Time
	DueDate           *time.Time
	CurrencyCode      string
	ExchangeRate      float64
	SubtotalAmount    float64
	DiscountAmount    float64
	VATAmount         float64
	TotalAmount       float64
	PaidAmount        float64
	RemainingAmount   float64
	EDocumentStatus   PurchaseEDocumentStatus
	Note              string
	CreatedBy         string
}

type CreatePurchaseInvoiceLineInput struct {
	TenantID              string
	PurchaseInvoiceID     string
	PurchaseOrderLineID   string
	PurchaseReceiptLineID string
	LineNo                int
	ItemID                string
	ProductID             string
	UnitID                string
	Description           string
	Quantity              float64
	UnitCost              float64
	DiscountRate          float64
	DiscountAmount        float64
	VATRate               float64
	VATAmount             float64
	LineTotal             float64
	CreatedBy             string
}

func ValidateCreatePurchaseOrderInput(input CreatePurchaseOrderInput) error {
	if err := validateProcurementHeader(input.TenantID, input.VendorID, input.PartyID); err != nil {
		return err
	}

	if strings.TrimSpace(input.PurchaseOrderNo) == "" {
		return ErrPurchaseOrderNoRequired
	}

	return validateProcurementAmountSummary(input.ExchangeRate, input.SubtotalAmount, input.DiscountAmount, input.VATAmount, input.TotalAmount)
}

func ValidateCreatePurchaseOrderLineInput(input CreatePurchaseOrderLineInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.PurchaseOrderID) == "" {
		return ErrPurchaseOrderIDRequired
	}

	if err := validateProcurementLine(input.LineNo, input.ItemID, input.UnitID, input.Quantity, input.UnitCost, input.DiscountRate, input.DiscountAmount, input.VATRate, input.VATAmount, input.LineTotal); err != nil {
		return err
	}

	if input.ReceivedQuantity < 0 || input.InvoicedQuantity < 0 || input.ReceivedQuantity > input.Quantity || input.InvoicedQuantity > input.Quantity {
		return ErrQuantityRangeInvalid
	}

	return nil
}

func ValidateCreatePurchaseReceiptInput(input CreatePurchaseReceiptInput) error {
	if err := validateProcurementHeader(input.TenantID, input.VendorID, input.PartyID); err != nil {
		return err
	}

	if strings.TrimSpace(input.PurchaseReceiptNo) == "" {
		return ErrPurchaseReceiptNoRequired
	}

	if strings.TrimSpace(input.WarehouseID) == "" {
		return ErrWarehouseIDRequired
	}

	return nil
}

func ValidateCreatePurchaseReceiptLineInput(input CreatePurchaseReceiptLineInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.PurchaseReceiptID) == "" {
		return ErrPurchaseReceiptIDRequired
	}

	if input.LineNo <= 0 {
		return ErrLineNoInvalid
	}

	if strings.TrimSpace(input.ItemID) == "" {
		return ErrItemIDRequired
	}

	if strings.TrimSpace(input.UnitID) == "" {
		return ErrUnitIDRequired
	}

	if input.Quantity <= 0 {
		return ErrQuantityMustBePositive
	}

	return nil
}

func ValidateCreatePurchaseInvoiceInput(input CreatePurchaseInvoiceInput) error {
	if err := validateProcurementHeader(input.TenantID, input.VendorID, input.PartyID); err != nil {
		return err
	}

	if strings.TrimSpace(input.PurchaseInvoiceNo) == "" {
		return ErrPurchaseInvoiceNoRequired
	}

	invoiceType := input.InvoiceType
	if strings.TrimSpace(string(invoiceType)) == "" {
		invoiceType = PurchaseInvoiceTypePurchase
	}

	switch invoiceType {
	case PurchaseInvoiceTypePurchase, PurchaseInvoiceTypeReturn, PurchaseInvoiceTypeProforma:
	default:
		return ErrPurchaseInvoiceTypeInvalid
	}

	eDocumentStatus := input.EDocumentStatus
	if strings.TrimSpace(string(eDocumentStatus)) == "" {
		eDocumentStatus = PurchaseEDocumentStatusNone
	}

	switch eDocumentStatus {
	case PurchaseEDocumentStatusNone, PurchaseEDocumentStatusPending, PurchaseEDocumentStatusReceived, PurchaseEDocumentStatusAccepted, PurchaseEDocumentStatusRejected, PurchaseEDocumentStatusCancelled:
	default:
		return ErrPurchaseEDocumentInvalid
	}

	if err := validateProcurementAmountSummary(input.ExchangeRate, input.SubtotalAmount, input.DiscountAmount, input.VATAmount, input.TotalAmount); err != nil {
		return err
	}

	if input.PaidAmount < 0 || input.RemainingAmount < 0 || input.PaidAmount > input.TotalAmount {
		return ErrAmountInvalid
	}

	return nil
}

func ValidateCreatePurchaseInvoiceLineInput(input CreatePurchaseInvoiceLineInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.PurchaseInvoiceID) == "" {
		return ErrPurchaseInvoiceIDRequired
	}

	return validateProcurementLine(input.LineNo, input.ItemID, input.UnitID, input.Quantity, input.UnitCost, input.DiscountRate, input.DiscountAmount, input.VATRate, input.VATAmount, input.LineTotal)
}

func validateProcurementHeader(tenantID string, vendorID string, partyID string) error {
	if strings.TrimSpace(tenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(vendorID) == "" {
		return ErrVendorIDRequired
	}

	if strings.TrimSpace(partyID) == "" {
		return ErrPartyIDRequired
	}

	return nil
}

func validateProcurementAmountSummary(exchangeRate float64, subtotalAmount float64, discountAmount float64, vatAmount float64, totalAmount float64) error {
	if exchangeRate <= 0 {
		return ErrAmountInvalid
	}

	if subtotalAmount < 0 || discountAmount < 0 || vatAmount < 0 || totalAmount < 0 {
		return ErrAmountInvalid
	}

	return nil
}

func validateProcurementLine(lineNo int, itemID string, unitID string, quantity float64, unitCost float64, discountRate float64, discountAmount float64, vatRate float64, vatAmount float64, lineTotal float64) error {
	if lineNo <= 0 {
		return ErrLineNoInvalid
	}

	if strings.TrimSpace(itemID) == "" {
		return ErrItemIDRequired
	}

	if strings.TrimSpace(unitID) == "" {
		return ErrUnitIDRequired
	}

	if quantity <= 0 {
		return ErrQuantityMustBePositive
	}

	if unitCost < 0 || discountAmount < 0 || vatAmount < 0 || lineTotal < 0 {
		return ErrAmountInvalid
	}

	if discountRate < 0 || discountRate > 100 {
		return ErrDiscountRateInvalid
	}

	if vatRate < 0 || vatRate > 100 {
		return ErrVATRateInvalid
	}

	return nil
}
