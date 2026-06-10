package readmodel

import (
	"fmt"
	"strings"
)

type TenantQueryTarget struct {
	ProjectionName string
	TableName      string
	FullTableName  string
	TenantColumn   string
}

func (t TenantQueryTarget) Validate() error {
	if strings.TrimSpace(t.ProjectionName) == "" {
		return fmt.Errorf("readmodel: empty projection name")
	}
	if strings.TrimSpace(t.TableName) == "" {
		return fmt.Errorf("readmodel: empty table name")
	}
	if strings.TrimSpace(t.FullTableName) == "" {
		return fmt.Errorf("readmodel: empty full table name")
	}
	if strings.TrimSpace(t.TenantColumn) == "" {
		return fmt.Errorf("readmodel: empty tenant column")
	}
	return nil
}

type TenantQueryAccessPlan struct {
	TenantID      string
	Target        TenantQueryTarget
	WhereClause   string
	Args          []any
	GuardRequired bool
}

func (p TenantQueryAccessPlan) Validate() error {
	if strings.TrimSpace(p.TenantID) == "" {
		return fmt.Errorf("readmodel: empty tenant id")
	}
	if err := p.Target.Validate(); err != nil {
		return err
	}
	if strings.TrimSpace(p.WhereClause) == "" {
		return fmt.Errorf("readmodel: empty where clause")
	}
	if len(p.Args) != 1 {
		return fmt.Errorf("readmodel: invalid args")
	}
	if !p.GuardRequired {
		return fmt.Errorf("readmodel: tenant guard must be required")
	}
	return nil
}

func BuildTenantQueryAccessPlan(
	tenantID string,
	target TenantQueryTarget,
) (TenantQueryAccessPlan, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return TenantQueryAccessPlan{}, fmt.Errorf("readmodel: empty tenant id")
	}

	if err := target.Validate(); err != nil {
		return TenantQueryAccessPlan{}, err
	}

	return TenantQueryAccessPlan{
		TenantID:      tenantID,
		Target:        target,
		WhereClause:   fmt.Sprintf("%s = ?", target.TenantColumn),
		Args:          []any{tenantID},
		GuardRequired: true,
	}, nil
}
