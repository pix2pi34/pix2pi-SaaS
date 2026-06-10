package productcatalog

import "errors"

var (
	ErrTenantRequired        = errors.New("tenant_id zorunlu")
	ErrUnitCodeRequired      = errors.New("unit_code zorunlu")
	ErrUnitNameRequired      = errors.New("unit_name zorunlu")
	ErrUnitTypeInvalid       = errors.New("unit_type gecersiz")
	ErrUnitNotFound          = errors.New("unit bulunamadi")
	ErrCategoryCodeRequired  = errors.New("category_code zorunlu")
	ErrCategoryNameRequired  = errors.New("category_name zorunlu")
	ErrCategoryNotFound      = errors.New("category bulunamadi")
	ErrItemCodeRequired      = errors.New("item_code zorunlu")
	ErrItemNameRequired      = errors.New("item_name zorunlu")
	ErrItemTypeInvalid       = errors.New("item_type gecersiz")
	ErrItemNotFound          = errors.New("item bulunamadi")
	ErrBaseUnitIDRequired    = errors.New("base_unit_id zorunlu")
	ErrVATRateInvalid        = errors.New("vat_rate gecersiz")
	ErrProductCodeRequired   = errors.New("product_code zorunlu")
	ErrProductNameRequired   = errors.New("product_name zorunlu")
	ErrProductNotFound       = errors.New("product bulunamadi")
	ErrItemIDRequired        = errors.New("item_id zorunlu")
	ErrDecimalPrecisionRange = errors.New("decimal_precision 0 ile 6 arasinda olmali")
)
