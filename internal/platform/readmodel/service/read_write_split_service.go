package service

import (
	"fmt"
	"sort"

	readdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/readmodel/domain"
	ufkdomain "github.com/divrigili/pix2pi-SaaS/internal/ufk/domain"
)

type ReadWriteSplitService struct {
	writeLedger map[string]ufkdomain.LedgerAccount
	readLedger  map[string]readdomain.LedgerReadModel
}

func NewReadWriteSplitService() *ReadWriteSplitService {
	return &ReadWriteSplitService{
		writeLedger: make(map[string]ufkdomain.LedgerAccount),
		readLedger:  make(map[string]readdomain.LedgerReadModel),
	}
}

func (s *ReadWriteSplitService) key(tenantID string, hesapKodu string) string {
	return tenantID + "::" + hesapKodu
}

func (s *ReadWriteSplitService) WriteSideKaydet(
	tenantID string,
	hesap ufkdomain.LedgerAccount,
) error {
	if tenantID == "" {
		return fmt.Errorf("tenant id zorunlu")
	}
	if hesap.HesapKodu == "" {
		return fmt.Errorf("hesap kodu zorunlu")
	}

	s.writeLedger[s.key(tenantID, hesap.HesapKodu)] = hesap
	return nil
}

func (s *ReadWriteSplitService) ReadModelGuncelle(
	tenantID string,
	hesap ufkdomain.LedgerAccount,
) error {
	if tenantID == "" {
		return fmt.Errorf("tenant id zorunlu")
	}
	if hesap.HesapKodu == "" {
		return fmt.Errorf("hesap kodu zorunlu")
	}

	s.readLedger[s.key(tenantID, hesap.HesapKodu)] = readdomain.LedgerReadModel{
		TenantID:   tenantID,
		HesapKodu:  hesap.HesapKodu,
		Bakiye:     hesap.Bakiye,
		KaynakTipi: "ledger_snapshot",
	}
	return nil
}

func (s *ReadWriteSplitService) ReadModelGetir(
	tenantID string,
	hesapKodu string,
) (readdomain.LedgerReadModel, error) {
	if tenantID == "" {
		return readdomain.LedgerReadModel{}, fmt.Errorf("tenant id zorunlu")
	}
	if hesapKodu == "" {
		return readdomain.LedgerReadModel{}, fmt.Errorf("hesap kodu zorunlu")
	}

	model, ok := s.readLedger[s.key(tenantID, hesapKodu)]
	if !ok {
		return readdomain.LedgerReadModel{}, fmt.Errorf("read model bulunamadi")
	}

	return model, nil
}

func (s *ReadWriteSplitService) TenantReadModelleriniListele(
	tenantID string,
) []readdomain.LedgerReadModel {
	sonuc := make([]readdomain.LedgerReadModel, 0)

	for _, model := range s.readLedger {
		if model.TenantID == tenantID {
			sonuc = append(sonuc, model)
		}
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].HesapKodu < sonuc[j].HesapKodu
	})

	return sonuc
}
