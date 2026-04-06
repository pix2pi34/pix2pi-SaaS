package domain

import "time"

type AuditLog struct {
	LogID           string
	TenantID        string
	TenantUUID      string
	UserID          string
	UserEmail       string
	Role            string
	Entity          string
	EntityID        string
	Action          string
	OldValue        string
	NewValue        string
	OlusturmaTarihi time.Time
}
