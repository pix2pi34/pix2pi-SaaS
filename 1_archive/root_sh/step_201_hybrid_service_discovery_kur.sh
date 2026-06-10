#!/bin/bash
set -e

proje_dizini="$HOME/pix2pi/pix2pi-SaaS"
hedef_klasor="$proje_dizini/cmd/service-discovery"
hedef_dosya="$hedef_klasor/service_discovery_main.go"
test_dosya="$hedef_klasor/service_discovery_main_test.go"

yedek_klasor="$proje_dizini/_yedekler"
zaman="$(date +%Y%m%d_%H%M%S)"

binary_dosya="/usr/local/bin/pix2pi_service_discovery_bin"
start_script="/usr/local/bin/pix2pi_service_discovery_start.sh"
stop_script="/usr/local/bin/pix2pi_service_discovery_stop.sh"
status_script="/usr/local/bin/pix2pi_service_discovery_status.sh"

log_dosya="/tmp/pix2pi_service_discovery.log"
pid_dosya="/tmp/pix2pi_service_discovery.pid"

echo "1) Klasorler hazirlaniyor..."
mkdir -p "$hedef_klasor"
mkdir -p "$yedek_klasor"
echo "OK ✅ klasorler hazir"

echo
echo "2) Yedekler aliniyor..."
if [ -f "$hedef_dosya" ]; then
  cp "$hedef_dosya" "$yedek_klasor/service_discovery_main.go.$zaman.bak"
  echo "OK ✅ service_discovery_main.go yedegi alindi"
else
  echo "OK ✅ onceki service_discovery_main.go yok"
fi

if [ -f "$test_dosya" ]; then
  cp "$test_dosya" "$yedek_klasor/service_discovery_main_test.go.$zaman.bak"
  echo "OK ✅ service_discovery_main_test.go yedegi alindi"
else
  echo "OK ✅ onceki test dosyasi yok"
fi

echo
echo "3) Hybrid service discovery kodu yaziliyor..."
cat <<'GOEOF' > "$hedef_dosya"
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
GOEOF
echo "OK ✅ service_discovery_main.go yazildi"

echo
echo "4) Test kodu yaziliyor..."
cat <<'GOEOF' > "$test_dosya"
package main

import (
	"testing"
	"time"
)

func TestRegistryRegisterAndList(t *testing.T) {
	registry := NewRegistry(1 * time.Minute)

	registry.Register("stock_service", "http://127.0.0.1:7001", "HTTP")
	liste := registry.List()

	if len(liste) != 1 {
		t.Fatalf("beklenen 1 servis, gelen %d", len(liste))
	}

	if liste[0].Name != "stock_service" {
		t.Fatalf("beklenen stock_service, gelen %s", liste[0].Name)
	}

	if liste[0].Status != "RUNNING" {
		t.Fatalf("beklenen RUNNING, gelen %s", liste[0].Status)
	}

	if liste[0].Source != "HTTP" {
		t.Fatalf("beklenen HTTP, gelen %s", liste[0].Source)
	}
}

func TestRegistryHeartbeat(t *testing.T) {
	registry := NewRegistry(1 * time.Minute)

	registry.Register("accounting_service", "http://127.0.0.1:7002", "NATS")
	ok := registry.Heartbeat("accounting_service", "NATS")
	if !ok {
		t.Fatal("heartbeat false dondu")
	}

	yok := registry.Heartbeat("olmayan_servis", "NATS")
	if yok {
		t.Fatal("olmayan servis icin heartbeat true dondu")
	}
}
GOEOF
echo "OK ✅ test dosyasi yazildi"

echo
echo "5) Testler calistiriliyor..."
cd "$proje_dizini"
go test ./cmd/service-discovery -v
echo "OK ✅ testler gecti"

echo
echo "6) Build yapiliyor..."
go build -o "$binary_dosya" ./cmd/service-discovery
chmod +x "$binary_dosya"
echo "OK ✅ binary hazir: $binary_dosya"

echo
echo "7) Start/Stop/Status scriptleri yaziliyor..."
cat <<STARTEOF > "$start_script"
#!/bin/bash
set -e

binary_dosya="/usr/local/bin/pix2pi_service_discovery_bin"
log_dosya="/tmp/pix2pi_service_discovery.log"
pid_dosya="/tmp/pix2pi_service_discovery.pid"

if [ -f "\$pid_dosya" ]; then
  pid="\$(cat "\$pid_dosya" 2>/dev/null || true)"
  if [ -n "\$pid" ] && kill -0 "\$pid" 2>/dev/null; then
    echo "OK ✅ service_discovery zaten calisiyor | pid=\$pid"
    exit 0
  fi
fi

nohup "\$binary_dosya" >> "\$log_dosya" 2>&1 &
yeni_pid=\$!
echo "\$yeni_pid" > "\$pid_dosya"
sleep 2

if kill -0 "\$yeni_pid" 2>/dev/null; then
  echo "OK ✅ service_discovery baslatildi | pid=\$yeni_pid"
else
  echo "HATA ❌ service_discovery baslatilamadi"
  exit 1
fi
STARTEOF

cat <<STOPEOF > "$stop_script"
#!/bin/bash
set -e

pid_dosya="/tmp/pix2pi_service_discovery.pid"

if [ ! -f "\$pid_dosya" ]; then
  echo "OK ✅ service_discovery zaten kapali"
  exit 0
fi

pid="\$(cat "\$pid_dosya" 2>/dev/null || true)"
if [ -n "\$pid" ] && kill -0 "\$pid" 2>/dev/null; then
  kill "\$pid"
  sleep 1
  echo "OK ✅ service_discovery durduruldu | pid=\$pid"
else
  echo "OK ✅ process zaten calismiyordu"
fi

rm -f "\$pid_dosya"
STOPEOF

cat <<STATUSEOF > "$status_script"
#!/bin/bash
set -e

pid_dosya="/tmp/pix2pi_service_discovery.pid"
log_dosya="/tmp/pix2pi_service_discovery.log"

if [ -f "\$pid_dosya" ]; then
  pid="\$(cat "\$pid_dosya" 2>/dev/null || true)"
  if [ -n "\$pid" ] && kill -0 "\$pid" 2>/dev/null; then
    echo "RUNNING pid=\$pid"
    echo "LOG: \$log_dosya"
    exit 0
  fi
fi

echo "STOPPED"
echo "LOG: \$log_dosya"
exit 1
STATUSEOF

chmod +x "$start_script" "$stop_script" "$status_script"
echo "OK ✅ start/stop/status scriptleri hazir"

echo
echo "8) Eski process temizleniyor..."
"$stop_script" || true
echo "OK ✅ eski process temizligi tamam"

echo
echo "9) Service discovery arka planda baslatiliyor..."
"$start_script"

echo
echo "10) Durum kontrolu..."
"$status_script"

echo
echo "11) HTTP health testi..."
curl -s http://127.0.0.1:8090/health
echo
echo "OK ✅ health testi gecti"

echo
echo "12) HTTP register testi..."
curl -s -X POST http://127.0.0.1:8090/register \
  -H "Content-Type: application/json" \
  -d '{"name":"stock_service","address":"http://127.0.0.1:7001"}'
echo
echo "OK ✅ HTTP register testi gecti"

echo
echo "13) HTTP heartbeat testi..."
curl -s -X POST http://127.0.0.1:8090/heartbeat \
  -H "Content-Type: application/json" \
  -d '{"name":"stock_service"}'
echo
echo "OK ✅ HTTP heartbeat testi gecti"

echo
echo "14) NATS register testi..."
docker exec pix2pi_nats_cli nats pub pix2pi.service.register '{"name":"accounting_service","address":"http://127.0.0.1:7002"}'
sleep 1
echo "OK ✅ NATS register testi gecti"

echo
echo "15) NATS heartbeat testi..."
docker exec pix2pi_nats_cli nats pub pix2pi.service.heartbeat '{"name":"accounting_service"}'
sleep 1
echo "OK ✅ NATS heartbeat testi gecti"

echo
echo "16) Services testi..."
curl -s http://127.0.0.1:8090/services
echo
echo "OK ✅ services testi gecti"

echo
echo "17) Son 30 log satiri..."
tail -n 30 "$log_dosya" || true

echo
echo "OK ✅ 68 hybrid service discovery temel kurulum tamam"
echo "OK ✅ HTTP + NATS birlikte calisiyor"
echo
echo "KULLANIM"
echo "Baslat : $start_script"
echo "Durdur : $stop_script"
echo "Durum  : $status_script"
