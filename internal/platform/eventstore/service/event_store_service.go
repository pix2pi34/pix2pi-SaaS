package service

import (
	"fmt"
	"sort"
	"time"

	eventstoredomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/domain"
)

type EventStoreService struct {
	kayitlar []eventstoredomain.EventStoreRecord
}

func NewEventStoreService() *EventStoreService {
	return &EventStoreService{
		kayitlar: make([]eventstoredomain.EventStoreRecord, 0),
	}
}

func (s *EventStoreService) eventVarMi(eventID string) bool {
	for _, kayit := range s.kayitlar {
		if kayit.EventID == eventID {
			return true
		}
	}
	return false
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
	if s.eventVarMi(kayit.EventID) {
		return fmt.Errorf("duplicate event id")
	}
	if kayit.TenantID == "" {
		return fmt.Errorf("tenant id zorunlu")
	}
	if kayit.TenantUUID == "" {
		return fmt.Errorf("tenant uuid zorunlu")
	}
	if kayit.Topic == "" {
		return fmt.Errorf("topic zorunlu")
	}
	if kayit.Payload == "" {
		return fmt.Errorf("payload zorunlu")
	}
	if kayit.Version == 0 {
		kayit.Version = 1
	}
	if kayit.OlusturmaTarihi.IsZero() {
		kayit.OlusturmaTarihi = time.Now()
	}

	s.kayitlar = append(s.kayitlar, kayit)
	return nil
}

func (s *EventStoreService) TumKayitlariListele() []eventstoredomain.EventStoreRecord {
	sonuc := make([]eventstoredomain.EventStoreRecord, 0, len(s.kayitlar))
	sonuc = append(sonuc, s.kayitlar...)

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}

func (s *EventStoreService) TenantKayitlariniListele(
	tenantID string,
) []eventstoredomain.EventStoreRecord {
	sonuc := make([]eventstoredomain.EventStoreRecord, 0)

	for _, kayit := range s.kayitlar {
		if kayit.TenantID == tenantID {
			sonuc = append(sonuc, kayit)
		}
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}

func (s *EventStoreService) TopicKayitlariniListele(
	topic string,
) []eventstoredomain.EventStoreRecord {
	sonuc := make([]eventstoredomain.EventStoreRecord, 0)

	for _, kayit := range s.kayitlar {
		if kayit.Topic == topic {
			sonuc = append(sonuc, kayit)
		}
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}

func (s *EventStoreService) TenantTopicKayitlariniListele(
	tenantID string,
	topic string,
) []eventstoredomain.EventStoreRecord {
	sonuc := make([]eventstoredomain.EventStoreRecord, 0)

	for _, kayit := range s.kayitlar {
		if kayit.TenantID == tenantID && kayit.Topic == topic {
			sonuc = append(sonuc, kayit)
		}
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}
