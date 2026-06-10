package main

import (
	"log"
	"net/http"
	"os"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/realtime"
)

func main() {
	addr := getenv("REALTIME_WS_ADDR", ":9075")

	config := realtime.DefaultWebSocketRuntimeConfig()
	config.AllowAllOrigins = getenv("REALTIME_WS_ALLOW_ALL_ORIGINS", "false") == "true"

	runtime := realtime.NewWebSocketRuntime(config)

	mux := http.NewServeMux()
	mux.Handle("/ws", runtime)
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("realtime-ws:ok"))
	})

	log.Printf("realtime websocket server listening on %s", addr)
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
