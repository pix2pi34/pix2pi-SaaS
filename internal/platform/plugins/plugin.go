package plugins

type Plugin struct {
	Name    string   `json:"name"`
	Version string   `json:"version"`
	Type    string   `json:"type"`
	Routes  []string `json:"routes"`
	Health  string   `json:"health"`
}
