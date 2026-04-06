package auditlog

import (
	"database/sql"
	"encoding/json"
)

type Repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

type Record struct {
	TenantID   string
	ActorType  string
	ActorID    string
	Action     string
	EntityType string
	EntityID   string
	Status     string
	Details    interface{}
}

func (r *Repository) Write(rec Record) error {
	data, err := json.Marshal(rec.Details)
	if err != nil {
		return err
	}

	_, err = r.db.Exec(`
		INSERT INTO audit_logs (
			tenant_id,
			actor_type,
			actor_id,
			action,
			entity_type,
			entity_id,
			status,
			details
		)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
	`,
		rec.TenantID,
		rec.ActorType,
		rec.ActorID,
		rec.Action,
		rec.EntityType,
		rec.EntityID,
		rec.Status,
		data,
	)

	return err
}
