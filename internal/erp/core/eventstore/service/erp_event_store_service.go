package service

import (
	"errors"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/erp/core/eventstore/domain"
)

type EventStoreService struct {
	events []eventdomain.AccountingEvent
}

func NewEventStoreService() *EventStoreService {
	return &EventStoreService{
		events: make([]eventdomain.AccountingEvent, 0),
	}
}

func (s *EventStoreService) Append(
	event eventdomain.AccountingEvent,
) error {
	if event.EventID == "" {
		return errors.New("event id zorunlu")
	}
	if event.TenantID == "" {
		return errors.New("tenant id zorunlu")
	}
	if event.TenantUUID == "" {
		return errors.New("tenant uuid zorunlu")
	}
	if event.EventType == "" {
		return errors.New("event type zorunlu")
	}

	s.events = append(s.events, event)
	return nil
}

func (s *EventStoreService) Events() []eventdomain.AccountingEvent {
	return s.events
}

func (s *EventStoreService) TenantEvents(
	tenantID string,
) []eventdomain.AccountingEvent {
	sonuc := make([]eventdomain.AccountingEvent, 0)

	for _, event := range s.events {
		if event.TenantID == tenantID {
			sonuc = append(sonuc, event)
		}
	}

	return sonuc
}
