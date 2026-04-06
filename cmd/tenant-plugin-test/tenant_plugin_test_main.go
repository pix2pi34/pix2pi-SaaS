package main

import (
	"fmt"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/plugins/tenant"
)

func main() {

	m := tenant.NewManager()

	m.Enable("tenant-a", "erp")

	ok := m.IsEnabled("tenant-a", "erp")

	if ok {
		fmt.Println("PLUGIN ENABLED")
	} else {
		fmt.Println("PLUGIN DISABLED")
	}
}
