package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"
)

func envOr(k, def string) string {
	v := strings.TrimSpace(os.Getenv(k))
	if v == "" {
		return def
	}
	return v
}

func joinHealth(u string) string {
	u = strings.TrimSpace(u)
	if u == "" {
		return ""
	}
	// If caller already gives a path, keep it.
	// But if it's a base URL, append /health.
	if strings.HasSuffix(u, "/health") || strings.Contains(u, "/health?") {
		return u
	}
	u = strings.TrimRight(u, "/")
	return u + "/health"
}

func httpGetJSON(url string, out any, timeout time.Duration) error {
	c := &http.Client{Timeout: timeout}
	resp, err := c.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("status=%d", resp.StatusCode)
	}
	return json.NewDecoder(resp.Body).Decode(out)
}

func httpOK(url string, timeout time.Duration) bool {
	c := &http.Client{Timeout: timeout}
	resp, err := c.Get(url)
	if err != nil {
		return false
	}
	defer resp.Body.Close()
	return resp.StatusCode >= 200 && resp.StatusCode < 300
}

func main() {
	// Ports
	missionPort := envOr("MISSION_PORT", "5860")
	registryPort := envOr("REGISTRY_PORT", "5870")

	// Registry URL
	registryURL := "http://localhost:" + registryPort + "/services"

	// Timeout for checks
	timeout := 1200 * time.Millisecond

	// Health (public)
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"ok":      true,
			"service": "mission-control",
		})
	})

	// Services status (UP/DOWN) - dynamic from registry
	http.HandleFunc("/api/services", func(w http.ResponseWriter, r *http.Request) {
		services := map[string]string{}

		// fetch registry
		if err := httpGetJSON(registryURL, &services, timeout); err != nil {
			// registry down -> still return mission-control status + registry status
			w.Header().Set("Content-Type", "application/json")
			_ = json.NewEncoder(w).Encode(map[string]string{
				"mission-control":  "UP",
				"service-registry": "DOWN",
			})
			return
		}

		result := map[string]string{}

		// include registry itself
		if httpOK("http://localhost:"+registryPort+"/health", timeout) {
			result["service-registry"] = "UP"
		} else {
			result["service-registry"] = "DOWN"
		}

		// check services from registry
		for name, baseURL := range services {
			healthURL := joinHealth(baseURL)
			if healthURL == "" {
				result[name] = "DOWN"
				continue
			}
			if httpOK(healthURL, timeout) {
				result[name] = "UP"
			} else {
				result[name] = "DOWN"
			}
		}

		// always include self
		result["mission-control"] = "UP"

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(result)
	})

	fmt.Println("🚀 Pix2pi Mission Control listening on :" + missionPort)
	_ = http.ListenAndServe(":"+missionPort, nil)
}
