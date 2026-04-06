package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/divrigili/pix2pi-SaaS/internal/plugins/erp/handler"
)

func main() {
	http.HandleFunc("/health", handler.HealthHandler)
	http.HandleFunc("/plugin/info", handler.InfoHandler)

	fmt.Println("ERP Plugin başlatıldı :9002")

	log.Fatal(http.ListenAndServe(":9002", nil))
}
