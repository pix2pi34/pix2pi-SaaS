package masterparty

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ VendorRepository = (*PostgresVendorRepository)(nil)

type PostgresVendorRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresVendorRepository(pool *pgxpool.Pool) *PostgresVendorRepository {
	return &PostgresVendorRepository{pool: pool}
}

func (r *PostgresVendorRepository) CreateVendor(ctx context.Context, tenantID string, partyID string, vendorCode string) (Vendor, error) {
	if strings.TrimSpace(tenantID) == "" {
		return Vendor{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return Vendor{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_vendors (
    tenant_id,
    party_id,
    vendor_code,
    currency_code,
    is_purchase_allowed,
    status,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    'TRY',
    true,
    'active',
    'faz3_repository'
)
RETURNING
    vendor_id::text,
    tenant_id,
    party_id::text,
    vendor_code,
    COALESCE(vendor_group, ''),
    payment_terms_days,
    currency_code,
    is_purchase_allowed,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`, tenantID, partyID, strings.TrimSpace(vendorCode))

	vendor, err := scanVendor(row)
	if err != nil {
		return Vendor{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Vendor{}, err
	}

	return vendor, nil
}

func (r *PostgresVendorRepository) GetVendorByID(ctx context.Context, tenantID string, vendorID string) (Vendor, error) {
	if strings.TrimSpace(tenantID) == "" {
		return Vendor{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return Vendor{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    vendor_id::text,
    tenant_id,
    party_id::text,
    vendor_code,
    COALESCE(vendor_group, ''),
    payment_terms_days,
    currency_code,
    is_purchase_allowed,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_vendors
WHERE tenant_id = $1
  AND vendor_id = $2
  AND deleted_at IS NULL;
`, tenantID, vendorID)

	vendor, err := scanVendor(row)
	if err != nil {
		return Vendor{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Vendor{}, err
	}

	return vendor, nil
}

func (r *PostgresVendorRepository) ListVendors(ctx context.Context, tenantID string, filter ListVendorsFilter) ([]Vendor, error) {
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
    v.vendor_id::text,
    v.tenant_id,
    v.party_id::text,
    v.vendor_code,
    COALESCE(v.vendor_group, ''),
    v.payment_terms_days,
    v.currency_code,
    v.is_purchase_allowed,
    v.status,
    v.created_at,
    v.updated_at,
    COALESCE(v.created_by, ''),
    COALESCE(v.updated_by, '')
FROM erp_vendors v
JOIN erp_parties p ON p.party_id = v.party_id
WHERE v.tenant_id = $1
  AND p.tenant_id = $1
  AND ($2::text = '' OR (
      v.vendor_code ILIKE '%' || $2 || '%'
      OR COALESCE(v.vendor_group, '') ILIKE '%' || $2 || '%'
      OR p.display_name ILIKE '%' || $2 || '%'
      OR COALESCE(p.tax_no, '') ILIKE '%' || $2 || '%'
  ))
  AND ($3::text = '' OR v.status = $3)
  AND v.deleted_at IS NULL
  AND p.deleted_at IS NULL
ORDER BY v.vendor_code ASC
LIMIT $4 OFFSET $5;
`,
		tenantID,
		strings.TrimSpace(filter.Query),
		string(filter.Status),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	vendors := make([]Vendor, 0)

	for rows.Next() {
		vendor, err := scanVendor(rows)
		if err != nil {
			return nil, err
		}

		vendors = append(vendors, vendor)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return vendors, nil
}

func (r *PostgresVendorRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type vendorScanner interface {
	Scan(dest ...any) error
}

func scanVendor(scanner vendorScanner) (Vendor, error) {
	var vendor Vendor
	var status string

	err := scanner.Scan(
		&vendor.VendorID,
		&vendor.TenantID,
		&vendor.PartyID,
		&vendor.VendorCode,
		&vendor.VendorGroup,
		&vendor.PaymentTermsDays,
		&vendor.CurrencyCode,
		&vendor.IsPurchaseAllowed,
		&status,
		&vendor.CreatedAt,
		&vendor.UpdatedAt,
		&vendor.CreatedBy,
		&vendor.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return Vendor{}, ErrVendorNotFound
	}

	if err != nil {
		return Vendor{}, err
	}

	vendor.Status = PartyStatus(status)

	return vendor, nil
}
