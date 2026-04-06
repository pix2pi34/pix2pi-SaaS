package service

import (
	"fmt"
	"time"

	ufkdomain "github.com/divrigili/pix2pi-SaaS/internal/ufk/domain"
)

type SnapshotEngineService struct {
}

func NewSnapshotEngineService() *SnapshotEngineService {
	return &SnapshotEngineService{}
}

func (s *SnapshotEngineService) SnapshotOlustur(
	snapshotID string,
	aciklama string,
	hesaplar []ufkdomain.LedgerAccount,
) (ufkdomain.LedgerSnapshot, error) {
	if snapshotID == "" {
		return ufkdomain.LedgerSnapshot{}, fmt.Errorf("snapshot id zorunlu")
	}
	if len(hesaplar) == 0 {
		return ufkdomain.LedgerSnapshot{}, fmt.Errorf("hesap listesi bos olamaz")
	}

	kopya := make([]ufkdomain.LedgerAccount, 0, len(hesaplar))
	kopya = append(kopya, hesaplar...)

	return ufkdomain.LedgerSnapshot{
		SnapshotID:      snapshotID,
		Aciklama:        aciklama,
		Hesaplar:        kopya,
		OlusturmaTarihi: time.Now(),
	}, nil
}

func (s *SnapshotEngineService) SnapshotYukle(
	snapshot ufkdomain.LedgerSnapshot,
) ([]ufkdomain.LedgerAccount, error) {
	if snapshot.SnapshotID == "" {
		return nil, fmt.Errorf("snapshot id zorunlu")
	}
	if len(snapshot.Hesaplar) == 0 {
		return nil, fmt.Errorf("snapshot hesaplari bos olamaz")
	}

	kopya := make([]ufkdomain.LedgerAccount, 0, len(snapshot.Hesaplar))
	kopya = append(kopya, snapshot.Hesaplar...)

	return kopya, nil
}
