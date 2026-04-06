package tenant

type TenantPlugin struct {
	TenantID string `json:"tenant_id"`
	Plugin   string `json:"plugin"`
	Enabled  bool   `json:"enabled"`
}
