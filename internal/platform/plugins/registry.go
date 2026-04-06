package plugins

type Registry struct {
	Items []Plugin
}

func NewRegistry() *Registry {
	return &Registry{
		Items: []Plugin{},
	}
}

func (r *Registry) Register(p Plugin) {
	r.Items = append(r.Items, p)
}

func (r *Registry) List() []Plugin {
	return r.Items
}
