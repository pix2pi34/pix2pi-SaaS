package discovery

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/plugins"
)

func DiscoverPlugin(url string) (plugins.Plugin, error) {
	client := http.Client{
		Timeout: 3 * time.Second,
	}

	resp, err := client.Get(url)
	if err != nil {
		return plugins.Plugin{}, err
	}
	defer resp.Body.Close()

	var p plugins.Plugin
	err = json.NewDecoder(resp.Body).Decode(&p)
	if err != nil {
		return plugins.Plugin{}, err
	}

	return p, nil
}
