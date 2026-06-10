package db

import (
	"fmt"

	"gorm.io/gorm"
)

type TenantRLSTarget struct {
	TableName    string
	TenantColumn string
	PolicyName   string
}

func (t TenantRLSTarget) Validate() error {
	if err := ValidateSQLIdentifier(t.TableName); err != nil {
		return err
	}

	if err := ValidateSQLIdentifier(t.TenantColumn); err != nil {
		return err
	}

	if t.PolicyName == "" {
		return fmt.Errorf("policy name bos olamaz")
	}

	if err := ValidateSQLIdentifier(t.PolicyName); err != nil {
		return err
	}

	return nil
}

func SnapshotTenantRLSTarget() TenantRLSTarget {
	tableName := "snapshots"

	return TenantRLSTarget{
		TableName:    tableName,
		TenantColumn: "tenant_id",
		PolicyName:   DefaultTenantRLSPolicyName(tableName),
	}
}

func JournalEntriesTenantRLSTarget() TenantRLSTarget {
	tableName := "journal_entries"

	return TenantRLSTarget{
		TableName:    tableName,
		TenantColumn: "tenant_id",
		PolicyName:   DefaultTenantRLSPolicyName(tableName),
	}
}

func DefaultCoreTenantRLSTargets() []TenantRLSTarget {
	return []TenantRLSTarget{
		SnapshotTenantRLSTarget(),
		JournalEntriesTenantRLSTarget(),
	}
}

func ApplyTenantRLSTarget(
	tx *gorm.DB,
	target TenantRLSTarget,
) error {
	if tx == nil {
		return fmt.Errorf("tx nil olamaz")
	}

	if err := target.Validate(); err != nil {
		return err
	}

	return ApplyTenantRLSPolicy(
		tx,
		target.TableName,
		target.TenantColumn,
		target.PolicyName,
	)
}

func ApplyDefaultCoreTenantRLSPolicies(
	tx *gorm.DB,
) error {
	for _, target := range DefaultCoreTenantRLSTargets() {
		if err := ApplyTenantRLSTarget(tx, target); err != nil {
			return err
		}
	}

	return nil
}
