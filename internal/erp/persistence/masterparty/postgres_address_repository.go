package masterparty

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ AddressRepository = (*PostgresAddressRepository)(nil)

type PostgresAddressRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresAddressRepository(pool *pgxpool.Pool) *PostgresAddressRepository {
	return &PostgresAddressRepository{pool: pool}
}

func (r *PostgresAddressRepository) CreateAddress(ctx context.Context, input CreateAddressInput) (Address, error) {
	if strings.TrimSpace(input.TenantID) == "" {
		return Address{}, ErrTenantRequired
	}

	if strings.TrimSpace(input.PartyID) == "" {
		return Address{}, ErrPartyIDRequired
	}

	addressType := input.AddressType
	if strings.TrimSpace(string(addressType)) == "" {
		addressType = AddressTypeGeneral
	}

	switch addressType {
	case AddressTypeGeneral, AddressTypeInvoice, AddressTypeDelivery, AddressTypeWarehouse, AddressTypeBranch:
	default:
		return Address{}, ErrAddressTypeInvalid
	}

	countryCode := strings.ToUpper(strings.TrimSpace(input.CountryCode))
	if countryCode == "" {
		countryCode = "TR"
	}

	if strings.TrimSpace(input.City) == "" {
		return Address{}, ErrAddressCityRequired
	}

	if strings.TrimSpace(input.AddressLine1) == "" {
		return Address{}, ErrAddressLine1Required
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return Address{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_addresses (
    tenant_id,
    party_id,
    address_type,
    country_code,
    city,
    district,
    neighborhood,
    address_line1,
    address_line2,
    postal_code,
    is_primary,
    is_invoice_address,
    is_delivery_address,
    status,
    created_by
)
VALUES (
    $1,
    $2,
    $3,
    $4,
    $5,
    NULLIF($6, ''),
    NULLIF($7, ''),
    $8,
    NULLIF($9, ''),
    NULLIF($10, ''),
    $11,
    $12,
    $13,
    'active',
    NULLIF($14, '')
)
RETURNING
    address_id::text,
    tenant_id,
    party_id::text,
    address_type,
    country_code,
    city,
    COALESCE(district, ''),
    COALESCE(neighborhood, ''),
    address_line1,
    COALESCE(address_line2, ''),
    COALESCE(postal_code, ''),
    is_primary,
    is_invoice_address,
    is_delivery_address,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		input.PartyID,
		string(addressType),
		countryCode,
		strings.TrimSpace(input.City),
		input.District,
		input.Neighborhood,
		strings.TrimSpace(input.AddressLine1),
		input.AddressLine2,
		input.PostalCode,
		input.IsPrimary,
		input.IsInvoiceAddress,
		input.IsDeliveryAddress,
		input.CreatedBy,
	)

	address, err := scanAddress(row)
	if err != nil {
		return Address{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Address{}, err
	}

	return address, nil
}

func (r *PostgresAddressRepository) GetAddressByID(ctx context.Context, tenantID string, addressID string) (Address, error) {
	if strings.TrimSpace(tenantID) == "" {
		return Address{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return Address{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    address_id::text,
    tenant_id,
    party_id::text,
    address_type,
    country_code,
    city,
    COALESCE(district, ''),
    COALESCE(neighborhood, ''),
    address_line1,
    COALESCE(address_line2, ''),
    COALESCE(postal_code, ''),
    is_primary,
    is_invoice_address,
    is_delivery_address,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_addresses
WHERE tenant_id = $1
  AND address_id = $2
  AND deleted_at IS NULL;
`, tenantID, addressID)

	address, err := scanAddress(row)
	if err != nil {
		return Address{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Address{}, err
	}

	return address, nil
}

func (r *PostgresAddressRepository) ListAddresses(ctx context.Context, tenantID string, filter ListAddressesFilter) ([]Address, error) {
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
    a.address_id::text,
    a.tenant_id,
    a.party_id::text,
    a.address_type,
    a.country_code,
    a.city,
    COALESCE(a.district, ''),
    COALESCE(a.neighborhood, ''),
    a.address_line1,
    COALESCE(a.address_line2, ''),
    COALESCE(a.postal_code, ''),
    a.is_primary,
    a.is_invoice_address,
    a.is_delivery_address,
    a.status,
    a.created_at,
    a.updated_at,
    COALESCE(a.created_by, ''),
    COALESCE(a.updated_by, '')
FROM erp_addresses a
JOIN erp_parties p ON p.party_id = a.party_id
WHERE a.tenant_id = $1
  AND p.tenant_id = $1
  AND ($2::uuid IS NULL OR a.party_id = $2::uuid)
  AND ($3::text = '' OR a.address_type = $3)
  AND ($4::text = '' OR (
      a.city ILIKE '%' || $4 || '%'
      OR COALESCE(a.district, '') ILIKE '%' || $4 || '%'
      OR COALESCE(a.neighborhood, '') ILIKE '%' || $4 || '%'
      OR a.address_line1 ILIKE '%' || $4 || '%'
  ))
  AND ($5::text = '' OR a.status = $5)
  AND a.deleted_at IS NULL
  AND p.deleted_at IS NULL
ORDER BY a.is_primary DESC, a.address_type ASC, a.city ASC
LIMIT $6 OFFSET $7;
`,
		tenantID,
		nilIfEmpty(filter.PartyID),
		string(filter.AddressType),
		strings.TrimSpace(filter.Query),
		string(filter.Status),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	addresses := make([]Address, 0)

	for rows.Next() {
		address, err := scanAddress(rows)
		if err != nil {
			return nil, err
		}

		addresses = append(addresses, address)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return addresses, nil
}

func (r *PostgresAddressRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type addressScanner interface {
	Scan(dest ...any) error
}

func scanAddress(scanner addressScanner) (Address, error) {
	var address Address
	var addressType string
	var status string

	err := scanner.Scan(
		&address.AddressID,
		&address.TenantID,
		&address.PartyID,
		&addressType,
		&address.CountryCode,
		&address.City,
		&address.District,
		&address.Neighborhood,
		&address.AddressLine1,
		&address.AddressLine2,
		&address.PostalCode,
		&address.IsPrimary,
		&address.IsInvoiceAddress,
		&address.IsDeliveryAddress,
		&status,
		&address.CreatedAt,
		&address.UpdatedAt,
		&address.CreatedBy,
		&address.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return Address{}, ErrAddressNotFound
	}

	if err != nil {
		return Address{}, err
	}

	address.AddressType = AddressType(addressType)
	address.Status = PartyStatus(status)

	return address, nil
}
