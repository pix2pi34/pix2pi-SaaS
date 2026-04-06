package repository

import "github.com/divrigili/pix2pi-SaaS/internal/platform/kernel"

type IdentityRepository interface {
	WhoAmI(ctx kernel.Context) (map[string]any, error)
}
