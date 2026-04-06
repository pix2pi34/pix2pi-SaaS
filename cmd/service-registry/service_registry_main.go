package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
)

var services = map[string]string{}

type RegisterRequest struct {
	Name string `json:"name"`
	URL  string `json:"url"`
}

func main() {

	port := os.Getenv("REGISTRY_PORT")
	if port == "" {
		port = "5870"
	}

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Pix2pi Service Registry OK")
	})

	http.HandleFunc("/services", func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(services)
	})

	http.HandleFunc("/register", func(w http.ResponseWriter, r *http.Request) {

		var req RegisterRequest

		err := json.NewDecoder(r.Body).Decode(&req)
		if err != nil {
			http.Error(w, "invalid json", 400)
			return
		}

		services[req.Name] = req.URL

		fmt.Println("service registered:", req.Name, req.URL)

		fmt.Fprintf(w, "registered")
	})

	fmt.Println("📦 Pix2pi Service Registry running on :" + port)

	http.ListenAndServe(":"+port, nil)
}
