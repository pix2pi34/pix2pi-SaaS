package main

import (
	"log"
	"net/http"
	"os"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/realtime"
)

func main() {
	addr := getenv("REALTIME_SSE_ADDR", ":9076")

	config := realtime.DefaultSSERuntimeConfig()
	config.AllowCORS = getenv("REALTIME_SSE_ALLOW_CORS", "false") == "true"

	runtime := realtime.NewSSERuntime(config)

	mux := http.NewServeMux()
	mux.Handle("/events", runtime)
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("realtime-sse:ok"))
	})

	log.Printf("realtime SSE server listening on %s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatal(err)
	}
}

func getenv(key string, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	return value
}
