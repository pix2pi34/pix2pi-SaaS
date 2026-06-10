package db

import (
	"fmt"
	"strconv"

	"gorm.io/gorm"
)

func TenantSchemaName(tenantID uint) (string, error) {
	if tenantID == 0 {
		return "", fmt.Errorf("tenant id must be greater than zero")
	}

	schema := fmt.Sprintf("tenant_%d", tenantID)

	if err := ValidateTenantSchema(schema); err != nil {
		return "", err
	}

	return schema, nil
}

func BuildTenantSessionStatements(tenantID uint) ([]string, string, error) {
	schema, err := TenantSchemaName(tenantID)
	if err != nil {
		return nil, "", err
	}

	tenantIDStr := strconv.FormatUint(uint64(tenantID), 10)

	statements := []string{
		fmt.Sprintf(
			"SELECT set_config('app.tenant_id', '%s', true)",
			tenantIDStr,
		),
		fmt.Sprintf(
			"SELECT set_config('app.tenant_schema', '%s', true)",
			schema,
		),
		fmt.Sprintf(
			`SET LOCAL search_path TO "%s", public`,
			schema,
		),
	}

	return statements, schema, nil
}

func BindTenantSession(tx *gorm.DB, tenantID uint) (*gorm.DB, error) {
	if tx == nil {
		return nil, fmt.Errorf("tx cannot be nil")
	}

	statements, schema, err := BuildTenantSessionStatements(tenantID)
	if err != nil {
		return nil, err
	}

	boundTx := tx.Set("tenant_id", tenantID)
	boundTx = boundTx.Set("tenant_schema", schema)

	for _, stmt := range statements {
		if err := boundTx.Exec(stmt).Error; err != nil {
			return nil, err
		}
	}

	return boundTx, nil
}
