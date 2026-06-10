package procurement

import "errors"

var (
	ErrTenantRequired             = errors.New("tenant_id zorunlu")
	ErrVendorIDRequired           = errors.New("vendor_id zorunlu")
	ErrPartyIDRequired            = errors.New("party_id zorunlu")
	ErrWarehouseIDRequired        = errors.New("warehouse_id zorunlu")
	ErrItemIDRequired             = errors.New("item_id zorunlu")
	ErrUnitIDRequired             = errors.New("unit_id zorunlu")
	ErrPurchaseOrderIDRequired    = errors.New("purchase_order_id zorunlu")
	ErrPurchaseReceiptIDRequired  = errors.New("purchase_receipt_id zorunlu")
	ErrPurchaseInvoiceIDRequired  = errors.New("purchase_invoice_id zorunlu")
	ErrPurchaseOrderNoRequired    = errors.New("purchase_order_no zorunlu")
	ErrPurchaseReceiptNoRequired  = errors.New("purchase_receipt_no zorunlu")
	ErrPurchaseInvoiceNoRequired  = errors.New("purchase_invoice_no zorunlu")
	ErrLineNoInvalid              = errors.New("line_no gecersiz")
	ErrQuantityMustBePositive     = errors.New("quantity sifirdan buyuk olmali")
	ErrQuantityRangeInvalid       = errors.New("quantity araligi gecersiz")
	ErrAmountInvalid              = errors.New("amount gecersiz")
	ErrDiscountRateInvalid        = errors.New("discount_rate gecersiz")
	ErrVATRateInvalid             = errors.New("vat_rate gecersiz")
	ErrPurchaseInvoiceTypeInvalid = errors.New("purchase invoice_type gecersiz")
	ErrPurchaseEDocumentInvalid   = errors.New("purchase e_document_status gecersiz")
	ErrPurchaseOrderNotFound      = errors.New("purchase order bulunamadi")
	ErrPurchaseReceiptNotFound    = errors.New("purchase receipt bulunamadi")
	ErrPurchaseInvoiceNotFound    = errors.New("purchase invoice bulunamadi")
)
