package inventory

import "errors"

var (
	ErrTenantRequired           = errors.New("tenant_id zorunlu")
	ErrWarehouseCodeRequired    = errors.New("warehouse_code zorunlu")
	ErrWarehouseNameRequired    = errors.New("warehouse_name zorunlu")
	ErrWarehouseTypeInvalid     = errors.New("warehouse_type gecersiz")
	ErrMovementNoRequired       = errors.New("movement_no zorunlu")
	ErrMovementTypeInvalid      = errors.New("movement_type gecersiz")
	ErrMovementDirectionInvalid = errors.New("movement_direction gecersiz")
	ErrWarehouseIDRequired      = errors.New("warehouse_id zorunlu")
	ErrItemIDRequired           = errors.New("item_id zorunlu")
	ErrUnitIDRequired           = errors.New("unit_id zorunlu")
	ErrQuantityMustBePositive   = errors.New("quantity sifirdan buyuk olmali")
	ErrCostInvalid              = errors.New("cost negatif olamaz")
	ErrBalanceQuantityInvalid   = errors.New("balance quantity gecersiz")
	ErrWarehouseNotFound        = errors.New("warehouse bulunamadi")
	ErrStockMovementNotFound    = errors.New("stock movement bulunamadi")
	ErrWarehouseBalanceNotFound = errors.New("warehouse balance bulunamadi")
)
