package db

import (
	"fmt"
	"strconv"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

// TenantIDFromCtx: fiber locals'tan tenant_id okur (string/int/uint toleransli)
func TenantIDFromCtx(c *fiber.Ctx) (uint, error) {
	v := c.Locals("tenant_id")
	if v == nil {
		return 0, fmt.Errorf("tenant_id missing in locals")
	}

	switch t := v.(type) {
	case uint:
		return t, nil
	case int:
		if t < 0 {
			return 0, fmt.Errorf("invalid tenant_id: %d", t)
		}
		return uint(t), nil
	case int64:
		if t < 0 {
			return 0, fmt.Errorf("invalid tenant_id: %d", t)
		}
		return uint(t), nil
	case string:
		u64, err := strconv.ParseUint(t, 10, 64)
		if err != nil {
			return 0, fmt.Errorf("invalid tenant_id string: %q", t)
		}
		return uint(u64), nil
	default:
		return 0, fmt.Errorf("unsupported tenant_id type: %T", v)
	}
}

// WithTenantTx: tenant_id ile transaction calistirir.
// Not: Burada "tenant filter" uygulamak, repo katmaninda scope ile yapilacak (L26/L27).
func WithTenantTx(c *fiber.Ctx, db *gorm.DB, fn func(tx *gorm.DB, tenantID uint) error) error {
	tenantID, err := TenantIDFromCtx(c)
	if err != nil {
		return err
	}
	return db.Transaction(func(tx *gorm.DB) error {
		// tenant id'yi tx contextine koyuyoruz (istersen repo buradan okuyabilir)
		tx = tx.Set("tenant_id", tenantID)
		return fn(tx, tenantID)
	})
}
