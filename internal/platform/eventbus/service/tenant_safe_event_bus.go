package service

import (
	"fmt"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/domain"
)

type EventPublisher interface {
	Publish(event eventdomain.EventMessage) error
}

func PublishTenantSafe(
	publisher EventPublisher,
	event eventdomain.EventMessage,
) error {
	if publisher == nil {
		return fmt.Errorf("event publisher zorunlu")
	}

	if err := event.ValidateTenantIdentity(); err != nil {
		return err
	}

	return publisher.Publish(event)
}
