package repository

import "github.com/divrigili/pix2pi-SaaS/internal/platform/kernel"

// MemoryRepo: Şimdilik DB yok, mimariyi oturtmak için.
type MemoryRepo struct{}

func NewMemoryRepo() *MemoryRepo { return &MemoryRepo{} }

func (r *MemoryRepo) WhoAmI(ctx kernel.Context) (map[string]any, error) {
	return map[string]any{
		"tenant_id":  ctx.TenantID(),
		"request_id": ctx.RequestID,
		"source":     "repo:memory",
	}, nil
}
