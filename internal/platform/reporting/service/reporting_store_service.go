package service

import (
	"fmt"
	"sort"

	reportdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/domain"
	ufkdomain "github.com/divrigili/pix2pi-SaaS/internal/ufk/domain"
)

type ReportingStoreService struct {
	kayitlar map[string]reportdomain.ReportRecord
}

func NewReportingStoreService() *ReportingStoreService {
	return &ReportingStoreService{
		kayitlar: make(map[string]reportdomain.ReportRecord),
	}
}

func (s *ReportingStoreService) key(tenantID string, reportKey string) string {
	return tenantID + "::" + reportKey
}

func (s *ReportingStoreService) LedgerdanRaporGuncelle(
	tenantID string,
	reportKey string,
	hesaplar []ufkdomain.LedgerAccount,
) error {
	if tenantID == "" {
		return fmt.Errorf("tenant id zorunlu")
	}
	if reportKey == "" {
		return fmt.Errorf("report key zorunlu")
	}
	if len(hesaplar) == 0 {
		return fmt.Errorf("hesap listesi bos olamaz")
	}

	var toplamBorc float64
	var toplamAlacak float64

	for _, hesap := range hesaplar {
		if hesap.Bakiye >= 0 {
			toplamBorc += hesap.Bakiye
		} else {
			toplamAlacak += -hesap.Bakiye
		}
	}

	s.kayitlar[s.key(tenantID, reportKey)] = reportdomain.ReportRecord{
		TenantID:     tenantID,
		ReportKey:    reportKey,
		ToplamBorc:   toplamBorc,
		ToplamAlacak: toplamAlacak,
		NetBakiye:    toplamBorc - toplamAlacak,
		KayitSayisi:  len(hesaplar),
	}

	return nil
}

func (s *ReportingStoreService) RaporGetir(
	tenantID string,
	reportKey string,
) (reportdomain.ReportRecord, error) {
	if tenantID == "" {
		return reportdomain.ReportRecord{}, fmt.Errorf("tenant id zorunlu")
	}
	if reportKey == "" {
		return reportdomain.ReportRecord{}, fmt.Errorf("report key zorunlu")
	}

	kayit, ok := s.kayitlar[s.key(tenantID, reportKey)]
	if !ok {
		return reportdomain.ReportRecord{}, fmt.Errorf("rapor bulunamadi")
	}

	return kayit, nil
}

func (s *ReportingStoreService) TenantRaporlariniListele(
	tenantID string,
) []reportdomain.ReportRecord {
	sonuc := make([]reportdomain.ReportRecord, 0)

	for _, kayit := range s.kayitlar {
		if kayit.TenantID == tenantID {
			sonuc = append(sonuc, kayit)
		}
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].ReportKey < sonuc[j].ReportKey
	})

	return sonuc
}
