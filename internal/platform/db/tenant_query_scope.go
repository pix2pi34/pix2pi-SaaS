package db

import (
	"fmt"
	"strings"

	"gorm.io/gorm"
)

const DefaultTenantQueryColumn = "tenant_id"

type TenantQueryScopeSpec struct {
	TenantID    uint
	TenantColumn string
	WhereClause string
	Args        []any
}

func BuildTenantQueryScopeSpec(
	tenantID uint,
	tenantColumn string,
) (TenantQueryScopeSpec, error) {
	if tenantID == 0 {
		return TenantQueryScopeSpec{}, fmt.Errorf("tenant id must be greater than zero")
	}

	tenantColumn = strings.TrimSpace(tenantColumn)
	if tenantColumn == "" {
		tenantColumn = DefaultTenantQueryColumn
	}

	if err := ValidateSQLIdentifier(tenantColumn); err != nil {
		return TenantQueryScopeSpec{}, err
	}

	return TenantQueryScopeSpec{
		TenantID:     tenantID,
		TenantColumn: tenantColumn,
		WhereClause:  fmt.Sprintf("%s = ?", tenantColumn),
		Args:         []any{tenantID},
	}, nil
}

func ApplyTenantQueryScope(
	db *gorm.DB,
	spec TenantQueryScopeSpec,
) (*gorm.DB, error) {
	if db == nil {
		return nil, fmt.Errorf("db nil olamaz")
	}

	if spec.WhereClause == "" || len(spec.Args) == 0 {
		normalized, err := BuildTenantQueryScopeSpec(spec.TenantID, spec.TenantColumn)
		if err != nil {
			return nil, err
		}
		spec = normalized
	}

	return db.Where(spec.WhereClause, spec.Args...), nil
}

func ApplyTenantQueryScopeByID(
	db *gorm.DB,
	tenantID uint,
	tenantColumn string,
) (*gorm.DB, error) {
	spec, err := BuildTenantQueryScopeSpec(tenantID, tenantColumn)
	if err != nil {
		return nil, err
	}

	return ApplyTenantQueryScope(db, spec)
}
