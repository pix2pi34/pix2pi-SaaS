package tenancy

import (
	"errors"
	"strings"
)

var (
	ErrEmptyTenantID         = errors.New("tenancy: tenant id zorunlu")
	ErrEmptyTenantUUID       = errors.New("tenancy: tenant uuid zorunlu")
	ErrIncompleteIdentity    = errors.New("tenancy: tenant identity eksik")
	ErrTenantBoundaryViolation = errors.New("tenancy: tenant boundary violation")
)

type TenantIdentity struct {
	TenantID   string
	TenantUUID string
}

func NewTenantIdentity(
	tenantID string,
	tenantUUID string,
) (TenantIdentity, error) {
	ti := TenantIdentity{
		TenantID:   normalizeTenantPart(tenantID),
		TenantUUID: normalizeTenantPart(tenantUUID),
	}

	if err := ti.Validate(); err != nil {
		return TenantIdentity{}, err
	}

	return ti, nil
}

func (t TenantIdentity) Validate() error {
	if t.TenantID == "" && t.TenantUUID == "" {
		return ErrIncompleteIdentity
	}
	if t.TenantID == "" {
		return ErrEmptyTenantID
	}
	if t.TenantUUID == "" {
		return ErrEmptyTenantUUID
	}
	return nil
}

func (t TenantIdentity) IsZero() bool {
	return strings.TrimSpace(t.TenantID) == "" &&
		strings.TrimSpace(t.TenantUUID) == ""
}

func (t TenantIdentity) MatchesTenantID(tenantID string) bool {
	return normalizeTenantPart(t.TenantID) == normalizeTenantPart(tenantID)
}

func (t TenantIdentity) RequireHeaderMatch(headerTenantID string) error {
	headerTenantID = normalizeTenantPart(headerTenantID)
	if headerTenantID == "" {
		return ErrEmptyTenantID
	}
	if !t.MatchesTenantID(headerTenantID) {
		return ErrTenantBoundaryViolation
	}
	return nil
}

func normalizeTenantPart(v string) string {
	return strings.TrimSpace(v)
}
