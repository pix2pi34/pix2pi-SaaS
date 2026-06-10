package db

import (
	"fmt"

	"gorm.io/gorm"
)

type TenantRLSMigrationPlan struct {
	ApplyTargets []TenantRLSTarget
	SkipTargets  []TenantRLSTarget
}

func BuildTenantRLSMigrationPlan(
	targets []TenantRLSTarget,
	hasTable func(string) bool,
) (TenantRLSMigrationPlan, error) {
	if hasTable == nil {
		return TenantRLSMigrationPlan{}, fmt.Errorf("hasTable func nil olamaz")
	}

	plan := TenantRLSMigrationPlan{
		ApplyTargets: make([]TenantRLSTarget, 0),
		SkipTargets:  make([]TenantRLSTarget, 0),
	}

	for _, target := range targets {
		if err := target.Validate(); err != nil {
			return TenantRLSMigrationPlan{}, err
		}

		if hasTable(target.TableName) {
			plan.ApplyTargets = append(plan.ApplyTargets, target)
			continue
		}

		plan.SkipTargets = append(plan.SkipTargets, target)
	}

	return plan, nil
}

func ApplyExistingCoreTenantRLSPolicies(
	tx *gorm.DB,
) error {
	if tx == nil {
		return fmt.Errorf("tx nil olamaz")
	}

	plan, err := BuildTenantRLSMigrationPlan(
		DefaultCoreTenantRLSTargets(),
		func(tableName string) bool {
			return tx.Migrator().HasTable(tableName)
		},
	)
	if err != nil {
		return err
	}

	for _, target := range plan.ApplyTargets {
		if err := ApplyTenantRLSTarget(tx, target); err != nil {
			return err
		}
	}

	return nil
}
