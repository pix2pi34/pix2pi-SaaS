package chartofaccounts

import (
	"context"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func postgresAccountMappingRuleRepositoryTestDSN(t *testing.T) string {
	t.Helper()

	dsn := os.Getenv("PIX2PI_DB_TEST_DSN")
	if dsn == "" {
		dsn = os.Getenv("DB_WRITE_DSN")
	}
	if dsn == "" {
		dsn = os.Getenv("DATABASE_URL")
	}
	if dsn == "" {
		t.Skip("PIX2PI_DB_TEST_DSN / DB_WRITE_DSN / DATABASE_URL not set; skipping account mapping rule repository integration test")
	}

	return dsn
}

func TestPostgresAccountMappingRuleRepositoryCreateGetList(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresAccountMappingRuleRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresAccountMappingRuleRepository(pool)

	unique := fmt.Sprintf("%d", time.Now().UnixNano())
	mappingKey := "sales.invoice.receivable.repo." + unique
	accountCode := "120." + unique[len(unique)-6:]
	vatRate := 20.0
	isDefault := true
	isActive := true

	rule, err := repo.CreateAccountMappingRule(ctx, CreateAccountMappingRuleInput{
		TenantID:           "tenant_7",
		MappingKey:         mappingKey,
		SourceModule:       MappingSourceSales,
		SourceDocumentType: "invoice",
		EventType:          "sales.invoice.posted",
		LineType:           "receivable",
		AccountCode:        accountCode,
		AccountName:        "Alicilar Mapping Repo Test " + unique,
		VATRate:            &vatRate,
		Priority:           100,
		IsDefault:          true,
		IsActive:           true,
		Description:        "FAZ3 account mapping rule repository test " + unique,
		CreatedBy:          "faz3_test",
	})
	if err != nil {
		t.Fatalf("create account mapping rule: %v", err)
	}

	defer cleanupAccountMappingRuleFixture(t, pool, "tenant_7", rule.AccountMappingRuleID)

	if rule.AccountMappingRuleID == "" {
		t.Fatal("expected account_mapping_rule_id")
	}

	if rule.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", rule.TenantID)
	}

	if rule.MappingKey != mappingKey {
		t.Fatalf("expected mapping_key %s, got %s", mappingKey, rule.MappingKey)
	}

	if rule.SourceModule != MappingSourceSales {
		t.Fatalf("expected sales source module, got %s", rule.SourceModule)
	}

	if rule.VATRate == nil || *rule.VATRate != 20 {
		t.Fatalf("expected vat_rate 20, got %v", rule.VATRate)
	}

	gotByID, err := repo.GetAccountMappingRuleByID(ctx, "tenant_7", rule.AccountMappingRuleID)
	if err != nil {
		t.Fatalf("get account mapping rule by id: %v", err)
	}

	if gotByID.AccountMappingRuleID != rule.AccountMappingRuleID {
		t.Fatalf("expected account_mapping_rule_id %s, got %s", rule.AccountMappingRuleID, gotByID.AccountMappingRuleID)
	}

	gotByKey, err := repo.GetAccountMappingRuleByKey(ctx, "tenant_7", mappingKey)
	if err != nil {
		t.Fatalf("get account mapping rule by key: %v", err)
	}

	if gotByKey.MappingKey != mappingKey {
		t.Fatalf("expected mapping_key %s, got %s", mappingKey, gotByKey.MappingKey)
	}

	list, err := repo.ListAccountMappingRules(ctx, "tenant_7", ListAccountMappingRulesFilter{
		SourceModule:       MappingSourceSales,
		SourceDocumentType: "invoice",
		EventType:          "sales.invoice.posted",
		LineType:           "receivable",
		AccountCode:        accountCode,
		IsDefault:          &isDefault,
		IsActive:           &isActive,
		Query:              unique,
		Limit:              10,
	})
	if err != nil {
		t.Fatalf("list account mapping rules: %v", err)
	}

	if len(list) != 1 {
		t.Fatalf("expected 1 account mapping rule in list, got %d", len(list))
	}

	_, err = repo.GetAccountMappingRuleByID(ctx, "tenant_99", rule.AccountMappingRuleID)
	if !errors.Is(err, ErrAccountMappingNotFound) {
		t.Fatalf("expected ErrAccountMappingNotFound for cross-tenant read, got %v", err)
	}
}

func TestPostgresAccountMappingRuleRepositoryValidation(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, postgresAccountMappingRuleRepositoryTestDSN(t))
	if err != nil {
		t.Fatalf("create pgx pool: %v", err)
	}
	defer pool.Close()

	repo := NewPostgresAccountMappingRuleRepository(pool)

	_, err = repo.CreateAccountMappingRule(ctx, CreateAccountMappingRuleInput{
		TenantID:     "tenant_7",
		SourceModule: MappingSourceSales,
		AccountCode:  "120",
		Priority:     100,
	})

	if !errors.Is(err, ErrMappingKeyRequired) {
		t.Fatalf("expected ErrMappingKeyRequired, got %v", err)
	}
}

func cleanupAccountMappingRuleFixture(t *testing.T, pool *pgxpool.Pool, tenantID string, accountMappingRuleID string) {
	t.Helper()

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Logf("cleanup begin failed: %v", err)
		return
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		t.Logf("cleanup set tenant failed: %v", err)
		return
	}

	if accountMappingRuleID != "" {
		if _, err := tx.Exec(ctx, "DELETE FROM erp_account_mapping_rules WHERE account_mapping_rule_id = $1;", accountMappingRuleID); err != nil {
			t.Logf("cleanup account mapping rule failed: %v", err)
			return
		}
	}

	if err := tx.Commit(ctx); err != nil {
		t.Logf("cleanup commit failed: %v", err)
		return
	}
}
