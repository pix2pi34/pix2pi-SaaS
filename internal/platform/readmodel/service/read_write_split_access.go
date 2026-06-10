package service

import (
	"fmt"
	"strings"

	readmodel "github.com/divrigili/pix2pi-SaaS/internal/platform/readmodel"
)

type ReadSplitAccessSpec struct {
	TenantID    string
	AccountCode string
	AccessPlan  readmodel.TenantQueryAccessPlan
}

func (s ReadSplitAccessSpec) Validate() error {
	if strings.TrimSpace(s.TenantID) == "" {
		return fmt.Errorf("read split access: tenant id zorunlu")
	}
	if strings.TrimSpace(s.AccountCode) == "" {
		return fmt.Errorf("read split access: account code zorunlu")
	}
	if err := s.AccessPlan.Validate(); err != nil {
		return err
	}
	if s.AccessPlan.TenantID != s.TenantID {
		return fmt.Errorf("read split access: tenant mismatch")
	}
	return nil
}

func BuildReadSplitAccessSpec(
	tenantID string,
	accountCode string,
	accessPlan readmodel.TenantQueryAccessPlan,
) (ReadSplitAccessSpec, error) {
	spec := ReadSplitAccessSpec{
		TenantID:    strings.TrimSpace(tenantID),
		AccountCode: strings.TrimSpace(accountCode),
		AccessPlan:  accessPlan,
	}

	if err := spec.Validate(); err != nil {
		return ReadSplitAccessSpec{}, err
	}

	return spec, nil
}
