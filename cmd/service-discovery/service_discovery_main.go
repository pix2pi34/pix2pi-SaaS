package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"sort"
	"sync"
	"time"

	"github.com/nats-io/nats.go"
)

type ServiceInfo struct {
	Name      string    `json:"name"`
	Address   string    `json:"address"`
	Status    string    `json:"status"`
	UpdatedAt time.Time `json:"updated_at"`
	Source    string    `json:"source"`
}

type Registry struct {
	mu       sync.RWMutex
	services map[string]ServiceInfo
	ttl      time.Duration
}

func NewRegistry(ttl time.Duration) *Registry {
	return &Registry{
		services: make(map[string]ServiceInfo),
		ttl:      ttl,
	}
}

func (r *Registry) Register(name, address, source string) {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.services[name] = ServiceInfo{
		Name:      name,
		Address:   address,
		Status:    "RUNNING",
		UpdatedAt: time.Now().UTC(),
		Source:    source,
	}
}

func (r *Registry) Heartbeat(name, source string) bool {
	r.mu.Lock()
	defer r.mu.Unlock()

	svc, ok := r.services[name]
	if !ok {
		return false
	}

	svc.Status = "RUNNING"
	svc.UpdatedAt = time.Now().UTC()
	if source != "" {
		svc.Source = source
	}
	r.services[name] = svc
	return true
}

func (r *Registry) List() []ServiceInfo {
	r.mu.RLock()
	defer r.mu.RUnlock()

	sonuc := make([]ServiceInfo, 0, len(r.services))
	for _, svc := range r.services {
		kopya := svc
		if time.Since(kopya.UpdatedAt) > r.ttl {
			kopya.Status = "STALE"
		}
		sonuc = append(sonuc, kopya)
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].Name < sonuc[j].Name
	})

	return sonuc
}

func (r *Registry) Count() int {
	return len(r.List())
}

type registerRequest struct {
	Name    string `json:"name"`
	Address string `json:"address"`
}

type heartbeatRequest struct {
	Name string `json:"name"`
}

func writeJSON(w http.ResponseWriter, code int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(data)
}

func main() {
	port := os.Getenv("SERVICE_DISCOVERY_PORT")
	if port == "" {
		port = "8090"
	}

	natsURL := os.Getenv("NATS_URL")
	if natsURL == "" {
		natsURL = "nats://localhost:4222"
	}

	registry := NewRegistry(45 * time.Second)

	nc, err := nats.Connect(natsURL)
	if err != nil {
		log.Fatalf("NATS baglanti hatasi: %v", err)
	}
	defer nc.Close()

	_, err = nc.Subscribe("pix2pi.service.register", func(msg *nats.Msg) {
		var req registerRequest
		if err := json.Unmarshal(msg.Data, &req); err != nil {
			log.Printf("register parse hatasi: %v", err)
			return
		}
		if req.Name == "" || req.Address == "" {
			log.Printf("register eksik alan")
			return
		}
		registry.Register(req.Name, req.Address, "NATS")
		log.Printf("OK ✅ NATS register | name=%s | address=%s", req.Name, req.Address)
	})
	if err != nil {
		log.Fatalf("NATS register subscribe hatasi: %v", err)
	}

	_, err = nc.Subscribe("pix2pi.service.heartbeat", func(msg *nats.Msg) {
		var req heartbeatRequest
		if err := json.Unmarshal(msg.Data, &req); err != nil {
			log.Printf("heartbeat parse hatasi: %v", err)
			return
		}
		if req.Name == "" {
			log.Printf("heartbeat name bos")
			return
		}
		ok := registry.Heartbeat(req.Name, "NATS")
		if ok {
			log.Printf("OK ✅ NATS heartbeat | name=%s", req.Name)
		} else {
			log.Printf("UYARI ⚠ heartbeat geldi ama servis yok | name=%s", req.Name)
		}
	})
	if err != nil {
		log.Fatalf("NATS heartbeat subscribe hatasi: %v", err)
	}

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{
			"service": "service_discovery",
			"status":  "ok",
			"count":   registry.Count(),
			"time":    time.Now().UTC().Format(time.RFC3339),
			"mode":    "hybrid",
		})
	})

	http.HandleFunc("/register", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method_not_allowed"})
			return
		}

		var req registerRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "bad_json"})
			return
		}

		if req.Name == "" || req.Address == "" {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "name_and_address_required"})
			return
		}

		registry.Register(req.Name, req.Address, "HTTP")

		payload, _ := json.Marshal(req)
		_ = nc.Publish("pix2pi.service.register", payload)

		writeJSON(w, http.StatusOK, map[string]any{
			"ok":      true,
			"service": req.Name,
			"address": req.Address,
			"mode":    "hybrid",
		})
	})

	http.HandleFunc("/heartbeat", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method_not_allowed"})
			return
		}

		var req heartbeatRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "bad_json"})
			return
		}

		if req.Name == "" {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "name_required"})
			return
		}

		ok := registry.Heartbeat(req.Name, "HTTP")
		if !ok {
			writeJSON(w, http.StatusNotFound, map[string]string{"error": "service_not_found"})
			return
		}

		payload, _ := json.Marshal(req)
		_ = nc.Publish("pix2pi.service.heartbeat", payload)

		writeJSON(w, http.StatusOK, map[string]any{
			"ok":      true,
			"service": req.Name,
			"mode":    "hybrid",
		})
	})

	http.HandleFunc("/services", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{
			"services": registry.List(),
			"mode":     "hybrid",
		})
	})

	addr := ":" + port
	log.Printf("OK ✅ hybrid service_discovery started | port=%s | nats=%s", port, natsURL)
	log.Fatal(http.ListenAndServe(addr, nil))
}
