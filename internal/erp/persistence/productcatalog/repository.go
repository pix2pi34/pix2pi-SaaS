package productcatalog

import "context"

type UnitRepository interface {
	CreateUnit(ctx context.Context, input CreateUnitInput) (Unit, error)
	GetUnitByID(ctx context.Context, tenantID string, unitID string) (Unit, error)
	ListUnits(ctx context.Context, tenantID string, filter ListUnitsFilter) ([]Unit, error)
}

type ListUnitsFilter struct {
	Query  string
	Status CatalogStatus
	Limit  int
	Offset int
}

type CategoryRepository interface {
	CreateCategory(ctx context.Context, input CreateCategoryInput) (ProductCategory, error)
	GetCategoryByID(ctx context.Context, tenantID string, categoryID string) (ProductCategory, error)
	ListCategories(ctx context.Context, tenantID string, filter ListCategoriesFilter) ([]ProductCategory, error)
}

type ListCategoriesFilter struct {
	ParentCategoryID string
	Query            string
	Status           CatalogStatus
	Limit            int
	Offset           int
}

type ItemRepository interface {
	CreateItem(ctx context.Context, input CreateItemInput) (Item, error)
	GetItemByID(ctx context.Context, tenantID string, itemID string) (Item, error)
	ListItems(ctx context.Context, tenantID string, filter ListItemsFilter) ([]Item, error)
}

type ListItemsFilter struct {
	CategoryID string
	Query      string
	Status     CatalogStatus
	Limit      int
	Offset     int
}

type ProductRepository interface {
	CreateProduct(ctx context.Context, input CreateProductInput) (Product, error)
	GetProductByID(ctx context.Context, tenantID string, productID string) (Product, error)
	ListProducts(ctx context.Context, tenantID string, filter ListProductsFilter) ([]Product, error)
}

type ListProductsFilter struct {
	Query        string
	Status       CatalogStatus
	VisiblePOS   *bool
	VisibleWeb   *bool
	SellableOnly bool
	Limit        int
	Offset       int
}
