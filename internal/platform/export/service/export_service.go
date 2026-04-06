package service

import (
	"fmt"

	exportdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/export/domain"
	securityservice "github.com/divrigili/pix2pi-SaaS/internal/platform/security/service"
)

type ExportService struct {
	records []exportdomain.ExportRecord
	policy  *securityservice.TenantAccessPolicyService
}

func NewExportService(
	policy *securityservice.TenantAccessPolicyService,
) *ExportService {
	return &ExportService{
		records: make([]exportdomain.ExportRecord, 0),
		policy:  policy,
	}
}

func (s *ExportService) RecordEkle(
	record exportdomain.ExportRecord,
) error {
	if record.RecordID == "" {
		return fmt.Errorf("record id zorunlu")
	}
	if record.TenantID == "" {
		return fmt.Errorf("tenant id zorunlu")
	}
	if record.TenantUUID == "" {
		return fmt.Errorf("tenant uuid zorunlu")
	}
	if record.Entity == "" {
		return fmt.Errorf("entity zorunlu")
	}
	if record.EntityID == "" {
		return fmt.Errorf("entity id zorunlu")
	}

	s.records = append(s.records, record)
	return nil
}

func (s *ExportService) TenantExportAl(
	role string,
	requestTenantID string,
	resourceTenantID string,
) ([]exportdomain.ExportRecord, error) {
	err := s.policy.TenantErisimKontrol(role, requestTenantID, resourceTenantID)
	if err != nil {
		return nil, err
	}

	sonuc := make([]exportdomain.ExportRecord, 0)
	for _, record := range s.records {
		if record.TenantID == resourceTenantID {
			sonuc = append(sonuc, record)
		}
	}

	return sonuc, nil
}

func (s *ExportService) TumExportlariAlSuperAdmin(
	role string,
) ([]exportdomain.ExportRecord, error) {
	if role != securityservice.RoleSuperAdmin {
		return nil, fmt.Errorf("tum export icin super admin gerekli")
	}

	sonuc := make([]exportdomain.ExportRecord, 0, len(s.records))
	sonuc = append(sonuc, s.records...)
	return sonuc, nil
}
