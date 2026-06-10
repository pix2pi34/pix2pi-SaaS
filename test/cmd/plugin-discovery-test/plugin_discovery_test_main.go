package main

import (
	"fmt"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/plugins/discovery"
)

func main() {

	url := "http://127.0.0.1:9002/plugin/info"

	p, err := discovery.DiscoverPlugin(url)
	if err != nil {
		fmt.Println("HATA:", err)
		return
	}

	fmt.Println("Plugin bulundu:")
	fmt.Println("Name:", p.Name)
	fmt.Println("Version:", p.Version)
	fmt.Println("Type:", p.Type)
}
