package service

import (
	"fmt"
	"sort"
	"time"

	auditdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/audit/domain"
)

type AuditLogService struct {
	loglar []auditdomain.AuditLog
}

func NewAuditLogService() *AuditLogService {
	return &AuditLogService{
		loglar: make([]auditdomain.AuditLog, 0),
	}
}

func (s *AuditLogService) LogEkle(
	log auditdomain.AuditLog,
) error {
	if log.LogID == "" {
		return fmt.Errorf("log id zorunlu")
	}

	if err := log.ValidateTenantIdentity(); err != nil {
		return err
	}

	if log.UserID == "" {
		return fmt.Errorf("user id zorunlu")
	}
	if log.Entity == "" {
		return fmt.Errorf("entity zorunlu")
	}
	if log.EntityID == "" {
		return fmt.Errorf("entity id zorunlu")
	}
	if log.Action == "" {
		return fmt.Errorf("action zorunlu")
	}
	if log.OlusturmaTarihi.IsZero() {
		log.OlusturmaTarihi = time.Now()
	}

	s.loglar = append(s.loglar, log)
	return nil
}

func (s *AuditLogService) TumLoglariListele() []auditdomain.AuditLog {
	sonuc := make([]auditdomain.AuditLog, 0, len(s.loglar))
	sonuc = append(sonuc, s.loglar...)

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}

func (s *AuditLogService) TenantLoglariniListele(
	tenantID string,
) []auditdomain.AuditLog {
	sonuc := make([]auditdomain.AuditLog, 0)

	for _, log := range s.loglar {
		if log.TenantID == tenantID {
			sonuc = append(sonuc, log)
		}
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}

func (s *AuditLogService) EntityLoglariniListele(
	tenantID string,
	entity string,
	entityID string,
) []auditdomain.AuditLog {
	sonuc := make([]auditdomain.AuditLog, 0)

	for _, log := range s.loglar {
		if log.TenantID == tenantID && log.Entity == entity && log.EntityID == entityID {
			sonuc = append(sonuc, log)
		}
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}
