package eventstore

import (
	"database/sql"
	"encoding/json"
)

type EventStore struct {
	db *sql.DB
}

func NewEventStore(db *sql.DB) *EventStore {
	return &EventStore{db: db}
}

func (e *EventStore) Save(eventType, subject, tenantID string, payload interface{}) error {

	data, _ := json.Marshal(payload)

	_, err := e.db.Exec(`
	INSERT INTO event_store (event_id, event_type, subject, payload, tenant_id)
	VALUES ($1,$2,$3,$4,$5)
	`,
		"", eventType, subject, data, tenantID,
	)

	return err
}
