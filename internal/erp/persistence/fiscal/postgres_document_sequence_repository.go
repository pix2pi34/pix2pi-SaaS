package fiscal

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ DocumentSequenceRepository = (*PostgresDocumentSequenceRepository)(nil)

type PostgresDocumentSequenceRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresDocumentSequenceRepository(pool *pgxpool.Pool) *PostgresDocumentSequenceRepository {
	return &PostgresDocumentSequenceRepository{pool: pool}
}

func (r *PostgresDocumentSequenceRepository) CreateDocumentSequence(ctx context.Context, input CreateDocumentSequenceInput) (DocumentSequence, error) {
	if err := ValidateCreateDocumentSequenceInput(input); err != nil {
		return DocumentSequence{}, err
	}

	minNo := input.MinNo
	if minNo == 0 {
		minNo = 1
	}

	padding := input.Padding
	if padding == 0 {
		padding = 6
	}

	resetPolicy := input.ResetPolicy
	if strings.TrimSpace(string(resetPolicy)) == "" {
		resetPolicy = ResetPolicyYearly
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return DocumentSequence{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_document_sequences (
    tenant_id,
    document_module,
    document_type,
    fiscal_year,
    prefix,
    suffix,
    current_no,
    min_no,
    max_no,
    padding,
    reset_policy,
    is_active,
    description,
    status,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    $4,
    $5,
    $6,
    $7,
    $8,
    $9,
    $10,
    $11,
    $12,
    NULLIF($13, ''),
    'active',
    NULLIF($14, '')
)
RETURNING
    document_sequence_id::text,
    tenant_id,
    document_module,
    document_type,
    COALESCE(fiscal_year, 0),
    prefix,
    suffix,
    current_no,
    min_no,
    COALESCE(max_no, -1),
    padding,
    reset_policy,
    is_active,
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		string(input.DocumentModule),
		strings.TrimSpace(input.DocumentType),
		fiscalIntPtrAny(input.FiscalYear),
		input.Prefix,
		input.Suffix,
		input.CurrentNo,
		minNo,
		input.MaxNo,
		padding,
		string(resetPolicy),
		input.IsActive,
		input.Description,
		input.CreatedBy,
	)

	item, err := scanDocumentSequence(row)
	if err != nil {
		return DocumentSequence{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return DocumentSequence{}, err
	}

	return item, nil
}

func (r *PostgresDocumentSequenceRepository) GetDocumentSequenceByID(ctx context.Context, tenantID string, documentSequenceID string) (DocumentSequence, error) {
	if strings.TrimSpace(tenantID) == "" {
		return DocumentSequence{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return DocumentSequence{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, documentSequenceSelectSQL()+`
WHERE tenant_id = $1
  AND document_sequence_id = $2
  AND deleted_at IS NULL;
`, tenantID, documentSequenceID)

	item, err := scanDocumentSequence(row)
	if err != nil {
		return DocumentSequence{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return DocumentSequence{}, err
	}

	return item, nil
}

func (r *PostgresDocumentSequenceRepository) GetDocumentSequenceByModuleTypeYear(ctx context.Context, tenantID string, documentModule DocumentModule, documentType string, fiscalYear *int) (DocumentSequence, error) {
	if strings.TrimSpace(tenantID) == "" {
		return DocumentSequence{}, ErrTenantRequired
	}

	if !isValidDocumentModule(documentModule) {
		return DocumentSequence{}, ErrDocumentModuleInvalid
	}

	if strings.TrimSpace(documentType) == "" {
		return DocumentSequence{}, ErrDocumentTypeRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return DocumentSequence{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, documentSequenceSelectSQL()+`
WHERE tenant_id = $1
  AND document_module = $2
  AND document_type = $3
  AND COALESCE(fiscal_year, 0) = $4
  AND deleted_at IS NULL;
`, tenantID, string(documentModule), strings.TrimSpace(documentType), fiscalIntPtrKey(fiscalYear))

	item, err := scanDocumentSequence(row)
	if err != nil {
		return DocumentSequence{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return DocumentSequence{}, err
	}

	return item, nil
}

func (r *PostgresDocumentSequenceRepository) ListDocumentSequences(ctx context.Context, tenantID string, filter ListDocumentSequencesFilter) ([]DocumentSequence, error) {
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

	rows, err := tx.Query(ctx, documentSequenceSelectSQL()+`
WHERE tenant_id = $1
  AND ($2::text = '' OR document_module = $2)
  AND ($3::text = '' OR document_type = $3)
  AND ($4::int IS NULL OR fiscal_year = $4)
  AND ($5::boolean IS NULL OR is_active = $5)
  AND ($6::text = '' OR status = $6)
  AND ($7::text = '' OR (
      document_type ILIKE '%' || $7 || '%'
      OR prefix ILIKE '%' || $7 || '%'
      OR suffix ILIKE '%' || $7 || '%'
      OR COALESCE(description, '') ILIKE '%' || $7 || '%'
  ))
  AND deleted_at IS NULL
ORDER BY document_module ASC, document_type ASC, COALESCE(fiscal_year, 0) DESC
LIMIT $8 OFFSET $9;
`,
		tenantID,
		string(filter.DocumentModule),
		strings.TrimSpace(filter.DocumentType),
		fiscalIntPtrAny(filter.FiscalYear),
		fiscalBoolPtrAny(filter.IsActive),
		string(filter.Status),
		strings.TrimSpace(filter.Query),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]DocumentSequence, 0)

	for rows.Next() {
		item, err := scanDocumentSequence(rows)
		if err != nil {
			return nil, err
		}

		items = append(items, item)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return items, nil
}

func (r *PostgresDocumentSequenceRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

func documentSequenceSelectSQL() string {
	return `
SELECT
    document_sequence_id::text,
    tenant_id,
    document_module,
    document_type,
    COALESCE(fiscal_year, 0),
    prefix,
    suffix,
    current_no,
    min_no,
    COALESCE(max_no, -1),
    padding,
    reset_policy,
    is_active,
    COALESCE(description, ''),
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_document_sequences
`
}

type documentSequenceScanner interface {
	Scan(dest ...any) error
}

func scanDocumentSequence(scanner documentSequenceScanner) (DocumentSequence, error) {
	var item DocumentSequence
	var documentModule string
	var fiscalYear int
	var maxNo int64
	var resetPolicy string
	var status string

	err := scanner.Scan(
		&item.DocumentSequenceID,
		&item.TenantID,
		&documentModule,
		&item.DocumentType,
		&fiscalYear,
		&item.Prefix,
		&item.Suffix,
		&item.CurrentNo,
		&item.MinNo,
		&maxNo,
		&item.Padding,
		&resetPolicy,
		&item.IsActive,
		&item.Description,
		&status,
		&item.CreatedAt,
		&item.UpdatedAt,
		&item.CreatedBy,
		&item.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return DocumentSequence{}, ErrDocumentSequenceNotFound
	}

	if err != nil {
		return DocumentSequence{}, err
	}

	if fiscalYear > 0 {
		item.FiscalYear = &fiscalYear
	}

	if maxNo >= 0 {
		item.MaxNo = &maxNo
	}

	item.DocumentModule = DocumentModule(documentModule)
	item.ResetPolicy = ResetPolicy(resetPolicy)
	item.Status = SequenceStatus(status)

	return item, nil
}

func fiscalBoolPtrAny(value *bool) any {
	if value == nil {
		return nil
	}
	return *value
}
