package service

import (
	"fmt"

	eventdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventbus/domain"
)

func ValidateDlqEvent(
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

	return nil
}
