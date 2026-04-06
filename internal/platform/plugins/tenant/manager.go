package tenant

type Manager struct {
	items []TenantPlugin
}

func NewManager() *Manager {
	return &Manager{
		items: []TenantPlugin{},
	}
}

func (m *Manager) Enable(tenantID string, plugin string) {

	m.items = append(m.items, TenantPlugin{
		TenantID: tenantID,
		Plugin:   plugin,
		Enabled:  true,
	})
}

func (m *Manager) IsEnabled(tenantID string, plugin string) bool {

	for _, t := range m.items {

		if t.TenantID == tenantID && t.Plugin == plugin && t.Enabled {
			return true
		}
	}

	return false
}
