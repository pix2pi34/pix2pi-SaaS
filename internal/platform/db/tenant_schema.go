package db

import (
	"database/sql"
	"fmt"
	"regexp"
)

var tenantSchemaRe = regexp.MustCompile(`^tenant_[0-9]+$`)

func ValidateTenantSchema(schema string) error {
	if !tenantSchemaRe.MatchString(schema) {
		return fmt.Errorf("invalid tenant schema: %s", schema)
	}
	return nil
}

func EnsureTenantSchema(conn *sql.DB, schema string) error {
	if err := ValidateTenantSchema(schema); err != nil {
		return err
	}
	_, err := conn.Exec(`CREATE SCHEMA IF NOT EXISTS ` + schema)
	return err
}
