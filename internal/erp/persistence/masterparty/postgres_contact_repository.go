package masterparty

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ ContactRepository = (*PostgresContactRepository)(nil)

type PostgresContactRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresContactRepository(pool *pgxpool.Pool) *PostgresContactRepository {
	return &PostgresContactRepository{pool: pool}
}

func (r *PostgresContactRepository) CreateContact(ctx context.Context, input CreateContactInput) (Contact, error) {
	if strings.TrimSpace(input.TenantID) == "" {
		return Contact{}, ErrTenantRequired
	}

	if strings.TrimSpace(input.PartyID) == "" {
		return Contact{}, ErrPartyIDRequired
	}

	if strings.TrimSpace(input.FullName) == "" {
		return Contact{}, ErrContactFullNameRequired
	}

	if strings.TrimSpace(input.Email) != "" && !strings.Contains(input.Email, "@") {
		return Contact{}, ErrEmailInvalid
	}

	tx, err := r.beginTenantTx(ctx, input.TenantID)
	if err != nil {
		return Contact{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_contacts (
    tenant_id,
    party_id,
    full_name,
    title,
    department,
    phone,
    mobile_phone,
    email,
    is_primary,
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
    NULLIF($7, ''),
    NULLIF($8, ''),
    $9,
    'active',
    NULLIF($10, '')
)
RETURNING
    contact_id::text,
    tenant_id,
    party_id::text,
    full_name,
    COALESCE(title, ''),
    COALESCE(department, ''),
    COALESCE(phone, ''),
    COALESCE(mobile_phone, ''),
    COALESCE(email, ''),
    is_primary,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`,
		input.TenantID,
		input.PartyID,
		strings.TrimSpace(input.FullName),
		input.Title,
		input.Department,
		input.Phone,
		input.MobilePhone,
		input.Email,
		input.IsPrimary,
		input.CreatedBy,
	)

	contact, err := scanContact(row)
	if err != nil {
		return Contact{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Contact{}, err
	}

	return contact, nil
}

func (r *PostgresContactRepository) GetContactByID(ctx context.Context, tenantID string, contactID string) (Contact, error) {
	if strings.TrimSpace(tenantID) == "" {
		return Contact{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return Contact{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    contact_id::text,
    tenant_id,
    party_id::text,
    full_name,
    COALESCE(title, ''),
    COALESCE(department, ''),
    COALESCE(phone, ''),
    COALESCE(mobile_phone, ''),
    COALESCE(email, ''),
    is_primary,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_contacts
WHERE tenant_id = $1
  AND contact_id = $2
  AND deleted_at IS NULL;
`, tenantID, contactID)

	contact, err := scanContact(row)
	if err != nil {
		return Contact{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Contact{}, err
	}

	return contact, nil
}

func (r *PostgresContactRepository) ListContacts(ctx context.Context, tenantID string, filter ListContactsFilter) ([]Contact, error) {
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
    c.contact_id::text,
    c.tenant_id,
    c.party_id::text,
    c.full_name,
    COALESCE(c.title, ''),
    COALESCE(c.department, ''),
    COALESCE(c.phone, ''),
    COALESCE(c.mobile_phone, ''),
    COALESCE(c.email, ''),
    c.is_primary,
    c.status,
    c.created_at,
    c.updated_at,
    COALESCE(c.created_by, ''),
    COALESCE(c.updated_by, '')
FROM erp_contacts c
JOIN erp_parties p ON p.party_id = c.party_id
WHERE c.tenant_id = $1
  AND p.tenant_id = $1
  AND ($2::uuid IS NULL OR c.party_id = $2::uuid)
  AND ($3::text = '' OR (
      c.full_name ILIKE '%' || $3 || '%'
      OR COALESCE(c.email, '') ILIKE '%' || $3 || '%'
      OR COALESCE(c.phone, '') ILIKE '%' || $3 || '%'
      OR COALESCE(c.mobile_phone, '') ILIKE '%' || $3 || '%'
  ))
  AND ($4::text = '' OR c.status = $4)
  AND c.deleted_at IS NULL
  AND p.deleted_at IS NULL
ORDER BY c.is_primary DESC, c.full_name ASC
LIMIT $5 OFFSET $6;
`,
		tenantID,
		nilIfEmpty(filter.PartyID),
		strings.TrimSpace(filter.Query),
		string(filter.Status),
		limit,
		offset,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	contacts := make([]Contact, 0)

	for rows.Next() {
		contact, err := scanContact(rows)
		if err != nil {
			return nil, err
		}

		contacts = append(contacts, contact)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return contacts, nil
}

func (r *PostgresContactRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type contactScanner interface {
	Scan(dest ...any) error
}

func scanContact(scanner contactScanner) (Contact, error) {
	var contact Contact
	var status string

	err := scanner.Scan(
		&contact.ContactID,
		&contact.TenantID,
		&contact.PartyID,
		&contact.FullName,
		&contact.Title,
		&contact.Department,
		&contact.Phone,
		&contact.MobilePhone,
		&contact.Email,
		&contact.IsPrimary,
		&status,
		&contact.CreatedAt,
		&contact.UpdatedAt,
		&contact.CreatedBy,
		&contact.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return Contact{}, ErrContactNotFound
	}

	if err != nil {
		return Contact{}, err
	}

	contact.Status = PartyStatus(status)

	return contact, nil
}

func nilIfEmpty(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}

	return value
}
