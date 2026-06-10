package chartofaccounts

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ AccountMappingRuleRepository = (*PostgresAccountMappingRuleRepository)(nil)

type PostgresAccountMappingRuleRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresAccountMappingRuleRepository(pool *pgxpool.Pool) *PostgresAccountMappingRuleRepository {
	return &PostgresAccountMappingRuleRepository{pool: pool}
}

func (r *PostgresAccountMappingRuleRepository) CreateAccountMappingRule(ctx context.Context, input CreateAccountMappingRuleInput) (AccountMappingRule, error) {
	if err := ValidateCreateAccountMappingRuleInput(input); err != nil {
		return AccountMappingRule{}, err
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return AccountMappingRule{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_account_mapping_rules (
    tenant_id,
    mapping_key,
    source_module,
    source_document_type,
    event_type,
    line_type,
    account_code,
    account_name,
    vat_rate,
    priority,
    is_default,
    is_active,
    description,
    status,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    NULLIF($4, ''),
    NULLIF($5, ''),
    NULLIF($6, ''),
    $7,
    NULLIF($8, ''),
    $9,
    $10,
    $11,
    $12,
    NULLIF($13, ''),
    'active',
    NULLIF($14, '')
)
RETURNING
    account_mapping_rule_id::text,
    tenant_id,
    mapping_key,
    source_module,
    COALESCE(source_document_type, ''),
    COALESCE(event_type, ''),
    COALESCE(line_type, ''),
    account_code,
    COALESCE(account_name, ''),
    COALESCE(vat_rate::float8, -1),
    priority,
    is_default,
    is_active,
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		strings.TrimSpace(input.MappingKey),
		string(input.SourceModule),
		input.SourceDocumentType,
		input.EventType,
		input.LineType,
		strings.TrimSpace(input.AccountCode),
		input.AccountName,
		input.VATRate,
		input.Priority,
		input.IsDefault,
		input.IsActive,
		input.Description,
		input.CreatedBy,
	)

	rule, err := scanAccountMappingRule(row)
	if err != nil {
		return AccountMappingRule{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return AccountMappingRule{}, err
	}

	return rule, nil
}

func (r *PostgresAccountMappingRuleRepository) GetAccountMappingRuleByID(ctx context.Context, tenantID string, accountMappingRuleID string) (AccountMappingRule, error) {
	if strings.TrimSpace(tenantID) == "" {
		return AccountMappingRule{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return AccountMappingRule{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    account_mapping_rule_id::text,
    tenant_id,
    mapping_key,
    source_module,
    COALESCE(source_document_type, ''),
    COALESCE(event_type, ''),
    COALESCE(line_type, ''),
    account_code,
    COALESCE(account_name, ''),
    COALESCE(vat_rate::float8, -1),
    priority,
    is_default,
    is_active,
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_account_mapping_rules
WHERE tenant_id = $1
  AND account_mapping_rule_id = $2
  AND deleted_at IS NULL;
`, tenantID, accountMappingRuleID)

	rule, err := scanAccountMappingRule(row)
	if err != nil {
		return AccountMappingRule{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return AccountMappingRule{}, err
	}

	return rule, nil
}

func (r *PostgresAccountMappingRuleRepository) GetAccountMappingRuleByKey(ctx context.Context, tenantID string, mappingKey string) (AccountMappingRule, error) {
	if strings.TrimSpace(tenantID) == "" {
		return AccountMappingRule{}, ErrTenantRequired
	}

	if strings.TrimSpace(mappingKey) == "" {
		return AccountMappingRule{}, ErrMappingKeyRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return AccountMappingRule{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    account_mapping_rule_id::text,
    tenant_id,
    mapping_key,
    source_module,
    COALESCE(source_document_type, ''),
    COALESCE(event_type, ''),
    COALESCE(line_type, ''),
    account_code,
    COALESCE(account_name, ''),
    COALESCE(vat_rate::float8, -1),
    priority,
    is_default,
    is_active,
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_account_mapping_rules
WHERE tenant_id = $1
  AND mapping_key = $2
  AND deleted_at IS NULL;
`, tenantID, strings.TrimSpace(mappingKey))

	rule, err := scanAccountMappingRule(row)
	if err != nil {
		return AccountMappingRule{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return AccountMappingRule{}, err
	}

	return rule, nil
}

func (r *PostgresAccountMappingRuleRepository) ListAccountMappingRules(ctx context.Context, tenantID string, filter ListAccountMappingRulesFilter) ([]AccountMappingRule, error) {
	if strings.TrimSpace(tenantID) == "" {
		return nil, ErrTenantRequired
	}

	limit := filter.Limit
	if limit <= 0 || limit > 200 {
		limit = 50
	}

	offset := filter.Offset
	if offset < 0 {
		offset = 0
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	rows, err := tx.Query(ctx, `
SELECT
    account_mapping_rule_id::text,
    tenant_id,
    mapping_key,
    source_module,
    COALESCE(source_document_type, ''),
    COALESCE(event_type, ''),
    COALESCE(line_type, ''),
    account_code,
    COALESCE(account_name, ''),
    COALESCE(vat_rate::float8, -1),
    priority,
    is_default,
    is_active,
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_account_mapping_rules
WHERE tenant_id = $1
  AND ($2::text = '' OR source_module = $2)
  AND ($3::text = '' OR source_document_type = $3)
  AND ($4::text = '' OR event_type = $4)
  AND ($5::text = '' OR line_type = $5)
  AND ($6::text = '' OR account_code = $6)
  AND ($7::boolean IS NULL OR is_default = $7)
  AND ($8::boolean IS NULL OR is_active = $8)
  AND ($9::text = '' OR (
      mapping_key ILIKE '%' || $9 || '%'
      OR account_code ILIKE '%' || $9 || '%'
      OR COALESCE(account_name, '') ILIKE '%' || $9 || '%'
      OR COALESCE(description, '') ILIKE '%' || $9 || '%'
  ))
  AND deleted_at IS NULL
ORDER BY priority ASC, mapping_key ASC
LIMIT $10 OFFSET $11;
`,
		tenantID,
		string(filter.SourceModule),
		strings.TrimSpace(filter.SourceDocumentType),
		strings.TrimSpace(filter.EventType),
		strings.TrimSpace(filter.LineType),
		strings.TrimSpace(filter.AccountCode),
		boolPtrAny(filter.IsDefault),
		boolPtrAny(filter.IsActive),
		strings.TrimSpace(filter.Query),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	rules := make([]AccountMappingRule, 0)

	for rows.Next() {
		rule, err := scanAccountMappingRule(rows)
		if err != nil {
			return nil, err
		}

		rules = append(rules, rule)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return rules, nil
}

func (r *PostgresAccountMappingRuleRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		_ = tx.Rollback(ctx)
		return nil, err
	}

	return tx, nil
}

type accountMappingRuleScanner interface {
	Scan(dest ...any) error
}

func scanAccountMappingRule(scanner accountMappingRuleScanner) (AccountMappingRule, error) {
	var rule AccountMappingRule
	var sourceModule string
	var status string
	var vatRate float64

	err := scanner.Scan(
		&rule.AccountMappingRuleID,
		&rule.TenantID,
		&rule.MappingKey,
		&sourceModule,
		&rule.SourceDocumentType,
		&rule.EventType,
		&rule.LineType,
		&rule.AccountCode,
		&rule.AccountName,
		&vatRate,
		&rule.Priority,
		&rule.IsDefault,
		&rule.IsActive,
		&rule.Description,
		&status,
		&rule.CreatedAt,
		&rule.UpdatedAt,
		&rule.CreatedBy,
		&rule.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return AccountMappingRule{}, ErrAccountMappingNotFound
	}

	if err != nil {
		return AccountMappingRule{}, err
	}

	if vatRate >= 0 {
		rule.VATRate = &vatRate
	}

	rule.SourceModule = MappingSourceModule(sourceModule)
	rule.Status = AccountStatus(status)

	return rule, nil
}
