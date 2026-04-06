package kernel

import "time"

// PolicyRule: tenant schema içinde tutulan RBAC kuralı
// schema: tenant_{id}.policy_rules
type PolicyRule struct {
	ID        uint   `gorm:"primaryKey"`
	Route     string `gorm:"size:200;index;not null"` // ör: "GET /admin/ping" veya "GET /admin/*"
	Role      string `gorm:"size:50;index;not null"`  // ör: "superadmin", "admin", "user"
	Allow     bool   `gorm:"not null;default:false"`
	CreatedAt time.Time
	UpdatedAt time.Time
}
