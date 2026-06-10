package service

import (
	"fmt"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/domain"
	eventstoredomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/domain"
)

func BuildReplayEventFromStoreRecord(
	kayit eventstoredomain.EventStoreRecord,
) (eventdomain.EventMessage, error) {
	if kayit.EventID == "" {
		return eventdomain.EventMessage{}, fmt.Errorf("event id zorunlu")
	}

	if err := kayit.ValidateTenantIdentity(); err != nil {
		return eventdomain.EventMessage{}, err
	}

	if kayit.Topic == "" {
		return eventdomain.EventMessage{}, fmt.Errorf("topic zorunlu")
	}

	if kayit.Payload == "" {
		return eventdomain.EventMessage{}, fmt.Errorf("payload zorunlu")
	}

	event := eventdomain.EventMessage{
		EventID:           kayit.EventID,
		TenantID:          kayit.TenantID,
		TenantUUID:        kayit.TenantUUID,
		Topic:             kayit.Topic,
		Payload:           kayit.Payload,
		SozlesmeAdi:       kayit.SozlesmeAdi,
		SozlesmeVersiyonu: kayit.SozlesmeVersiyonu,
		CorrelationID:     kayit.CorrelationID,
		CausationID:       kayit.CausationID,
		IdempotencyKey:    kayit.IdempotencyKey,
		SourceService:     kayit.SourceService,
		Version:           kayit.Version,
		Durum:             eventdomain.EventDurumBekliyor,
		RetryCount:        kayit.RetryCount,
		MaxRetry:          kayit.MaxRetry,
		OlusturmaTarihi:   kayit.OlusturmaTarihi,
	}

	if err := event.ValidateTenantIdentity(); err != nil {
		return eventdomain.EventMessage{}, err
	}

	return event, nil
}
