package db

import (
	"strconv"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

type TenantDB struct {
	db       *gorm.DB
	tenantID string
}

func FromCtx(c *fiber.Ctx, base *gorm.DB) *TenantDB {
	tid := c.Locals("tenant_id")
	tidStr, _ := tid.(string)

	return &TenantDB{
		db:       base,
		tenantID: tidStr,
	}
}

func (t *TenantDB) Scope() *gorm.DB {
	id, _ := strconv.Atoi(t.tenantID)
	return t.db.Where("tenant_id = ?", id)
}
