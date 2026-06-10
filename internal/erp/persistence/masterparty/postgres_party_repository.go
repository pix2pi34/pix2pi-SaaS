package masterparty

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ PartyRepository = (*PostgresPartyRepository)(nil)

type PostgresPartyRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresPartyRepository(pool *pgxpool.Pool) *PostgresPartyRepository {
	return &PostgresPartyRepository{pool: pool}
}

func (r *PostgresPartyRepository) CreateParty(ctx context.Context, input CreatePartyInput) (Party, error) {
	if err := ValidateCreatePartyInput(input); err != nil {
		return Party{}, err
	}

	source := strings.TrimSpace(input.Source)
	if source == "" {
		source = "manual"
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return Party{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_parties (
    tenant_id,
    party_type,
    display_name,
    legal_name,
    trade_name,
    tax_no,
    tax_office,
    mersis_no,
    phone,
    email,
    source,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    NULLIF($4, ''),
    NULLIF($5, ''),
    NULLIF($6, ''),
    NULLIF($7, ''),
    NULLIF($8, ''),
    NULLIF($9, ''),
    NULLIF($10, ''),
    $11,
    NULLIF($12, '')
)
RETURNING
    party_id::text,
    tenant_id,
    party_type,
    display_name,
    COALESCE(legal_name, ''),
    COALESCE(trade_name, ''),
    COALESCE(tax_no, ''),
    COALESCE(tax_office, ''),
    COALESCE(mersis_no, ''),
    COALESCE(phone, ''),
    COALESCE(email, ''),
    status,
    source,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		string(input.PartyType),
		input.DisplayName,
		input.LegalName,
		input.TradeName,
		input.TaxNo,
		input.TaxOffice,
		input.MersisNo,
		input.Phone,
		input.Email,
		source,
		input.CreatedBy,
	)

	party, err := scanParty(row)
	if err != nil {
		return Party{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Party{}, err
	}

	return party, nil
}

func (r *PostgresPartyRepository) GetPartyByID(ctx context.Context, tenantID string, partyID string) (Party, error) {
	if strings.TrimSpace(tenantID) == "" {
		return Party{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return Party{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    party_id::text,
    tenant_id,
    party_type,
    display_name,
    COALESCE(legal_name, ''),
    COALESCE(trade_name, ''),
    COALESCE(tax_no, ''),
    COALESCE(tax_office, ''),
    COALESCE(mersis_no, ''),
    COALESCE(phone, ''),
    COALESCE(email, ''),
    status,
    source,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_parties
WHERE tenant_id = $1
  AND party_id = $2
  AND deleted_at IS NULL;
`, tenantID, partyID)

	party, err := scanParty(row)
	if err != nil {
		return Party{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Party{}, err
	}

	return party, nil
}

func (r *PostgresPartyRepository) ListParties(ctx context.Context, tenantID string, filter ListPartiesFilter) ([]Party, error) {
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
    party_id::text,
    tenant_id,
    party_type,
    display_name,
    COALESCE(legal_name, ''),
    COALESCE(trade_name, ''),
    COALESCE(tax_no, ''),
    COALESCE(tax_office, ''),
    COALESCE(mersis_no, ''),
    COALESCE(phone, ''),
    COALESCE(email, ''),
    status,
    source,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_parties
WHERE tenant_id = $1
  AND ($2::text = '' OR (
      display_name ILIKE '%' || $2 || '%'
      OR COALESCE(legal_name, '') ILIKE '%' || $2 || '%'
      OR COALESCE(tax_no, '') ILIKE '%' || $2 || '%'
  ))
  AND ($3::text = '' OR status = $3)
  AND ($6::boolean = true OR deleted_at IS NULL)
ORDER BY display_name ASC
LIMIT $4 OFFSET $5;
`,
		tenantID,
		strings.TrimSpace(filter.Query),
		string(filter.Status),
		limit,
		offset,
		filter.WithDeleted,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	parties := make([]Party, 0)

	for rows.Next() {
		party, err := scanParty(rows)
		if err != nil {
			return nil, err
		}

		parties = append(parties, party)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return parties, nil
}

func (r *PostgresPartyRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type partyScanner interface {
	Scan(dest ...any) error
}

func scanParty(scanner partyScanner) (Party, error) {
	var party Party
	var partyType string
	var status string

	err := scanner.Scan(
		&party.PartyID,
		&party.TenantID,
		&partyType,
		&party.DisplayName,
		&party.LegalName,
		&party.TradeName,
		&party.TaxNo,
		&party.TaxOffice,
		&party.MersisNo,
		&party.Phone,
		&party.Email,
		&status,
		&party.Source,
		&party.CreatedAt,
		&party.UpdatedAt,
		&party.CreatedBy,
		&party.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return Party{}, ErrPartyNotFound
	}

	if err != nil {
		return Party{}, err
	}

	party.PartyType = PartyType(partyType)
	party.Status = PartyStatus(status)

	return party, nil
}
