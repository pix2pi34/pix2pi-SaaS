package docnumber

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ DocumentSequenceProvider = (*PostgresDocumentNumberProviderStore)(nil)
var _ DocumentNumberAllocationStore = (*PostgresDocumentNumberProviderStore)(nil)

type PostgresDocumentNumberProviderStore struct {
	pool *pgxpool.Pool
}

func NewPostgresDocumentNumberProviderStore(pool *pgxpool.Pool) *PostgresDocumentNumberProviderStore {
	return &PostgresDocumentNumberProviderStore{pool: pool}
}

func (s *PostgresDocumentNumberProviderStore) FindDocumentSequence(ctx context.Context, req AllocateDocumentNumberRequest) (DocumentSequenceSnapshot, error) {
	if err := ValidateAllocateDocumentNumberRequest(req); err != nil {
		return DocumentSequenceSnapshot{}, err
	}

	tx, err := s.beginTenantTx(ctx, req.TenantID)
	if err != nil {
		return DocumentSequenceSnapshot{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    tenant_id,
    document_sequence_id::text,
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
    status
FROM erp_document_sequences
WHERE tenant_id = $1
  AND document_module = $2
  AND document_type = $3
  AND COALESCE(fiscal_year, 0) = $4
  AND deleted_at IS NULL
ORDER BY created_at DESC
LIMIT 1;
`,
		req.TenantID,
		string(req.DocumentModule),
		strings.TrimSpace(req.DocumentType),
		docNumberFiscalYearKey(req.FiscalYear),
	)

	sequence, err := scanDocumentSequenceSnapshot(row)
	if err != nil {
		return DocumentSequenceSnapshot{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return DocumentSequenceSnapshot{}, err
	}

	return sequence, nil
}

func (s *PostgresDocumentNumberProviderStore) PersistDocumentNumberAllocation(ctx context.Context, allocation DocumentNumberAllocation) (DocumentNumberAllocation, error) {
	if strings.TrimSpace(allocation.TenantID) == "" {
		return DocumentNumberAllocation{}, ErrTenantRequired
	}

	if strings.TrimSpace(allocation.DocumentSequenceID) == "" {
		return DocumentNumberAllocation{}, ErrSequenceIDRequired
	}

	if allocation.AllocatedNo <= 0 {
		return DocumentNumberAllocation{}, ErrAllocatedNoInvalid
	}

	if strings.TrimSpace(allocation.DocumentNo) == "" {
		return DocumentNumberAllocation{}, ErrAllocatedNoInvalid
	}

	tx, err := s.beginTenantTx(ctx, allocation.TenantID)
	if err != nil {
		return DocumentNumberAllocation{}, err
	}
	defer tx.Rollback(ctx)

	commandTag, err := tx.Exec(ctx, `
UPDATE erp_document_sequences
SET current_no = $3,
    updated_at = now(),
    updated_by = NULLIF($4, '')
WHERE tenant_id = $1
  AND document_sequence_id = $2
  AND deleted_at IS NULL
  AND is_active = true
  AND status = 'active'
  AND current_no < $3
  AND (max_no IS NULL OR $3 <= max_no);
`,
		allocation.TenantID,
		allocation.DocumentSequenceID,
		allocation.AllocatedNo,
		allocation.AllocatedBy,
	)
	if err != nil {
		return DocumentNumberAllocation{}, err
	}

	if commandTag.RowsAffected() != 1 {
		return DocumentNumberAllocation{}, ErrSequenceExhausted
	}

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
    COALESCE(allocated_by, '');
`,
		allocation.TenantID,
		allocation.DocumentSequenceID,
		string(allocation.DocumentModule),
		strings.TrimSpace(allocation.DocumentType),
		strings.TrimSpace(allocation.DocumentNo),
		allocation.AllocatedNo,
		docNumberFiscalYearAny(allocation.FiscalYear),
		allocation.FiscalPeriod,
		docNumberNilIfEmpty(allocation.SourceDocumentID),
		string(allocation.AllocationStatus),
		allocation.AllocatedBy,
		allocation.AllocatedBy,
	)

	persisted, err := scanPersistedDocumentNumberAllocation(row)
	if err != nil {
		return DocumentNumberAllocation{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return DocumentNumberAllocation{}, err
	}

	return persisted, nil
}

func (s *PostgresDocumentNumberProviderStore) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		_ = tx.Rollback(ctx)
		return nil, err
	}

	return tx, nil
}

type documentSequenceSnapshotScanner interface {
	Scan(dest ...any) error
}

func scanDocumentSequenceSnapshot(scanner documentSequenceSnapshotScanner) (DocumentSequenceSnapshot, error) {
	var sequence DocumentSequenceSnapshot
	var documentModule string
	var fiscalYear int
	var maxNo int64
	var resetPolicy string
	var status string

	err := scanner.Scan(
		&sequence.TenantID,
		&sequence.DocumentSequenceID,
		&documentModule,
		&sequence.DocumentType,
		&fiscalYear,
		&sequence.Prefix,
		&sequence.Suffix,
		&sequence.CurrentNo,
		&sequence.MinNo,
		&maxNo,
		&sequence.Padding,
		&resetPolicy,
		&sequence.IsActive,
		&status,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return DocumentSequenceSnapshot{}, ErrSequenceNotFound
	}

	if err != nil {
		return DocumentSequenceSnapshot{}, err
	}

	if fiscalYear > 0 {
		sequence.FiscalYear = &fiscalYear
	}

	if maxNo >= 0 {
		sequence.MaxNo = &maxNo
	}

	sequence.DocumentModule = DocumentModule(documentModule)
	sequence.ResetPolicy = ResetPolicy(resetPolicy)
	sequence.Status = SequenceStatus(status)

	return sequence, nil
}

type persistedDocumentNumberAllocationScanner interface {
	Scan(dest ...any) error
}

func scanPersistedDocumentNumberAllocation(scanner persistedDocumentNumberAllocationScanner) (DocumentNumberAllocation, error) {
	var allocation DocumentNumberAllocation
	var documentModule string
	var fiscalYear int
	var allocationStatus string

	err := scanner.Scan(
		&allocation.TenantID,
		&allocation.DocumentSequenceID,
		&documentModule,
		&allocation.DocumentType,
		&allocation.DocumentNo,
		&allocation.AllocatedNo,
		&fiscalYear,
		&allocation.FiscalPeriod,
		&allocation.SourceDocumentID,
		&allocationStatus,
		&allocation.AllocatedAt,
		&allocation.AllocatedBy,
	)
	if err != nil {
		return DocumentNumberAllocation{}, err
	}

	if fiscalYear > 0 {
		allocation.FiscalYear = &fiscalYear
	}

	allocation.DocumentModule = DocumentModule(documentModule)
	allocation.AllocationStatus = AllocationStatus(allocationStatus)

	return allocation, nil
}

func docNumberFiscalYearAny(value *int) any {
	if value == nil {
		return nil
	}

	return *value
}

func docNumberFiscalYearKey(value *int) int {
	if value == nil {
		return 0
	}

	return *value
}

func docNumberNilIfEmpty(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}

	return value
}
