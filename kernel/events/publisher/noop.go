package publisher

import (
	"context"

	"github.com/divrigili/pix2pi-SaaS/kernel/events/model"
)

// NoopPublisher: event bus yokken güvenli başlangıç.
type NoopPublisher struct{}

func NewNoopPublisher() *NoopPublisher { return &NoopPublisher{} }

func (p *NoopPublisher) Publish(ctx context.Context, e model.Event) error {
	return nil
}
