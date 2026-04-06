package snapshot

import (
	"database/sql"
	"encoding/json"
	"time"
)

type Repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

type StockState struct {
	Event       string    `json:"event"`
	SaleID      string    `json:"sale_id"`
	TenantID    string    `json:"tenant_id"`
	Amount      int       `json:"amount"`
	LastUpdated time.Time `json:"last_updated"`
}

func (r *Repository) UpsertStockSaleSnapshot(tenantID string, saleID string, amount int) error {
	state := StockState{
		Event:       "sale.created",
		SaleID:      saleID,
		TenantID:    tenantID,
		Amount:      amount,
		LastUpdated: time.Now().UTC(),
	}

	data, err := json.Marshal(state)
	if err != nil {
		return err
	}

	_, err = r.db.Exec(`
		INSERT INTO snapshots (tenant_id, aggregate_type, aggregate_id, version, state, updated_at)
		VALUES ($1, $2, $3, 1, $4, NOW())
		ON CONFLICT (tenant_id, aggregate_type, aggregate_id)
		DO UPDATE SET
			version = snapshots.version + 1,
			state = EXCLUDED.state,
			updated_at = NOW()
	`,
		tenantID,
		"stock",
		saleID,
		data,
	)

	return err
}

func (r *Repository) GetSnapshot(tenantID string, aggregateType string, aggregateID string) (string, int, error) {
	var state string
	var version int

	err := r.db.QueryRow(`
		SELECT state::text, version
		FROM snapshots
		WHERE tenant_id = $1 AND aggregate_type = $2 AND aggregate_id = $3
	`,
		tenantID,
		aggregateType,
		aggregateID,
	).Scan(&state, &version)

	return state, version, err
}
