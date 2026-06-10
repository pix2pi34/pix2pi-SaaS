package domain

import (
	"time"

	tenancy "github.com/divrigili/pix2pi-SaaS/internal/platform/tenancy"
)

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

func (l AuditLog) TenantIdentity() (tenancy.TenantIdentity, error) {
	return tenancy.NewTenantIdentity(l.TenantID, l.TenantUUID)
}

func (l AuditLog) ValidateTenantIdentity() error {
	_, err := l.TenantIdentity()
	return err
}
