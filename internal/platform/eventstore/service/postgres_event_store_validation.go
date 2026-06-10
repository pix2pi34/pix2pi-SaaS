package service

import (
	"fmt"

	eventstoredomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/domain"
)

func validatePostgresEventStoreKaydetInput(
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

	return nil
}
