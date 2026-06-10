package main

import (
	"fmt"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/plugins/health"
)

func main() {

	url := "http://127.0.0.1:9002/health"

	ok := health.Check(url)

	if ok {
		fmt.Println("PLUGIN OK")
	} else {
		fmt.Println("PLUGIN DOWN")
	}
}
