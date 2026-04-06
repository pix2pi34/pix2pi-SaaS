package service

import (
	"fmt"
	"path/filepath"
	"sort"
	"time"

	backupdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/backup/domain"
	securityservice "github.com/divrigili/pix2pi-SaaS/internal/platform/security/service"
)

type BackupService struct {
	records []backupdomain.BackupRecord
	policy  *securityservice.TenantAccessPolicyService
}

func NewBackupService(
	policy *securityservice.TenantAccessPolicyService,
) *BackupService {
	return &BackupService{
		records: make([]backupdomain.BackupRecord, 0),
		policy:  policy,
	}
}

func (s *BackupService) BackupOlustur(
	record backupdomain.BackupRecord,
) error {
	if record.BackupID == "" {
		return fmt.Errorf("backup id zorunlu")
	}
	if record.TenantID == "" {
		return fmt.Errorf("tenant id zorunlu")
	}
	if record.TenantUUID == "" {
		return fmt.Errorf("tenant uuid zorunlu")
	}
	if record.Content == "" {
		return fmt.Errorf("content zorunlu")
	}
	if record.OlusturmaTarihi.IsZero() {
		record.OlusturmaTarihi = time.Now()
	}

	record.FilePath = filepath.Join("backups", "tenant", record.TenantID, record.BackupID+".bak")
	s.records = append(s.records, record)
	return nil
}

func (s *BackupService) TenantBackupListele(
	role string,
	requestTenantID string,
	resourceTenantID string,
) ([]backupdomain.BackupRecord, error) {
	err := s.policy.TenantErisimKontrol(role, requestTenantID, resourceTenantID)
	if err != nil {
		return nil, err
	}

	sonuc := make([]backupdomain.BackupRecord, 0)
	for _, record := range s.records {
		if record.TenantID == resourceTenantID {
			sonuc = append(sonuc, record)
		}
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc, nil
}

func (s *BackupService) RestoreHazirla(
	role string,
	requestTenantID string,
	resourceTenantID string,
	backupID string,
) (backupdomain.BackupRecord, error) {
	err := s.policy.TenantErisimKontrol(role, requestTenantID, resourceTenantID)
	if err != nil {
		return backupdomain.BackupRecord{}, err
	}

	for _, record := range s.records {
		if record.TenantID == resourceTenantID && record.BackupID == backupID {
			return record, nil
		}
	}

	return backupdomain.BackupRecord{}, fmt.Errorf("backup bulunamadi")
}

func (s *BackupService) TumBackupListeleSuperAdmin(
	role string,
) ([]backupdomain.BackupRecord, error) {
	if role != securityservice.RoleSuperAdmin {
		return nil, fmt.Errorf("tum backuplar icin super admin gerekli")
	}

	sonuc := make([]backupdomain.BackupRecord, 0, len(s.records))
	sonuc = append(sonuc, s.records...)
	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})
	return sonuc, nil
}
