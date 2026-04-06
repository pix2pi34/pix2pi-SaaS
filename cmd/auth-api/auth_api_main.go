package main

import (
	"encoding/json"
	"log"
	"net/http"
)

type HealthResponse struct {
	OK      bool   `json:"ok"`
	Service string `json:"service"`
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	resp := HealthResponse{
		OK:      true,
		Service: "auth",
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(resp)
}

func main() {
	http.HandleFunc("/health", healthHandler)

	port := "9002"

	log.Println("Pix2pi Auth API starting on port", port)

	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Fatal(err)
	}
}
