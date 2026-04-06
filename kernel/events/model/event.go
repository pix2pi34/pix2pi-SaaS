package model

import "time"

type Event struct {
	Name       string
	Version    int
	EventID    string
	OccurredAt time.Time
	TenantID   *int64
	Payload    map[string]any
}
