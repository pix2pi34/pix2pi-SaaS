package readmodel

import (
	"errors"
	"strings"
)

var (
	ErrProjectionRebuildAccessTenantMismatch     = errors.New("readmodel: projection rebuild access tenant mismatch")
	ErrProjectionRebuildAccessProjectionMismatch = errors.New("readmodel: projection rebuild access projection mismatch")
	ErrProjectionRebuildAccessSourceMismatch     = errors.New("readmodel: projection rebuild access source mismatch")
)

type ProjectionRebuildAccessSpec struct {
	TenantID   string
	Plan       ProjectionRebuildPlan
	AccessPlan TenantQueryAccessPlan
}

func (s ProjectionRebuildAccessSpec) Validate() error {
	if strings.TrimSpace(s.TenantID) == "" {
		return ErrEmptyTenantID
	}

	gate := NewReportingQualityGate()
	if err := gate.ValidateRebuildPlan(s.Plan); err != nil {
		return err
	}

	if err := s.AccessPlan.Validate(); err != nil {
		return err
	}

	if s.AccessPlan.TenantID != s.TenantID {
		return ErrProjectionRebuildAccessTenantMismatch
	}

	if s.AccessPlan.Target.ProjectionName != s.Plan.Projection {
		return ErrProjectionRebuildAccessProjectionMismatch
	}

	if s.AccessPlan.Target.FullTableName != s.Plan.FullTableName {
		return ErrProjectionRebuildAccessSourceMismatch
	}

	return nil
}

func BuildProjectionRebuildAccessSpec(
	tenantID string,
	plan ProjectionRebuildPlan,
	accessPlan TenantQueryAccessPlan,
) (ProjectionRebuildAccessSpec, error) {
	spec := ProjectionRebuildAccessSpec{
		TenantID:   strings.TrimSpace(tenantID),
		Plan:       plan,
		AccessPlan: accessPlan,
	}

	if err := spec.Validate(); err != nil {
		return ProjectionRebuildAccessSpec{}, err
	}

	return spec, nil
}
