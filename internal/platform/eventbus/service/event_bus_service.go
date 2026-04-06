package service

import (
	"fmt"
	"sort"
	"time"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/domain"
	eventstoredomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/domain"
	eventstoreservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/service"
)

type EventBusService struct {
	kuyruk     []eventdomain.EventMessage
	dlq        []eventdomain.EventMessage
	eventStore *eventstoreservice.EventStoreService
}

func NewEventBusService() *EventBusService {
	return &EventBusService{
		kuyruk: make([]eventdomain.EventMessage, 0),
		dlq:    make([]eventdomain.EventMessage, 0),
	}
}

func NewEventBusServiceWithStore(
	store *eventstoreservice.EventStoreService,
) *EventBusService {
	return &EventBusService{
		kuyruk:     make([]eventdomain.EventMessage, 0),
		dlq:        make([]eventdomain.EventMessage, 0),
		eventStore: store,
	}
}

func (s *EventBusService) eventVarMi(eventID string) bool {

	for _, e := range s.kuyruk {
		if e.EventID == eventID {
			return true
		}
	}

	for _, e := range s.dlq {
		if e.EventID == eventID {
			return true
		}
	}

	return false
}

func (s *EventBusService) Publish(event eventdomain.EventMessage) error {

	if event.EventID == "" {
		return fmt.Errorf("event id zorunlu")
	}

	if s.eventVarMi(event.EventID) {
		return fmt.Errorf("duplicate event id")
	}

	if event.TenantID == "" {
		return fmt.Errorf("tenant id zorunlu")
	}

	if event.TenantUUID == "" {
		return fmt.Errorf("tenant uuid zorunlu")
	}

	if event.Topic == "" {
		return fmt.Errorf("topic zorunlu")
	}

	if event.Payload == "" {
		return fmt.Errorf("payload zorunlu")
	}

	if event.OlusturmaTarihi.IsZero() {
		event.OlusturmaTarihi = time.Now()
	}

	if event.MaxRetry == 0 {
		event.MaxRetry = 3
	}

	event.Durum = eventdomain.EventDurumBekliyor

	if s.eventStore != nil {
		err := s.eventStore.Kaydet(
			eventstoredomain.EventStoreRecord{
				StoreID:         "store-" + event.EventID,
				EventID:         event.EventID,
				TenantID:        event.TenantID,
				TenantUUID:      event.TenantUUID,
				Topic:           event.Topic,
				Payload:         event.Payload,
				Version:         1,
				OlusturmaTarihi: event.OlusturmaTarihi,
			},
		)
		if err != nil {
			return fmt.Errorf("event store kayit hatasi: %w", err)
		}
	}

	s.kuyruk = append(s.kuyruk, event)

	return nil
}

func (s *EventBusService) Retry(eventID string) error {

	if eventID == "" {
		return fmt.Errorf("event id zorunlu")
	}

	for i := range s.kuyruk {

		if s.kuyruk[i].EventID == eventID {

			s.kuyruk[i].RetryCount++

			if s.kuyruk[i].RetryCount >= s.kuyruk[i].MaxRetry {

				s.kuyruk[i].Durum = eventdomain.EventDurumDlq
				s.dlq = append(s.dlq, s.kuyruk[i])
				s.kuyruk = append(s.kuyruk[:i], s.kuyruk[i+1:]...)

				return nil
			}

			return nil
		}

	}

	return fmt.Errorf("event bulunamadi")
}

func (s *EventBusService) Ack(eventID string) error {

	if eventID == "" {
		return fmt.Errorf("event id zorunlu")
	}

	for i := range s.kuyruk {

		if s.kuyruk[i].EventID == eventID {

			s.kuyruk[i].Durum = eventdomain.EventDurumIslendi
			s.kuyruk[i].IslenmeTarihi = time.Now()

			return nil
		}

	}

	return fmt.Errorf("event bulunamadi")
}

func (s *EventBusService) TopicBekleyenEventleriListele(
	topic string,
) []eventdomain.EventMessage {

	sonuc := make([]eventdomain.EventMessage, 0)

	for _, event := range s.kuyruk {

		if event.Topic == topic &&
			event.Durum == eventdomain.EventDurumBekliyor {
			sonuc = append(sonuc, event)
		}
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}

func (s *EventBusService) TenantTopicBekleyenEventleriListele(
	tenantID string,
	topic string,
) []eventdomain.EventMessage {

	sonuc := make([]eventdomain.EventMessage, 0)

	for _, event := range s.kuyruk {

		if event.TenantID == tenantID &&
			event.Topic == topic &&
			event.Durum == eventdomain.EventDurumBekliyor {
			sonuc = append(sonuc, event)
		}
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}

func (s *EventBusService) DlqEventleri() []eventdomain.EventMessage {

	sort.Slice(s.dlq, func(i, j int) bool {
		return s.dlq[i].OlusturmaTarihi.Before(s.dlq[j].OlusturmaTarihi)
	})

	return s.dlq
}

func (s *EventBusService) DlqYenidenKuyrugaAl(eventID string) error {

	for i := range s.dlq {

		if s.dlq[i].EventID == eventID {

			event := s.dlq[i]
			event.RetryCount = 0
			event.Durum = eventdomain.EventDurumBekliyor

			s.kuyruk = append(s.kuyruk, event)
			s.dlq = append(s.dlq[:i], s.dlq[i+1:]...)

			return nil
		}
	}

	return fmt.Errorf("dlq event bulunamadi")
}
