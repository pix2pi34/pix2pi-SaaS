package service

import (
	"fmt"

	eventstoredomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/domain"
)

type EventStoreRecorder interface {
	Kaydet(kayit eventstoredomain.EventStoreRecord) error
}

func KaydetTenantSafe(
	store EventStoreRecorder,
	kayit eventstoredomain.EventStoreRecord,
) error {
	if store == nil {
		return fmt.Errorf("event store recorder zorunlu")
	}

	if err := kayit.ValidateTenantIdentity(); err != nil {
		return err
	}

	return store.Kaydet(kayit)
}
