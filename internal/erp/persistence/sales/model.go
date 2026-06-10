package sales

import (
	"strings"
	"time"
)

type SalesQuotationStatus string

const (
	SalesQuotationStatusDraft     SalesQuotationStatus = "draft"
	SalesQuotationStatusSent      SalesQuotationStatus = "sent"
	SalesQuotationStatusAccepted  SalesQuotationStatus = "accepted"
	SalesQuotationStatusRejected  SalesQuotationStatus = "rejected"
	SalesQuotationStatusExpired   SalesQuotationStatus = "expired"
	SalesQuotationStatusCancelled SalesQuotationStatus = "cancelled"
	SalesQuotationStatusConverted SalesQuotationStatus = "converted"
)

type SalesOrderStatus string

const (
	SalesOrderStatusDraft              SalesOrderStatus = "draft"
	SalesOrderStatusConfirmed          SalesOrderStatus = "confirmed"
	SalesOrderStatusPartiallyDelivered SalesOrderStatus = "partially_delivered"
	SalesOrderStatusDelivered          SalesOrderStatus = "delivered"
	SalesOrderStatusPartiallyInvoiced  SalesOrderStatus = "partially_invoiced"
	SalesOrderStatusInvoiced           SalesOrderStatus = "invoiced"
	SalesOrderStatusCancelled          SalesOrderStatus = "cancelled"
	SalesOrderStatusClosed             SalesOrderStatus = "closed"
)

type SalesDeliveryStatus string

const (
	SalesDeliveryStatusDraft     SalesDeliveryStatus = "draft"
	SalesDeliveryStatusReady     SalesDeliveryStatus = "ready"
	SalesDeliveryStatusShipped   SalesDeliveryStatus = "shipped"
	SalesDeliveryStatusDelivered SalesDeliveryStatus = "delivered"
	SalesDeliveryStatusCancelled SalesDeliveryStatus = "cancelled"
	SalesDeliveryStatusReturned  SalesDeliveryStatus = "returned"
)

type SalesInvoiceStatus string

const (
	SalesInvoiceStatusDraft         SalesInvoiceStatus = "draft"
	SalesInvoiceStatusIssued        SalesInvoiceStatus = "issued"
	SalesInvoiceStatusPartiallyPaid SalesInvoiceStatus = "partially_paid"
	SalesInvoiceStatusPaid          SalesInvoiceStatus = "paid"
	SalesInvoiceStatusCancelled     SalesInvoiceStatus = "cancelled"
	SalesInvoiceStatusVoid          SalesInvoiceStatus = "void"
)

type SalesLineStatus string

const (
	SalesLineStatusActive    SalesLineStatus = "active"
	SalesLineStatusCancelled SalesLineStatus = "cancelled"
	SalesLineStatusClosed    SalesLineStatus = "closed"
	SalesLineStatusReturned  SalesLineStatus = "returned"
	SalesLineStatusDeleted   SalesLineStatus = "deleted"
)

type SalesInvoiceType string

const (
	SalesInvoiceTypeSales    SalesInvoiceType = "sales"
	SalesInvoiceTypeReturn   SalesInvoiceType = "return"
	SalesInvoiceTypeProforma SalesInvoiceType = "proforma"
)

type EDocumentStatus string

const (
	EDocumentStatusNone      EDocumentStatus = "none"
	EDocumentStatusPending   EDocumentStatus = "pending"
	EDocumentStatusSent      EDocumentStatus = "sent"
	EDocumentStatusAccepted  EDocumentStatus = "accepted"
	EDocumentStatusRejected  EDocumentStatus = "rejected"
	EDocumentStatusCancelled EDocumentStatus = "cancelled"
)

type SalesQuotation struct {
	QuotationID      string
	TenantID         string
	QuotationNo      string
	CustomerID       string
	PartyID          string
	DocumentDate     time.Time
	ValidUntil       *time.Time
	CurrencyCode     string
	ExchangeRate     float64
	SubtotalAmount   float64
	DiscountAmount   float64
	VATAmount        float64
	TotalAmount      float64
	Status           SalesQuotationStatus
	Note             string
	ConvertedOrderID string
	CreatedAt        time.Time
	UpdatedAt        time.Time
	DeletedAt        *time.Time
	CreatedBy        string
	UpdatedBy        string
}

type SalesQuotationLine struct {
	QuotationLineID string
	TenantID        string
	QuotationID     string
	LineNo          int
	ItemID          string
	ProductID       string
	UnitID          string
	Description     string
	Quantity        float64
	UnitPrice       float64
	DiscountRate    float64
	DiscountAmount  float64
	VATRate         float64
	VATAmount       float64
	LineTotal       float64
	Status          SalesLineStatus
	CreatedAt       time.Time
	UpdatedAt       time.Time
	DeletedAt       *time.Time
	CreatedBy       string
	UpdatedBy       string
}

type SalesOrder struct {
	SalesOrderID          string
	TenantID              string
	SalesOrderNo          string
	QuotationID           string
	CustomerID            string
	PartyID               string
	DocumentDate          time.Time
	RequestedDeliveryDate *time.Time
	CurrencyCode          string
	ExchangeRate          float64
	SubtotalAmount        float64
	DiscountAmount        float64
	VATAmount             float64
	TotalAmount           float64
	Status                SalesOrderStatus
	Note                  string
	CreatedAt             time.Time
	UpdatedAt             time.Time
	DeletedAt             *time.Time
	CreatedBy             string
	UpdatedBy             string
}

type SalesOrderLine struct {
	SalesOrderLineID  string
	TenantID          string
	SalesOrderID      string
	QuotationLineID   string
	LineNo            int
	ItemID            string
	ProductID         string
	UnitID            string
	Description       string
	Quantity          float64
	DeliveredQuantity float64
	InvoicedQuantity  float64
	UnitPrice         float64
	DiscountRate      float64
	DiscountAmount    float64
	VATRate           float64
	VATAmount         float64
	LineTotal         float64
	Status            SalesLineStatus
	CreatedAt         time.Time
	UpdatedAt         time.Time
	DeletedAt         *time.Time
	CreatedBy         string
	UpdatedBy         string
}

type SalesDelivery struct {
	DeliveryID   string
	TenantID     string
	DeliveryNo   string
	SalesOrderID string
	CustomerID   string
	PartyID      string
	WarehouseID  string
	DocumentDate time.Time
	DeliveryDate *time.Time
	Status       SalesDeliveryStatus
	Note         string
	CreatedAt    time.Time
	UpdatedAt    time.Time
	DeletedAt    *time.Time
	CreatedBy    string
	UpdatedBy    string
}

type SalesDeliveryLine struct {
	DeliveryLineID   string
	TenantID         string
	DeliveryID       string
	SalesOrderLineID string
	LineNo           int
	ItemID           string
	ProductID        string
	UnitID           string
	Description      string
	Quantity         float64
	Status           SalesLineStatus
	CreatedAt        time.Time
	UpdatedAt        time.Time
	DeletedAt        *time.Time
	CreatedBy        string
	UpdatedBy        string
}

type SalesInvoice struct {
	SalesInvoiceID  string
	TenantID        string
	SalesInvoiceNo  string
	SalesOrderID    string
	DeliveryID      string
	CustomerID      string
	PartyID         string
	InvoiceType     SalesInvoiceType
	DocumentDate    time.Time
	DueDate         *time.Time
	CurrencyCode    string
	ExchangeRate    float64
	SubtotalAmount  float64
	DiscountAmount  float64
	VATAmount       float64
	TotalAmount     float64
	PaidAmount      float64
	RemainingAmount float64
	EDocumentStatus EDocumentStatus
	Status          SalesInvoiceStatus
	Note            string
	CreatedAt       time.Time
	UpdatedAt       time.Time
	DeletedAt       *time.Time
	CreatedBy       string
	UpdatedBy       string
}

type SalesInvoiceLine struct {
	SalesInvoiceLineID string
	TenantID           string
	SalesInvoiceID     string
	SalesOrderLineID   string
	DeliveryLineID     string
	LineNo             int
	ItemID             string
	ProductID          string
	UnitID             string
	Description        string
	Quantity           float64
	UnitPrice          float64
	DiscountRate       float64
	DiscountAmount     float64
	VATRate            float64
	VATAmount          float64
	LineTotal          float64
	Status             SalesLineStatus
	CreatedAt          time.Time
	UpdatedAt          time.Time
	DeletedAt          *time.Time
	CreatedBy          string
	UpdatedBy          string
}

type CreateSalesQuotationInput struct {
	TenantID       string
	QuotationNo    string
	CustomerID     string
	PartyID        string
	DocumentDate   time.Time
	ValidUntil     *time.Time
	CurrencyCode   string
	ExchangeRate   float64
	SubtotalAmount float64
	DiscountAmount float64
	VATAmount      float64
	TotalAmount    float64
	Note           string
	CreatedBy      string
}

type CreateSalesQuotationLineInput struct {
	TenantID       string
	QuotationID    string
	LineNo         int
	ItemID         string
	ProductID      string
	UnitID         string
	Description    string
	Quantity       float64
	UnitPrice      float64
	DiscountRate   float64
	DiscountAmount float64
	VATRate        float64
	VATAmount      float64
	LineTotal      float64
	CreatedBy      string
}

type CreateSalesOrderInput struct {
	TenantID              string
	SalesOrderNo          string
	QuotationID           string
	CustomerID            string
	PartyID               string
	DocumentDate          time.Time
	RequestedDeliveryDate *time.Time
	CurrencyCode          string
	ExchangeRate          float64
	SubtotalAmount        float64
	DiscountAmount        float64
	VATAmount             float64
	TotalAmount           float64
	Note                  string
	CreatedBy             string
}

type CreateSalesOrderLineInput struct {
	TenantID          string
	SalesOrderID      string
	QuotationLineID   string
	LineNo            int
	ItemID            string
	ProductID         string
	UnitID            string
	Description       string
	Quantity          float64
	DeliveredQuantity float64
	InvoicedQuantity  float64
	UnitPrice         float64
	DiscountRate      float64
	DiscountAmount    float64
	VATRate           float64
	VATAmount         float64
	LineTotal         float64
	CreatedBy         string
}

type CreateSalesDeliveryInput struct {
	TenantID     string
	DeliveryNo   string
	SalesOrderID string
	CustomerID   string
	PartyID      string
	WarehouseID  string
	DocumentDate time.Time
	DeliveryDate *time.Time
	Note         string
	CreatedBy    string
}

type CreateSalesDeliveryLineInput struct {
	TenantID         string
	DeliveryID       string
	SalesOrderLineID string
	LineNo           int
	ItemID           string
	ProductID        string
	UnitID           string
	Description      string
	Quantity         float64
	CreatedBy        string
}

type CreateSalesInvoiceInput struct {
	TenantID        string
	SalesInvoiceNo  string
	SalesOrderID    string
	DeliveryID      string
	CustomerID      string
	PartyID         string
	InvoiceType     SalesInvoiceType
	DocumentDate    time.Time
	DueDate         *time.Time
	CurrencyCode    string
	ExchangeRate    float64
	SubtotalAmount  float64
	DiscountAmount  float64
	VATAmount       float64
	TotalAmount     float64
	PaidAmount      float64
	RemainingAmount float64
	EDocumentStatus EDocumentStatus
	Note            string
	CreatedBy       string
}

type CreateSalesInvoiceLineInput struct {
	TenantID         string
	SalesInvoiceID   string
	SalesOrderLineID string
	DeliveryLineID   string
	LineNo           int
	ItemID           string
	ProductID        string
	UnitID           string
	Description      string
	Quantity         float64
	UnitPrice        float64
	DiscountRate     float64
	DiscountAmount   float64
	VATRate          float64
	VATAmount        float64
	LineTotal        float64
	CreatedBy        string
}

func ValidateCreateSalesQuotationInput(input CreateSalesQuotationInput) error {
	if err := validateHeaderTenantCustomerParty(input.TenantID, input.CustomerID, input.PartyID); err != nil {
		return err
	}
	if strings.TrimSpace(input.QuotationNo) == "" {
		return ErrQuotationNoRequired
	}
	return validateAmountSummary(input.ExchangeRate, input.SubtotalAmount, input.DiscountAmount, input.VATAmount, input.TotalAmount)
}

func ValidateCreateSalesQuotationLineInput(input CreateSalesQuotationLineInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}
	if strings.TrimSpace(input.QuotationID) == "" {
		return ErrQuotationIDRequired
	}
	return validateSalesLine(input.LineNo, input.ItemID, input.UnitID, input.Quantity, input.UnitPrice, input.DiscountRate, input.DiscountAmount, input.VATRate, input.VATAmount, input.LineTotal)
}

func ValidateCreateSalesOrderInput(input CreateSalesOrderInput) error {
	if err := validateHeaderTenantCustomerParty(input.TenantID, input.CustomerID, input.PartyID); err != nil {
		return err
	}
	if strings.TrimSpace(input.SalesOrderNo) == "" {
		return ErrSalesOrderNoRequired
	}
	return validateAmountSummary(input.ExchangeRate, input.SubtotalAmount, input.DiscountAmount, input.VATAmount, input.TotalAmount)
}

func ValidateCreateSalesOrderLineInput(input CreateSalesOrderLineInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}
	if strings.TrimSpace(input.SalesOrderID) == "" {
		return ErrSalesOrderIDRequired
	}
	if err := validateSalesLine(input.LineNo, input.ItemID, input.UnitID, input.Quantity, input.UnitPrice, input.DiscountRate, input.DiscountAmount, input.VATRate, input.VATAmount, input.LineTotal); err != nil {
		return err
	}
	if input.DeliveredQuantity < 0 || input.InvoicedQuantity < 0 || input.DeliveredQuantity > input.Quantity || input.InvoicedQuantity > input.Quantity {
		return ErrQuantityRangeInvalid
	}
	return nil
}

func ValidateCreateSalesDeliveryInput(input CreateSalesDeliveryInput) error {
	if err := validateHeaderTenantCustomerParty(input.TenantID, input.CustomerID, input.PartyID); err != nil {
		return err
	}
	if strings.TrimSpace(input.DeliveryNo) == "" {
		return ErrDeliveryNoRequired
	}
	if strings.TrimSpace(input.WarehouseID) == "" {
		return ErrWarehouseIDRequired
	}
	return nil
}

func ValidateCreateSalesDeliveryLineInput(input CreateSalesDeliveryLineInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}
	if strings.TrimSpace(input.DeliveryID) == "" {
		return ErrDeliveryIDRequired
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

func ValidateCreateSalesInvoiceInput(input CreateSalesInvoiceInput) error {
	if err := validateHeaderTenantCustomerParty(input.TenantID, input.CustomerID, input.PartyID); err != nil {
		return err
	}
	if strings.TrimSpace(input.SalesInvoiceNo) == "" {
		return ErrSalesInvoiceNoRequired
	}

	invoiceType := input.InvoiceType
	if strings.TrimSpace(string(invoiceType)) == "" {
		invoiceType = SalesInvoiceTypeSales
	}
	switch invoiceType {
	case SalesInvoiceTypeSales, SalesInvoiceTypeReturn, SalesInvoiceTypeProforma:
	default:
		return ErrInvoiceTypeInvalid
	}

	eDocumentStatus := input.EDocumentStatus
	if strings.TrimSpace(string(eDocumentStatus)) == "" {
		eDocumentStatus = EDocumentStatusNone
	}
	switch eDocumentStatus {
	case EDocumentStatusNone, EDocumentStatusPending, EDocumentStatusSent, EDocumentStatusAccepted, EDocumentStatusRejected, EDocumentStatusCancelled:
	default:
		return ErrEDocumentStatusInvalid
	}

	if err := validateAmountSummary(input.ExchangeRate, input.SubtotalAmount, input.DiscountAmount, input.VATAmount, input.TotalAmount); err != nil {
		return err
	}

	if input.PaidAmount < 0 || input.RemainingAmount < 0 || input.PaidAmount > input.TotalAmount {
		return ErrAmountInvalid
	}

	return nil
}

func ValidateCreateSalesInvoiceLineInput(input CreateSalesInvoiceLineInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}
	if strings.TrimSpace(input.SalesInvoiceID) == "" {
		return ErrSalesInvoiceIDRequired
	}
	return validateSalesLine(input.LineNo, input.ItemID, input.UnitID, input.Quantity, input.UnitPrice, input.DiscountRate, input.DiscountAmount, input.VATRate, input.VATAmount, input.LineTotal)
}

func validateHeaderTenantCustomerParty(tenantID string, customerID string, partyID string) error {
	if strings.TrimSpace(tenantID) == "" {
		return ErrTenantRequired
	}
	if strings.TrimSpace(customerID) == "" {
		return ErrCustomerIDRequired
	}
	if strings.TrimSpace(partyID) == "" {
		return ErrPartyIDRequired
	}
	return nil
}

func validateAmountSummary(exchangeRate float64, subtotalAmount float64, discountAmount float64, vatAmount float64, totalAmount float64) error {
	if exchangeRate <= 0 {
		return ErrAmountInvalid
	}
	if subtotalAmount < 0 || discountAmount < 0 || vatAmount < 0 || totalAmount < 0 {
		return ErrAmountInvalid
	}
	return nil
}

func validateSalesLine(lineNo int, itemID string, unitID string, quantity float64, unitPrice float64, discountRate float64, discountAmount float64, vatRate float64, vatAmount float64, lineTotal float64) error {
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
	if unitPrice < 0 || discountAmount < 0 || vatAmount < 0 || lineTotal < 0 {
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
