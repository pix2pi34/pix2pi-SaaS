package main

import (
	"fmt"
	"net/http"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/plugins"
)

func main() {

	reg := plugins.NewRegistry()

	reg.Register(plugins.Plugin{
		Name:    "pix2pi-erp-plugin",
		Version: "0.1",
		Type:    "plugin",
		Routes:  []string{"/erp"},
		Health:  "http://127.0.0.1:9002/health",
	})

	http.HandleFunc("/registry/plugins", plugins.RegistryHandler(reg))

	fmt.Println("Plugin Registry HTTP server :7070")

	http.ListenAndServe(":7070", nil)
}
