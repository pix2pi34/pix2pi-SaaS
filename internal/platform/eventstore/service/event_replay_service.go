package service

import (
	eventstoredomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/domain"
)

type EventReplayService struct {
	store *EventStoreService
}

func NewEventReplayService(store *EventStoreService) *EventReplayService {
	return &EventReplayService{
		store: store,
	}
}

func (s *EventReplayService) ReplayTumEventler() []eventstoredomain.EventStoreRecord {

	kayitlar := s.store.TumKayitlariListele()

	return kayitlar
}

func (s *EventReplayService) ReplayTenantEventleri(tenantID string) []eventstoredomain.EventStoreRecord {

	kayitlar := s.store.TenantKayitlariniListele(tenantID)

	return kayitlar
}

func (s *EventReplayService) ReplayTopicEventleri(topic string) []eventstoredomain.EventStoreRecord {

	kayitlar := s.store.TopicKayitlariniListele(topic)

	return kayitlar
}
