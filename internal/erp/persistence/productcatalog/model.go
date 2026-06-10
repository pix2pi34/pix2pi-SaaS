package productcatalog

import (
	"strings"
	"time"
)

type CatalogStatus string

const (
	CatalogStatusActive  CatalogStatus = "active"
	CatalogStatusPassive CatalogStatus = "passive"
	CatalogStatusBlocked CatalogStatus = "blocked"
	CatalogStatusDeleted CatalogStatus = "deleted"
)

type UnitType string

const (
	UnitTypeQuantity UnitType = "quantity"
	UnitTypeWeight   UnitType = "weight"
	UnitTypeVolume   UnitType = "volume"
	UnitTypeLength   UnitType = "length"
	UnitTypeTime     UnitType = "time"
	UnitTypePackage  UnitType = "package"
)

type ItemType string

const (
	ItemTypeStock       ItemType = "stock"
	ItemTypeService     ItemType = "service"
	ItemTypeRawMaterial ItemType = "raw_material"
	ItemTypeExpense     ItemType = "expense"
	ItemTypeAsset       ItemType = "asset"
	ItemTypePackage     ItemType = "package"
)

type Unit struct {
	UnitID           string
	TenantID         string
	UnitCode         string
	UnitName         string
	UnitType         UnitType
	DecimalPrecision int
	IsBaseUnit       bool
	Status           CatalogStatus
	CreatedAt        time.Time
	UpdatedAt        time.Time
	DeletedAt        *time.Time
	CreatedBy        string
	UpdatedBy        string
}

type ProductCategory struct {
	CategoryID       string
	TenantID         string
	ParentCategoryID string
	CategoryCode     string
	CategoryName     string
	Description      string
	SortOrder        int
	Status           CatalogStatus
	CreatedAt        time.Time
	UpdatedAt        time.Time
	DeletedAt        *time.Time
	CreatedBy        string
	UpdatedBy        string
}

type Item struct {
	ItemID             string
	TenantID           string
	ItemCode           string
	ItemName           string
	ItemType           ItemType
	CategoryID         string
	BaseUnitID         string
	Barcode            string
	SKU                string
	VATRate            float64
	IsInventoryTracked bool
	IsSalesAllowed     bool
	IsPurchaseAllowed  bool
	Status             CatalogStatus
	CreatedAt          time.Time
	UpdatedAt          time.Time
	DeletedAt          *time.Time
	CreatedBy          string
	UpdatedBy          string
}

type Product struct {
	ProductID          string
	TenantID           string
	ItemID             string
	ProductCode        string
	ProductName        string
	ShortDescription   string
	LongDescription    string
	DefaultSalesUnitID string
	IsSellable         bool
	IsVisiblePOS       bool
	IsVisibleWeb       bool
	Status             CatalogStatus
	CreatedAt          time.Time
	UpdatedAt          time.Time
	DeletedAt          *time.Time
	CreatedBy          string
	UpdatedBy          string
}

type CreateUnitInput struct {
	TenantID         string
	UnitCode         string
	UnitName         string
	UnitType         UnitType
	DecimalPrecision int
	IsBaseUnit       bool
	CreatedBy        string
}

type CreateCategoryInput struct {
	TenantID         string
	ParentCategoryID string
	CategoryCode     string
	CategoryName     string
	Description      string
	SortOrder        int
	CreatedBy        string
}

type CreateItemInput struct {
	TenantID           string
	ItemCode           string
	ItemName           string
	ItemType           ItemType
	CategoryID         string
	BaseUnitID         string
	Barcode            string
	SKU                string
	VATRate            float64
	IsInventoryTracked bool
	IsSalesAllowed     bool
	IsPurchaseAllowed  bool
	CreatedBy          string
}

type CreateProductInput struct {
	TenantID           string
	ItemID             string
	ProductCode        string
	ProductName        string
	ShortDescription   string
	LongDescription    string
	DefaultSalesUnitID string
	IsSellable         bool
	IsVisiblePOS       bool
	IsVisibleWeb       bool
	CreatedBy          string
}

func ValidateCreateUnitInput(input CreateUnitInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.UnitCode) == "" {
		return ErrUnitCodeRequired
	}

	if strings.TrimSpace(input.UnitName) == "" {
		return ErrUnitNameRequired
	}

	unitType := input.UnitType
	if strings.TrimSpace(string(unitType)) == "" {
		unitType = UnitTypeQuantity
	}

	switch unitType {
	case UnitTypeQuantity, UnitTypeWeight, UnitTypeVolume, UnitTypeLength, UnitTypeTime, UnitTypePackage:
	default:
		return ErrUnitTypeInvalid
	}

	if input.DecimalPrecision < 0 || input.DecimalPrecision > 6 {
		return ErrDecimalPrecisionRange
	}

	return nil
}

func ValidateCreateCategoryInput(input CreateCategoryInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.CategoryCode) == "" {
		return ErrCategoryCodeRequired
	}

	if strings.TrimSpace(input.CategoryName) == "" {
		return ErrCategoryNameRequired
	}

	return nil
}

func ValidateCreateItemInput(input CreateItemInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.ItemCode) == "" {
		return ErrItemCodeRequired
	}

	if strings.TrimSpace(input.ItemName) == "" {
		return ErrItemNameRequired
	}

	itemType := input.ItemType
	if strings.TrimSpace(string(itemType)) == "" {
		itemType = ItemTypeStock
	}

	switch itemType {
	case ItemTypeStock, ItemTypeService, ItemTypeRawMaterial, ItemTypeExpense, ItemTypeAsset, ItemTypePackage:
	default:
		return ErrItemTypeInvalid
	}

	if strings.TrimSpace(input.BaseUnitID) == "" {
		return ErrBaseUnitIDRequired
	}

	if input.VATRate < 0 || input.VATRate > 100 {
		return ErrVATRateInvalid
	}

	return nil
}

func ValidateCreateProductInput(input CreateProductInput) error {
	if strings.TrimSpace(input.TenantID) == "" {
		return ErrTenantRequired
	}

	if strings.TrimSpace(input.ItemID) == "" {
		return ErrItemIDRequired
	}

	if strings.TrimSpace(input.ProductCode) == "" {
		return ErrProductCodeRequired
	}

	if strings.TrimSpace(input.ProductName) == "" {
		return ErrProductNameRequired
	}

	return nil
}
