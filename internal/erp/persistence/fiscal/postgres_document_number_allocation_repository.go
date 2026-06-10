package fiscal

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ DocumentNumberAllocationRepository = (*PostgresDocumentNumberAllocationRepository)(nil)

type PostgresDocumentNumberAllocationRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresDocumentNumberAllocationRepository(pool *pgxpool.Pool) *PostgresDocumentNumberAllocationRepository {
	return &PostgresDocumentNumberAllocationRepository{pool: pool}
}

func (r *PostgresDocumentNumberAllocationRepository) CreateDocumentNumberAllocation(ctx context.Context, input CreateDocumentNumberAllocationInput) (DocumentNumberAllocation, error) {
	if err := ValidateCreateDocumentNumberAllocationInput(input); err != nil {
		return DocumentNumberAllocation{}, err
	}

	status := input.AllocationStatus
	if strings.TrimSpace(string(status)) == "" {
		status = AllocationStatusAllocated
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return DocumentNumberAllocation{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_document_number_allocations (
    tenant_id,
    document_sequence_id,
    document_module,
    document_type,
    document_no,
    allocated_no,
    fiscal_year,
    fiscal_period,
    source_document_id,
    allocation_status,
    allocated_by,
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
    NULLIF($8, ''),
    $9,
    $10,
    NULLIF($11, ''),
    NULLIF($12, '')
)
RETURNING
    document_number_allocation_id::text,
    tenant_id,
    document_sequence_id::text,
    document_module,
    document_type,
    document_no,
    allocated_no,
    COALESCE(fiscal_year, 0),
    COALESCE(fiscal_period, ''),
    COALESCE(source_document_id::text, ''),
    allocation_status,
    allocated_at,
    COALESCE(allocated_by, ''),
    confirmed_at,
    COALESCE(confirmed_by, ''),
    cancelled_at,
    COALESCE(cancelled_by, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		input.DocumentSequenceID,
		string(input.DocumentModule),
		strings.TrimSpace(input.DocumentType),
		strings.TrimSpace(input.DocumentNo),
		input.AllocatedNo,
		fiscalIntPtrAny(input.FiscalYear),
		input.FiscalPeriod,
		fiscalNilIfEmpty(input.SourceDocumentID),
		string(status),
		input.AllocatedBy,
		input.CreatedBy,
	)

	item, err := scanDocumentNumberAllocation(row)
	if err != nil {
		return DocumentNumberAllocation{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return DocumentNumberAllocation{}, err
	}

	return item, nil
}

func (r *PostgresDocumentNumberAllocationRepository) GetDocumentNumberAllocationByID(ctx context.Context, tenantID string, documentNumberAllocationID string) (DocumentNumberAllocation, error) {
	if strings.TrimSpace(tenantID) == "" {
		return DocumentNumberAllocation{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return DocumentNumberAllocation{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, documentNumberAllocationSelectSQL()+`
WHERE tenant_id = $1
  AND document_number_allocation_id = $2
  AND deleted_at IS NULL;
`, tenantID, documentNumberAllocationID)

	item, err := scanDocumentNumberAllocation(row)
	if err != nil {
		return DocumentNumberAllocation{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return DocumentNumberAllocation{}, err
	}

	return item, nil
}

func (r *PostgresDocumentNumberAllocationRepository) GetDocumentNumberAllocationByNo(ctx context.Context, tenantID string, documentModule DocumentModule, documentType string, documentNo string) (DocumentNumberAllocation, error) {
	if strings.TrimSpace(tenantID) == "" {
		return DocumentNumberAllocation{}, ErrTenantRequired
	}

	if !isValidDocumentModule(documentModule) {
		return DocumentNumberAllocation{}, ErrDocumentModuleInvalid
	}

	if strings.TrimSpace(documentType) == "" {
		return DocumentNumberAllocation{}, ErrDocumentTypeRequired
	}

	if strings.TrimSpace(documentNo) == "" {
		return DocumentNumberAllocation{}, ErrDocumentNoRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return DocumentNumberAllocation{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, documentNumberAllocationSelectSQL()+`
WHERE tenant_id = $1
  AND document_module = $2
  AND document_type = $3
  AND document_no = $4
  AND deleted_at IS NULL;
`, tenantID, string(documentModule), strings.TrimSpace(documentType), strings.TrimSpace(documentNo))

	item, err := scanDocumentNumberAllocation(row)
	if err != nil {
		return DocumentNumberAllocation{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return DocumentNumberAllocation{}, err
	}

	return item, nil
}

func (r *PostgresDocumentNumberAllocationRepository) ListDocumentNumberAllocations(ctx context.Context, tenantID string, filter ListDocumentNumberAllocationsFilter) ([]DocumentNumberAllocation, error) {
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

	rows, err := tx.Query(ctx, documentNumberAllocationSelectSQL()+`
WHERE tenant_id = $1
  AND ($2::uuid IS NULL OR document_sequence_id = $2::uuid)
  AND ($3::text = '' OR document_module = $3)
  AND ($4::text = '' OR document_type = $4)
  AND ($5::int IS NULL OR fiscal_year = $5)
  AND ($6::text = '' OR fiscal_period = $6)
  AND ($7::text = '' OR allocation_status = $7)
  AND ($8::text = '' OR (
      document_no ILIKE '%' || $8 || '%'
      OR document_type ILIKE '%' || $8 || '%'
      OR COALESCE(fiscal_period, '') ILIKE '%' || $8 || '%'
  ))
  AND deleted_at IS NULL
ORDER BY allocated_at DESC, document_no ASC
LIMIT $9 OFFSET $10;
`,
		tenantID,
		fiscalNilIfEmpty(filter.DocumentSequenceID),
		string(filter.DocumentModule),
		strings.TrimSpace(filter.DocumentType),
		fiscalIntPtrAny(filter.FiscalYear),
		strings.TrimSpace(filter.FiscalPeriod),
		string(filter.AllocationStatus),
		strings.TrimSpace(filter.Query),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]DocumentNumberAllocation, 0)

	for rows.Next() {
		item, err := scanDocumentNumberAllocation(rows)
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

func (r *PostgresDocumentNumberAllocationRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

func documentNumberAllocationSelectSQL() string {
	return `
SELECT
    document_number_allocation_id::text,
    tenant_id,
    document_sequence_id::text,
    document_module,
    document_type,
    document_no,
    allocated_no,
    COALESCE(fiscal_year, 0),
    COALESCE(fiscal_period, ''),
    COALESCE(source_document_id::text, ''),
    allocation_status,
    allocated_at,
    COALESCE(allocated_by, ''),
    confirmed_at,
    COALESCE(confirmed_by, ''),
    cancelled_at,
    COALESCE(cancelled_by, ''),
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_document_number_allocations
`
}

type documentNumberAllocationScanner interface {
	Scan(dest ...any) error
}

func scanDocumentNumberAllocation(scanner documentNumberAllocationScanner) (DocumentNumberAllocation, error) {
	var item DocumentNumberAllocation
	var documentModule string
	var fiscalYear int
	var allocationStatus string
	var confirmedAt pgtype.Timestamptz
	var cancelledAt pgtype.Timestamptz

	err := scanner.Scan(
		&item.DocumentNumberAllocationID,
		&item.TenantID,
		&item.DocumentSequenceID,
		&documentModule,
		&item.DocumentType,
		&item.DocumentNo,
		&item.AllocatedNo,
		&fiscalYear,
		&item.FiscalPeriod,
		&item.SourceDocumentID,
		&allocationStatus,
		&item.AllocatedAt,
		&item.AllocatedBy,
		&confirmedAt,
		&item.ConfirmedBy,
		&cancelledAt,
		&item.CancelledBy,
		&item.CreatedAt,
		&item.UpdatedAt,
		&item.CreatedBy,
		&item.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return DocumentNumberAllocation{}, ErrDocumentAllocationNotFound
	}

	if err != nil {
		return DocumentNumberAllocation{}, err
	}

	if fiscalYear > 0 {
		item.FiscalYear = &fiscalYear
	}

	if confirmedAt.Valid {
		t := confirmedAt.Time
		item.ConfirmedAt = &t
	}

	if cancelledAt.Valid {
		t := cancelledAt.Time
		item.CancelledAt = &t
	}

	item.DocumentModule = DocumentModule(documentModule)
	item.AllocationStatus = AllocationStatus(allocationStatus)

	return item, nil
}
