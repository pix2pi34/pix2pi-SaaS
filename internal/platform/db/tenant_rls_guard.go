package db

import (
	"fmt"
	"strings"
)

const TenantSessionSettingKey = "app.tenant_id"

func BuildTenantRLSCheckExpression(
	tenantColumn string,
) (string, error) {
	tenantColumn = strings.TrimSpace(tenantColumn)

	if err := ValidateSQLIdentifier(tenantColumn); err != nil {
		return "", err
	}

	return fmt.Sprintf(
		"%s::text = current_setting('%s', true)",
		tenantColumn,
		TenantSessionSettingKey,
	), nil
}

func ValidateTenantRLSGuardStatements(
	statements []string,
	tableName string,
	tenantColumn string,
	policyName string,
) error {
	if len(statements) != 4 {
		return fmt.Errorf("rls statement count invalid: %d", len(statements))
	}

	tableName = strings.TrimSpace(tableName)
	tenantColumn = strings.TrimSpace(tenantColumn)
	policyName = strings.TrimSpace(policyName)

	if err := ValidateSQLIdentifier(tableName); err != nil {
		return err
	}
	if err := ValidateSQLIdentifier(tenantColumn); err != nil {
		return err
	}
	if policyName == "" {
		policyName = DefaultTenantRLSPolicyName(tableName)
	}
	if err := ValidateSQLIdentifier(policyName); err != nil {
		return err
	}

	expectedExpr, err := BuildTenantRLSCheckExpression(tenantColumn)
	if err != nil {
		return err
	}

	expected0 := fmt.Sprintf("ALTER TABLE %s ENABLE ROW LEVEL SECURITY", tableName)
	expected1 := fmt.Sprintf("ALTER TABLE %s FORCE ROW LEVEL SECURITY", tableName)
	expected2 := fmt.Sprintf("DROP POLICY IF EXISTS %s ON %s", policyName, tableName)
	expected3Prefix := fmt.Sprintf("CREATE POLICY %s ON %s", policyName, tableName)

	if strings.TrimSpace(statements[0]) != expected0 {
		return fmt.Errorf("rls enable statement invalid")
	}
	if strings.TrimSpace(statements[1]) != expected1 {
		return fmt.Errorf("rls force statement invalid")
	}
	if strings.TrimSpace(statements[2]) != expected2 {
		return fmt.Errorf("rls drop policy statement invalid")
	}
	if !strings.Contains(statements[3], expected3Prefix) {
		return fmt.Errorf("rls create policy statement invalid")
	}

	if strings.Count(statements[3], expectedExpr) < 2 {
		return fmt.Errorf("tenant session guard missing in create policy")
	}

	return nil
}
