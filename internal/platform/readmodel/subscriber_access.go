package readmodel

import (
	"errors"
	"strings"
)

var (
	ErrSubscriberAccessEmptyName         = errors.New("readmodel: subscriber access empty name")
	ErrSubscriberAccessTenantMismatch    = errors.New("readmodel: subscriber access tenant mismatch")
	ErrSubscriberAccessProjectionMismatch = errors.New("readmodel: subscriber access projection mismatch")
	ErrSubscriberAccessSourceMismatch    = errors.New("readmodel: subscriber access source mismatch")
	ErrSubscriberAccessColumnMismatch    = errors.New("readmodel: subscriber access column mismatch")
)

type SubscriberAccessSpec struct {
	TenantID       string
	SubscriberName string
	Descriptor     ProjectionRepositoryDescriptor
	AccessPlan     TenantQueryAccessPlan
}

func (s SubscriberAccessSpec) Validate() error {
	if strings.TrimSpace(s.TenantID) == "" {
		return ErrEmptyTenantID
	}
	if strings.TrimSpace(s.SubscriberName) == "" {
		return ErrSubscriberAccessEmptyName
	}

	target, err := s.Descriptor.TenantQueryTarget()
	if err != nil {
		return err
	}

	if err := s.AccessPlan.Validate(); err != nil {
		return err
	}

	if s.AccessPlan.TenantID != s.TenantID {
		return ErrSubscriberAccessTenantMismatch
	}
	if s.AccessPlan.Target.ProjectionName != target.ProjectionName {
		return ErrSubscriberAccessProjectionMismatch
	}
	if s.AccessPlan.Target.FullTableName != target.FullTableName {
		return ErrSubscriberAccessSourceMismatch
	}
	if s.AccessPlan.Target.TenantColumn != target.TenantColumn {
		return ErrSubscriberAccessColumnMismatch
	}

	return nil
}

func BuildSubscriberAccessSpec(
	tenantID string,
	subscriberName string,
	descriptor ProjectionRepositoryDescriptor,
	accessPlan TenantQueryAccessPlan,
) (SubscriberAccessSpec, error) {
	spec := SubscriberAccessSpec{
		TenantID:       strings.TrimSpace(tenantID),
		SubscriberName: strings.TrimSpace(subscriberName),
		Descriptor:     descriptor,
		AccessPlan:     accessPlan,
	}

	if err := spec.Validate(); err != nil {
		return SubscriberAccessSpec{}, err
	}

	return spec, nil
}
