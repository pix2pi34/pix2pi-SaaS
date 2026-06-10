package db

import (
	"fmt"
	"regexp"
	"strings"

	"gorm.io/gorm"
)

var sqlIdentifierRe = regexp.MustCompile(`^[a-zA-Z_][a-zA-Z0-9_]*$`)

func ValidateSQLIdentifier(name string) error {
	name = strings.TrimSpace(name)
	if name == "" {
		return fmt.Errorf("sql identifier bos olamaz")
	}
	if !sqlIdentifierRe.MatchString(name) {
		return fmt.Errorf("gecersiz sql identifier: %s", name)
	}
	return nil
}

func DefaultTenantRLSPolicyName(tableName string) string {
	return "rls_" + strings.TrimSpace(tableName) + "_tenant_isolation"
}

func BuildTenantRLSPolicyStatements(
	tableName string,
	tenantColumn string,
	policyName string,
) ([]string, error) {
	tableName = strings.TrimSpace(tableName)
	tenantColumn = strings.TrimSpace(tenantColumn)
	policyName = strings.TrimSpace(policyName)

	if err := ValidateSQLIdentifier(tableName); err != nil {
		return nil, err
	}
	if err := ValidateSQLIdentifier(tenantColumn); err != nil {
		return nil, err
	}

	if policyName == "" {
		policyName = DefaultTenantRLSPolicyName(tableName)
	}
	if err := ValidateSQLIdentifier(policyName); err != nil {
		return nil, err
	}

	statements := []string{
		fmt.Sprintf(`ALTER TABLE %s ENABLE ROW LEVEL SECURITY`, tableName),
		fmt.Sprintf(`ALTER TABLE %s FORCE ROW LEVEL SECURITY`, tableName),
		fmt.Sprintf(`DROP POLICY IF EXISTS %s ON %s`, policyName, tableName),
		fmt.Sprintf(
			`CREATE POLICY %s ON %s USING (%s::text = current_setting('app.tenant_id', true)) WITH CHECK (%s::text = current_setting('app.tenant_id', true))`,
			policyName,
			tableName,
			tenantColumn,
			tenantColumn,
		),
	}

	return statements, nil
}

func ApplyTenantRLSPolicy(
	tx *gorm.DB,
	tableName string,
	tenantColumn string,
	policyName string,
) error {
	if tx == nil {
		return fmt.Errorf("tx nil olamaz")
	}

	statements, err := BuildTenantRLSPolicyStatements(
		tableName,
		tenantColumn,
		policyName,
	)
	if err != nil {
		return err
	}

	for _, stmt := range statements {
		if err := tx.Exec(stmt).Error; err != nil {
			return err
		}
	}

	return nil
}
