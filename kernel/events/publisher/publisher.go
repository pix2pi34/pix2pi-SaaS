package publisher

import (
	"context"

	"github.com/divrigili/pix2pi-SaaS/kernel/events/model"
)

type Publisher interface {
	Publish(ctx context.Context, e model.Event) error
}
