package masterparty

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ CustomerRepository = (*PostgresCustomerRepository)(nil)

type PostgresCustomerRepository struct {
	pool *pgxpool.Pool
}

func NewPostgresCustomerRepository(pool *pgxpool.Pool) *PostgresCustomerRepository {
	return &PostgresCustomerRepository{pool: pool}
}

func (r *PostgresCustomerRepository) CreateCustomer(ctx context.Context, tenantID string, partyID string, customerCode string) (Customer, error) {
	if strings.TrimSpace(tenantID) == "" {
		return Customer{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return Customer{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
INSERT INTO erp_customers (
    tenant_id,
    party_id,
    customer_code,
    currency_code,
    is_credit_allowed,
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
    customer_id::text,
    tenant_id,
    party_id::text,
    customer_code,
    COALESCE(customer_group, ''),
    credit_limit::float8,
    payment_terms_days,
    currency_code,
    is_credit_allowed,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '');
`, tenantID, partyID, strings.TrimSpace(customerCode))

	customer, err := scanCustomer(row)
	if err != nil {
		return Customer{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Customer{}, err
	}

	return customer, nil
}

func (r *PostgresCustomerRepository) GetCustomerByID(ctx context.Context, tenantID string, customerID string) (Customer, error) {
	if strings.TrimSpace(tenantID) == "" {
		return Customer{}, ErrTenantRequired
	}

	tx, err := r.beginTenantTx(ctx, tenantID)
	if err != nil {
		return Customer{}, err
	}
	defer tx.Rollback(ctx)

	row := tx.QueryRow(ctx, `
SELECT
    customer_id::text,
    tenant_id,
    party_id::text,
    customer_code,
    COALESCE(customer_group, ''),
    credit_limit::float8,
    payment_terms_days,
    currency_code,
    is_credit_allowed,
    status,
    created_at,
    updated_at,
    COALESCE(created_by, ''),
    COALESCE(updated_by, '')
FROM erp_customers
WHERE tenant_id = $1
  AND customer_id = $2
  AND deleted_at IS NULL;
`, tenantID, customerID)

	customer, err := scanCustomer(row)
	if err != nil {
		return Customer{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Customer{}, err
	}

	return customer, nil
}

func (r *PostgresCustomerRepository) ListCustomers(ctx context.Context, tenantID string, filter ListCustomersFilter) ([]Customer, error) {
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
    c.customer_id::text,
    c.tenant_id,
    c.party_id::text,
    c.customer_code,
    COALESCE(c.customer_group, ''),
    c.credit_limit::float8,
    c.payment_terms_days,
    c.currency_code,
    c.is_credit_allowed,
    c.status,
    c.created_at,
    c.updated_at,
    COALESCE(c.created_by, ''),
    COALESCE(c.updated_by, '')
FROM erp_customers c
JOIN erp_parties p ON p.party_id = c.party_id
WHERE c.tenant_id = $1
  AND p.tenant_id = $1
  AND ($2::text = '' OR (
      c.customer_code ILIKE '%' || $2 || '%'
      OR COALESCE(c.customer_group, '') ILIKE '%' || $2 || '%'
      OR p.display_name ILIKE '%' || $2 || '%'
      OR COALESCE(p.tax_no, '') ILIKE '%' || $2 || '%'
  ))
  AND ($3::text = '' OR c.status = $3)
  AND c.deleted_at IS NULL
  AND p.deleted_at IS NULL
ORDER BY c.customer_code ASC
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

	customers := make([]Customer, 0)

	for rows.Next() {
		customer, err := scanCustomer(rows)
		if err != nil {
			return nil, err
		}

		customers = append(customers, customer)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return customers, nil
}

func (r *PostgresCustomerRepository) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
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

type customerScanner interface {
	Scan(dest ...any) error
}

func scanCustomer(scanner customerScanner) (Customer, error) {
	var customer Customer
	var status string

	err := scanner.Scan(
		&customer.CustomerID,
		&customer.TenantID,
		&customer.PartyID,
		&customer.CustomerCode,
		&customer.CustomerGroup,
		&customer.CreditLimit,
		&customer.PaymentTermsDays,
		&customer.CurrencyCode,
		&customer.IsCreditAllowed,
		&status,
		&customer.CreatedAt,
		&customer.UpdatedAt,
		&customer.CreatedBy,
		&customer.UpdatedBy,
	)

	if errors.Is(err, pgx.ErrNoRows) {
		return Customer{}, ErrCustomerNotFound
	}

	if err != nil {
		return Customer{}, err
	}

	customer.Status = PartyStatus(status)

	return customer, nil
}
