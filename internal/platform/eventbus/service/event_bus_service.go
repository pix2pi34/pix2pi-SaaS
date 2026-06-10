package service

import (
	"fmt"
	"sort"
	"sync"
	"time"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/domain"
	schemaservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventschema/service"
	eventstoredomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/domain"
	eventstoreservice "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/service"
)

type EventBusService struct {
	mu            sync.RWMutex
	kuyruk        []eventdomain.EventMessage
	dlq           []eventdomain.EventMessage
	eventStore    eventstoreservice.EventStorePort
	schemaService *schemaservice.EventSchemaService
}

func NewEventBusService() *EventBusService {
	return &EventBusService{
		kuyruk: make([]eventdomain.EventMessage, 0),
		dlq:    make([]eventdomain.EventMessage, 0),
	}
}

func NewEventBusServiceWithStore(
	store eventstoreservice.EventStorePort,
) *EventBusService {
	return &EventBusService{
		kuyruk:     make([]eventdomain.EventMessage, 0),
		dlq:        make([]eventdomain.EventMessage, 0),
		eventStore: store,
	}
}

func NewEventBusServiceWithStoreAndSchema(
	store eventstoreservice.EventStorePort,
	schema *schemaservice.EventSchemaService,
) *EventBusService {
	return &EventBusService{
		kuyruk:        make([]eventdomain.EventMessage, 0),
		dlq:           make([]eventdomain.EventMessage, 0),
		eventStore:    store,
		schemaService: schema,
	}
}

func metadataStandartla(event *eventdomain.EventMessage) {
	if event.Version == 0 {
		event.Version = 1
	}
	if event.CorrelationID == "" {
		event.CorrelationID = event.EventID
	}
	if event.IdempotencyKey == "" {
		event.IdempotencyKey = event.EventID
	}
	if event.SourceService == "" {
		event.SourceService = "unknown"
	}
}

func (s *EventBusService) schemaStandartlaVeDogrula(
	event *eventdomain.EventMessage,
) error {
	if s.schemaService == nil {
		return nil
	}

	sozlesme, err := s.schemaService.Dogrula(event.Topic, event.Payload)
	if err != nil {
		return err
	}

	if event.SozlesmeAdi != "" && event.SozlesmeAdi != sozlesme.SozlesmeAdi {
		return fmt.Errorf("event sozlesme adi uyusmuyor")
	}

	if event.SozlesmeVersiyonu != 0 &&
		event.SozlesmeVersiyonu != sozlesme.SozlesmeVersiyonu {
		return fmt.Errorf("event sozlesme versiyonu uyusmuyor")
	}

	event.SozlesmeAdi = sozlesme.SozlesmeAdi
	event.SozlesmeVersiyonu = sozlesme.SozlesmeVersiyonu

	return nil
}

func (s *EventBusService) eventKuyrukVeyaDlqVarMiLocked(eventID string) bool {
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

func (s *EventBusService) ayniIdempotencyVarMiLocked(
	event eventdomain.EventMessage,
) bool {
	if event.TenantID == "" || event.Topic == "" || event.IdempotencyKey == "" {
		return false
	}

	for _, e := range s.kuyruk {
		if e.TenantID == event.TenantID &&
			e.Topic == event.Topic &&
			e.IdempotencyKey == event.IdempotencyKey {
			return true
		}
	}

	for _, e := range s.dlq {
		if e.TenantID == event.TenantID &&
			e.Topic == event.Topic &&
			e.IdempotencyKey == event.IdempotencyKey {
			return true
		}
	}

	if s.eventStore != nil &&
		s.eventStore.IdempotencyKaydiVarMi(
			event.TenantID,
			event.Topic,
			event.IdempotencyKey,
		) {
		return true
	}

	return false
}

func (s *EventBusService) eventVarMiLocked(eventID string) bool {
	if s.eventKuyrukVeyaDlqVarMiLocked(eventID) {
		return true
	}

	if s.eventStore != nil && s.eventStore.EventVarMi(eventID) {
		return true
	}

	return false
}

func (s *EventBusService) Publish(event eventdomain.EventMessage) error {
	if event.EventID == "" {
		return fmt.Errorf("event id zorunlu")
	}

	if err := event.ValidateTenantIdentity(); err != nil {
		return err
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

	metadataStandartla(&event)

	if err := s.schemaStandartlaVeDogrula(&event); err != nil {
		return err
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	if s.eventVarMiLocked(event.EventID) {
		return fmt.Errorf("duplicate event id")
	}

	if s.ayniIdempotencyVarMiLocked(event) {
		return fmt.Errorf("duplicate idempotency key")
	}

	event.Durum = eventdomain.EventDurumBekliyor

	if s.eventStore != nil {
		err := eventstoreservice.KaydetTenantSafe(
			s.eventStore,
			eventstoredomain.EventStoreRecord{
				StoreID:           "store-" + event.EventID,
				EventID:           event.EventID,
				TenantID:          event.TenantID,
				TenantUUID:        event.TenantUUID,
				Topic:             event.Topic,
				Payload:           event.Payload,
				SozlesmeAdi:       event.SozlesmeAdi,
				SozlesmeVersiyonu: event.SozlesmeVersiyonu,
				CorrelationID:     event.CorrelationID,
				CausationID:       event.CausationID,
				IdempotencyKey:    event.IdempotencyKey,
				SourceService:     event.SourceService,
				Version:           event.Version,
				Durum:             eventstoredomain.EventStoreDurumBekliyor,
				RetryCount:        0,
				MaxRetry:          event.MaxRetry,
				ReplayCount:       0,
				OlusturmaTarihi:   event.OlusturmaTarihi,
				GuncellemeTarihi:  event.OlusturmaTarihi,
			},
		)
		if err != nil {
			return fmt.Errorf("event store kayit hatasi: %w", err)
		}
	}

	s.kuyruk = append(s.kuyruk, event)
	return nil
}

func (s *EventBusService) ReplayIcinKuyrugaAl(
	event eventdomain.EventMessage,
) error {
	if event.EventID == "" {
		return fmt.Errorf("event id zorunlu")
	}

	if err := event.ValidateTenantIdentity(); err != nil {
		return err
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

	metadataStandartla(&event)

	if err := s.schemaStandartlaVeDogrula(&event); err != nil {
		return err
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	if s.eventKuyrukVeyaDlqVarMiLocked(event.EventID) {
		return fmt.Errorf("event zaten kuyrukta veya dlq'da")
	}

	event.Durum = eventdomain.EventDurumBekliyor
	event.RetryCount = 0
	event.IslenmeTarihi = time.Time{}

	s.kuyruk = append(s.kuyruk, event)
	return nil
}

func (s *EventBusService) Retry(eventID string) error {
	if eventID == "" {
		return fmt.Errorf("event id zorunlu")
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	for i := range s.kuyruk {
		if s.kuyruk[i].EventID != eventID {
			continue
		}

		yeniRetry := s.kuyruk[i].RetryCount + 1
		zaman := time.Now()

		if yeniRetry >= s.kuyruk[i].MaxRetry {
			s.kuyruk[i].RetryCount = yeniRetry
			s.kuyruk[i].Durum = eventdomain.EventDurumDlq

			if s.eventStore != nil {
				err := s.eventStore.DlqOlarakIsaretle(
					eventID,
					yeniRetry,
					"max retry asildi",
					zaman,
				)
				if err != nil {
					return err
				}
			}

			s.dlq = append(s.dlq, s.kuyruk[i])
			s.kuyruk = append(s.kuyruk[:i], s.kuyruk[i+1:]...)
			return nil
		}

		s.kuyruk[i].RetryCount = yeniRetry
		s.kuyruk[i].Durum = eventdomain.EventDurumBekliyor

		if s.eventStore != nil {
			err := s.eventStore.RetryGuncelle(
				eventID,
				yeniRetry,
				"retry tetiklendi",
				zaman,
			)
			if err != nil {
				return err
			}
		}

		return nil
	}

	return fmt.Errorf("event bulunamadi")
}

func (s *EventBusService) Ack(eventID string) error {
	if eventID == "" {
		return fmt.Errorf("event id zorunlu")
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	for i := range s.kuyruk {
		if s.kuyruk[i].EventID == eventID {
			islenmeZamani := time.Now()
			s.kuyruk[i].Durum = eventdomain.EventDurumIslendi
			s.kuyruk[i].IslenmeTarihi = islenmeZamani

			if s.eventStore != nil {
				err := s.eventStore.IslendiOlarakIsaretle(eventID, islenmeZamani)
				if err != nil {
					return err
				}
			}

			s.kuyruk = append(s.kuyruk[:i], s.kuyruk[i+1:]...)
			return nil
		}
	}

	return fmt.Errorf("event bulunamadi")
}

func (s *EventBusService) TopicBekleyenEventleriListele(
	topic string,
) []eventdomain.EventMessage {
	s.mu.RLock()
	sonuc := make([]eventdomain.EventMessage, 0)

	for _, event := range s.kuyruk {
		if event.Topic == topic &&
			event.Durum == eventdomain.EventDurumBekliyor {
			sonuc = append(sonuc, event)
		}
	}

	s.mu.RUnlock()

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}

func (s *EventBusService) TenantTopicBekleyenEventleriListele(
	tenantID string,
	topic string,
) []eventdomain.EventMessage {
	s.mu.RLock()
	sonuc := make([]eventdomain.EventMessage, 0)

	for _, event := range s.kuyruk {
		if event.TenantID == tenantID &&
			event.Topic == topic &&
			event.Durum == eventdomain.EventDurumBekliyor {
			sonuc = append(sonuc, event)
		}
	}

	s.mu.RUnlock()

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}

func (s *EventBusService) DlqEventleri() []eventdomain.EventMessage {
	s.mu.RLock()
	sonuc := make([]eventdomain.EventMessage, 0, len(s.dlq))
	sonuc = append(sonuc, s.dlq...)
	s.mu.RUnlock()

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc
}

func (s *EventBusService) DlqYenidenKuyrugaAl(eventID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	for i := range s.dlq {
		if s.dlq[i].EventID == eventID {
			event := s.dlq[i]
			event.RetryCount = 0
			event.Durum = eventdomain.EventDurumBekliyor

			if s.eventStore != nil {
				err := s.eventStore.YenidenKuyrugaAlOlarakIsaretle(
					eventID,
					time.Now(),
				)
				if err != nil {
					return err
				}
			}

			s.kuyruk = append(s.kuyruk, event)
			s.dlq = append(s.dlq[:i], s.dlq[i+1:]...)
			return nil
		}
	}

	return fmt.Errorf("dlq event bulunamadi")
}
