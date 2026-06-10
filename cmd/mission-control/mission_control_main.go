package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"time"
)

func envOr(key, fallback string) string {
	v := os.Getenv(key)
	if v == "" {
		return fallback
	}
	return v
}

func httpOK(url string, timeout time.Duration) bool {
	client := &http.Client{Timeout: timeout}
	resp, err := client.Get(url)
	if err != nil {
		return false
	}
	defer resp.Body.Close()
	return resp.StatusCode >= 200 && resp.StatusCode < 300
}

func main() {
	missionPort := envOr("MISSION_PORT", "5860")
	registryHost := envOr("REGISTRY_HOST", "service-registry")
	registryPort := envOr("REGISTRY_PORT", "5870")
	timeout := 2 * time.Second

	registryURL := "http://" + registryHost + ":" + registryPort + "/services"

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]any{
			"ok":      true,
			"service": "mission-control",
		})
	})

	http.HandleFunc("/api/services", func(w http.ResponseWriter, r *http.Request) {
		result := map[string]string{
			"mission-control": "UP",
			"service-registry": "DOWN",
		}

		if httpOK("http://"+registryHost+":"+registryPort+"/health", timeout) {
			result["service-registry"] = "UP"
		}

		if httpOK(registryURL, timeout) {
			result["service-registry"] = "UP"
		}

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(result)
	})

	fmt.Println("🚀 Pix2pi Mission Control listening on :" + missionPort)
	_ = http.ListenAndServe(":"+missionPort, nil)
}
