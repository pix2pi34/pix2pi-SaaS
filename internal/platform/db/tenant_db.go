package db

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

type TenantDB struct {
	db           *gorm.DB
	tenantID     string
	tenantColumn string
}

func FromCtx(c *fiber.Ctx, base *gorm.DB) *TenantDB {
	tid := fmt.Sprint(c.Locals("tenant_id"))

	return &TenantDB{
		db:           base,
		tenantID:     strings.TrimSpace(tid),
		tenantColumn: DefaultTenantQueryColumn,
	}
}

func (t *TenantDB) WithTenantColumn(column string) *TenantDB {
	if t == nil {
		return nil
	}

	return &TenantDB{
		db:           t.db,
		tenantID:     t.tenantID,
		tenantColumn: strings.TrimSpace(column),
	}
}

func (t *TenantDB) Scope() *gorm.DB {
	if t == nil {
		return nil
	}

	if t.db == nil {
		return nil
	}

	id64, err := strconv.ParseUint(strings.TrimSpace(t.tenantID), 10, 64)
	if err != nil || id64 == 0 {
		return t.db.Where("1 = 0")
	}

	scoped, err := ApplyTenantQueryScopeByID(t.db, uint(id64), t.tenantColumn)
	if err != nil {
		return t.db.Where("1 = 0")
	}

	return scoped
}
