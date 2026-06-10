package main

import (
	"encoding/json"
	"fmt"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/plugins"
)

func main() {

	r := plugins.NewRegistry()

	r.Register(plugins.Plugin{
		Name:    "pix2pi-erp-plugin",
		Version: "0.1",
		Type:    "plugin",
		Routes:  []string{"/erp"},
		Health:  "http://127.0.0.1:9002/health",
	})

	out, _ := json.MarshalIndent(r.List(), "", "  ")

	fmt.Println(string(out))
}
