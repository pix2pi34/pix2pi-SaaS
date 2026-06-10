package service

import (
	"fmt"
	"sort"
	"sync"
	"time"

	eventstoredomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/domain"
)

type EventStoreService struct {
	mu       sync.RWMutex
	kayitlar []eventstoredomain.EventStoreRecord
}

func NewEventStoreService() *EventStoreService {
	return &EventStoreService{
		kayitlar: make([]eventstoredomain.EventStoreRecord, 0),
	}
}

func (s *EventStoreService) eventVarMiLocked(eventID string) bool {
	for _, kayit := range s.kayitlar {
		if kayit.EventID == eventID {
			return true
		}
	}
	return false
}

func (s *EventStoreService) EventVarMi(eventID string) bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.eventVarMiLocked(eventID)
}

func (s *EventStoreService) idempotencyKaydiVarMiLocked(
	tenantID string,
	topic string,
	idempotencyKey string,
) bool {
	if tenantID == "" || topic == "" || idempotencyKey == "" {
		return false
	}

	for _, kayit := range s.kayitlar {
		if kayit.TenantID == tenantID &&
			kayit.Topic == topic &&
			kayit.IdempotencyKey == idempotencyKey {
			return true
		}
	}

	return false
}

func (s *EventStoreService) IdempotencyKaydiVarMi(
	tenantID string,
	topic string,
	idempotencyKey string,
) bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.idempotencyKaydiVarMiLocked(tenantID, topic, idempotencyKey)
}

func (s *EventStoreService) indexBulLocked(eventID string) int {
	for i, kayit := range s.kayitlar {
		if kayit.EventID == eventID {
			return i
		}
	}
	return -1
}

func (s *EventStoreService) EventIDIleGetir(
	eventID string,
) (eventstoredomain.EventStoreRecord, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	index := s.indexBulLocked(eventID)
	if index == -1 {
		return eventstoredomain.EventStoreRecord{}, fmt.Errorf("event kaydi bulunamadi")
	}

	return s.kayitlar[index], nil
}

func metadataStandartla(kayit *eventstoredomain.EventStoreRecord) {
	if kayit.Version == 0 {
		kayit.Version = 1
	}
	if kayit.CorrelationID == "" {
		kayit.CorrelationID = kayit.EventID
	}
	if kayit.IdempotencyKey == "" {
		kayit.IdempotencyKey = kayit.EventID
	}
	if kayit.SourceService == "" {
		kayit.SourceService = "unknown"
	}
}

func (s *EventStoreService) Kaydet(
	kayit eventstoredomain.EventStoreRecord,
) error {
	if kayit.StoreID == "" {
		return fmt.Errorf("store id zorunlu")
	}

	if kayit.EventID == "" {
		return fmt.Errorf("event id zorunlu")
	}

	if err := kayit.ValidateTenantIdentity(); err != nil {
		return err
	}

	if kayit.Topic == "" {
		return fmt.Errorf("topic zorunlu")
	}

	if kayit.Payload == "" {
		return fmt.Errorf("payload zorunlu")
	}

	metadataStandartla(&kayit)

	s.mu.Lock()
	defer s.mu.Unlock()

	if s.eventVarMiLocked(kayit.EventID) {
		return fmt.Errorf("duplicate event id")
	}

	if s.idempotencyKaydiVarMiLocked(
		kayit.TenantID,
		kayit.Topic,
		kayit.IdempotencyKey,
	) {
		return fmt.Errorf("duplicate idempotency key")
	}

	if kayit.MaxRetry == 0 {
		kayit.MaxRetry = 3
	}

	if kayit.Durum == "" {
		kayit.Durum = eventstoredomain.EventStoreDurumBekliyor
	}

	if kayit.OlusturmaTarihi.IsZero() {
		kayit.OlusturmaTarihi = time.Now()
	}

	if kayit.GuncellemeTarihi.IsZero() {
		kayit.GuncellemeTarihi = kayit.OlusturmaTarihi
	}

	s.kayitlar = append(s.kayitlar, kayit)
	return nil
}

func (s *EventStoreService) DurumGuncelle(eventID string, durum string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	index := s.indexBulLocked(eventID)
	if index == -1 {
		return fmt.Errorf("event kaydi bulunamadi")
	}

	s.kayitlar[index].Durum = durum
	s.kayitlar[index].GuncellemeTarihi = time.Now()
	return nil
}

func (s *EventStoreService) RetryGuncelle(
	eventID string,
	retryCount int,
	sonHata string,
	zaman time.Time,
) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	index := s.indexBulLocked(eventID)
	if index == -1 {
		return fmt.Errorf("event kaydi bulunamadi")
	}

	s.kayitlar[index].RetryCount = retryCount
	s.kayitlar[index].SonHata = sonHata
	s.kayitlar[index].SonRetryTarihi = zaman
	s.kayitlar[index].Durum = eventstoredomain.EventStoreDurumTekrar
	s.kayitlar[index].GuncellemeTarihi = zaman
	return nil
}

func (s *EventStoreService) IslendiOlarakIsaretle(
	eventID string,
	zaman time.Time,
) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	index := s.indexBulLocked(eventID)
	if index == -1 {
		return fmt.Errorf("event kaydi bulunamadi")
	}

	s.kayitlar[index].Durum = eventstoredomain.EventStoreDurumIslendi
	s.kayitlar[index].IslenmeTarihi = zaman
	s.kayitlar[index].GuncellemeTarihi = zaman
	return nil
}

func (s *EventStoreService) DlqOlarakIsaretle(
	eventID string,
	retryCount int,
	neden string,
	zaman time.Time,
) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	index := s.indexBulLocked(eventID)
	if index == -1 {
		return fmt.Errorf("event kaydi bulunamadi")
	}

	s.kayitlar[index].RetryCount = retryCount
	s.kayitlar[index].DlqNedeni = neden
	s.kayitlar[index].Durum = eventstoredomain.EventStoreDurumDlq
	s.kayitlar[index].DlqTarihi = zaman
	s.kayitlar[index].GuncellemeTarihi = zaman
	return nil
}

func (s *EventStoreService) YenidenKuyrugaAlOlarakIsaretle(
	eventID string,
	zaman time.Time,
) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	index := s.indexBulLocked(eventID)
	if index == -1 {
		return fmt.Errorf("event kaydi bulunamadi")
	}

	s.kayitlar[index].Durum = eventstoredomain.EventStoreDurumBekliyor
	s.kayitlar[index].RetryCount = 0
	s.kayitlar[index].SonHata = ""
	s.kayitlar[index].DlqNedeni = ""
	s.kayitlar[index].GuncellemeTarihi = zaman
	return nil
}

func (s *EventStoreService) ReplayGuncelle(
	eventID string,
	zaman time.Time,
) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	index := s.indexBulLocked(eventID)
	if index == -1 {
		return fmt.Errorf("event kaydi bulunamadi")
	}

	s.kayitlar[index].ReplayCount++
	s.kayitlar[index].RetryCount = 0
	s.kayitlar[index].SonHata = ""
	s.kayitlar[index].DlqNedeni = ""
	s.kayitlar[index].Durum = eventstoredomain.EventStoreDurumBekliyor
	s.kayitlar[index].SonReplayTarihi = zaman
	s.kayitlar[index].GuncellemeTarihi = zaman
	return nil
}

func (s *EventStoreService) TumKayitlariListele() []eventstoredomain.EventStoreRecord {
	s.mu.RLock()
	sonuc := make([]eventstoredomain.EventStoreRecord, 0, len(s.kayitlar))
	sonuc = append(sonuc, s.kayitlar...)
	s.mu.RUnlock()

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}

func (s *EventStoreService) TenantKayitlariniListele(
	tenantID string,
) []eventstoredomain.EventStoreRecord {
	s.mu.RLock()
	sonuc := make([]eventstoredomain.EventStoreRecord, 0)

	for _, kayit := range s.kayitlar {
		if kayit.TenantID == tenantID {
			sonuc = append(sonuc, kayit)
		}
	}

	s.mu.RUnlock()

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}

func (s *EventStoreService) TopicKayitlariniListele(
	topic string,
) []eventstoredomain.EventStoreRecord {
	s.mu.RLock()
	sonuc := make([]eventstoredomain.EventStoreRecord, 0)

	for _, kayit := range s.kayitlar {
		if kayit.Topic == topic {
			sonuc = append(sonuc, kayit)
		}
	}

	s.mu.RUnlock()

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}

func (s *EventStoreService) TenantTopicKayitlariniListele(
	tenantID string,
	topic string,
) []eventstoredomain.EventStoreRecord {
	s.mu.RLock()
	sonuc := make([]eventstoredomain.EventStoreRecord, 0)

	for _, kayit := range s.kayitlar {
		if kayit.TenantID == tenantID && kayit.Topic == topic {
			sonuc = append(sonuc, kayit)
		}
	}

	s.mu.RUnlock()

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}
