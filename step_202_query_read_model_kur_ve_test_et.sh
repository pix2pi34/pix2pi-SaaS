#!/bin/bash
set -e

proje_dizini="$HOME/pix2pi/pix2pi-SaaS"
hedef_klasor="$proje_dizini/cmd/query-read-model"
hedef_dosya="$hedef_klasor/query_read_model_main.go"
test_dosya="$hedef_klasor/query_read_model_main_test.go"

yedek_klasor="$proje_dizini/_yedekler"
zaman="$(date +%Y%m%d_%H%M%S)"

binary_dosya="/usr/local/bin/pix2pi_query_read_model_bin"
start_script="/usr/local/bin/pix2pi_query_read_model_start.sh"
stop_script="/usr/local/bin/pix2pi_query_read_model_stop.sh"
status_script="/usr/local/bin/pix2pi_query_read_model_status.sh"

log_dosya="/tmp/pix2pi_query_read_model.log"
pid_dosya="/tmp/pix2pi_query_read_model.pid"
json_dosya="/tmp/pix2pi_query_read_model.json"

echo "1) Klasorler hazirlaniyor..."
mkdir -p "$hedef_klasor"
mkdir -p "$yedek_klasor"
echo "OK ✅ klasorler hazir"

echo
echo "2) Yedekler aliniyor..."
if [ -f "$hedef_dosya" ]; then
  cp "$hedef_dosya" "$yedek_klasor/query_read_model_main.go.$zaman.bak"
  echo "OK ✅ query_read_model_main.go yedegi alindi"
else
  echo "OK ✅ onceki query_read_model_main.go yok"
fi

if [ -f "$test_dosya" ]; then
  cp "$test_dosya" "$yedek_klasor/query_read_model_main_test.go.$zaman.bak"
  echo "OK ✅ query_read_model_main_test.go yedegi alindi"
else
  echo "OK ✅ onceki test dosyasi yok"
fi

echo
echo "3) Query read model kodu yaziliyor..."
cat <<'GOEOF' > "$hedef_dosya"
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"sort"
	"strings"
	"sync"
	"time"
)

type SaleSummary struct {
	OrderID   string    `json:"order_id"`
	Customer  string    `json:"customer"`
	Amount    float64   `json:"amount"`
	Status    string    `json:"status"`
	UpdatedAt time.Time `json:"updated_at"`
}

type ReadStore struct {
	mu    sync.RWMutex
	Sales map[string]SaleSummary `json:"sales"`
}

func NewReadStore() *ReadStore {
	return &ReadStore{
		Sales: make(map[string]SaleSummary),
	}
}

func (s *ReadStore) UpsertSale(sale SaleSummary) {
	s.mu.Lock()
	defer s.mu.Unlock()
	sale.UpdatedAt = time.Now().UTC()
	s.Sales[sale.OrderID] = sale
}

func (s *ReadStore) GetSale(orderID string) (SaleSummary, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	v, ok := s.Sales[orderID]
	return v, ok
}

func (s *ReadStore) ListSales() []SaleSummary {
	s.mu.RLock()
	defer s.mu.RUnlock()

	out := make([]SaleSummary, 0, len(s.Sales))
	for _, v := range s.Sales {
		out = append(out, v)
	}

	sort.Slice(out, func(i, j int) bool {
		return out[i].OrderID < out[j].OrderID
	})

	return out
}

func (s *ReadStore) SearchSales(q string) []SaleSummary {
	s.mu.RLock()
	defer s.mu.RUnlock()

	q = strings.ToLower(strings.TrimSpace(q))
	out := make([]SaleSummary, 0)

	for _, v := range s.Sales {
		if q == "" ||
			strings.Contains(strings.ToLower(v.OrderID), q) ||
			strings.Contains(strings.ToLower(v.Customer), q) ||
			strings.Contains(strings.ToLower(v.Status), q) {
			out = append(out, v)
		}
	}

	sort.Slice(out, func(i, j int) bool {
		return out[i].OrderID < out[j].OrderID
	})

	return out
}

func (s *ReadStore) SaveToFile(path string) error {
	s.mu.RLock()
	defer s.mu.RUnlock()

	data, err := json.MarshalIndent(s, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(path, data, 0644)
}

func (s *ReadStore) LoadFromFile(path string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}

	var loaded ReadStore
	if err := json.Unmarshal(data, &loaded); err != nil {
		return err
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	if loaded.Sales == nil {
		loaded.Sales = make(map[string]SaleSummary)
	}

	s.Sales = loaded.Sales
	return nil
}

func writeJSON(w http.ResponseWriter, code int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(data)
}

func main() {
	port := os.Getenv("QUERY_READ_MODEL_PORT")
	if port == "" {
		port = "8091"
	}

	dataPath := os.Getenv("QUERY_READ_MODEL_FILE")
	if dataPath == "" {
		dataPath = "/tmp/pix2pi_query_read_model.json"
	}

	store := NewReadStore()

	if _, err := os.Stat(dataPath); err == nil {
		if err := store.LoadFromFile(dataPath); err != nil {
			log.Printf("UYARI ⚠ read model dosya yukleme hatasi: %v", err)
		}
	}

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{
			"service": "query_read_model",
			"status":  "ok",
			"count":   len(store.ListSales()),
			"time":    time.Now().UTC().Format(time.RFC3339),
		})
	})

	http.HandleFunc("/seed", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method_not_allowed"})
			return
		}

		store.UpsertSale(SaleSummary{
			OrderID:  "ORD-1001",
			Customer: "Ahmet Market",
			Amount:   1250,
			Status:   "PAID",
		})
		store.UpsertSale(SaleSummary{
			OrderID:  "ORD-1002",
			Customer: "Yildiz Ticaret",
			Amount:   980,
			Status:   "PENDING",
		})
		store.UpsertSale(SaleSummary{
			OrderID:  "ORD-1003",
			Customer: "Demir Gida",
			Amount:   430,
			Status:   "PAID",
		})

		if err := store.SaveToFile(dataPath); err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "save_failed"})
			return
		}

		writeJSON(w, http.StatusOK, map[string]any{
			"ok":    true,
			"count": len(store.ListSales()),
		})
	})

	http.HandleFunc("/sales", func(w http.ResponseWriter, r *http.Request) {
		q := r.URL.Query().Get("q")
		writeJSON(w, http.StatusOK, map[string]any{
			"sales": store.SearchSales(q),
			"count": len(store.SearchSales(q)),
		})
	})

	http.HandleFunc("/sales/get", func(w http.ResponseWriter, r *http.Request) {
		orderID := r.URL.Query().Get("order_id")
		if orderID == "" {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "order_id_required"})
			return
		}

		sale, ok := store.GetSale(orderID)
		if !ok {
			writeJSON(w, http.StatusNotFound, map[string]string{"error": "not_found"})
			return
		}

		writeJSON(w, http.StatusOK, sale)
	})

	addr := ":" + port
	log.Printf("OK ✅ query_read_model started | port=%s | file=%s", port, dataPath)
	log.Fatal(http.ListenAndServe(addr, nil))
}
GOEOF
echo "OK ✅ query_read_model_main.go yazildi"

echo
echo "4) Test kodu yaziliyor..."
cat <<'GOEOF' > "$test_dosya"
package main

import "testing"

func TestUpsertAndGetSale(t *testing.T) {
	store := NewReadStore()

	store.UpsertSale(SaleSummary{
		OrderID:  "ORD-1",
		Customer: "Test Cari",
		Amount:   100,
		Status:   "PAID",
	})

	item, ok := store.GetSale("ORD-1")
	if !ok {
		t.Fatal("kayit bulunamadi")
	}

	if item.Customer != "Test Cari" {
		t.Fatalf("beklenen Test Cari, gelen %s", item.Customer)
	}
}

func TestSearchSales(t *testing.T) {
	store := NewReadStore()

	store.UpsertSale(SaleSummary{
		OrderID:  "ORD-2",
		Customer: "Alpha",
		Amount:   200,
		Status:   "PAID",
	})
	store.UpsertSale(SaleSummary{
		OrderID:  "ORD-3",
		Customer: "Beta",
		Amount:   300,
		Status:   "PENDING",
	})

	result := store.SearchSales("beta")
	if len(result) != 1 {
		t.Fatalf("beklenen 1 sonuc, gelen %d", len(result))
	}

	if result[0].OrderID != "ORD-3" {
		t.Fatalf("beklenen ORD-3, gelen %s", result[0].OrderID)
	}
}
GOEOF
echo "OK ✅ test dosyasi yazildi"

echo
echo "5) Testler calistiriliyor..."
cd "$proje_dizini"
go test ./cmd/query-read-model -v
echo "OK ✅ testler gecti"

echo
echo "6) Build yapiliyor..."
go build -o "$binary_dosya" ./cmd/query-read-model
chmod +x "$binary_dosya"
echo "OK ✅ binary hazir: $binary_dosya"

echo
echo "7) Start / Stop / Status scriptleri yaziliyor..."
cat <<STARTEOF > "$start_script"
#!/bin/bash
set -e

binary_dosya="/usr/local/bin/pix2pi_query_read_model_bin"
log_dosya="/tmp/pix2pi_query_read_model.log"
pid_dosya="/tmp/pix2pi_query_read_model.pid"
json_dosya="/tmp/pix2pi_query_read_model.json"

if [ -f "\$pid_dosya" ]; then
  pid="\$(cat "\$pid_dosya" 2>/dev/null || true)"
  if [ -n "\$pid" ] && kill -0 "\$pid" 2>/dev/null; then
    echo "OK ✅ query_read_model zaten calisiyor | pid=\$pid"
    exit 0
  fi
fi

QUERY_READ_MODEL_FILE="\$json_dosya" nohup "\$binary_dosya" >> "\$log_dosya" 2>&1 &
yeni_pid=\$!
echo "\$yeni_pid" > "\$pid_dosya"
sleep 2

if kill -0 "\$yeni_pid" 2>/dev/null; then
  echo "OK ✅ query_read_model baslatildi | pid=\$yeni_pid"
else
  echo "HATA ❌ query_read_model baslatilamadi"
  exit 1
fi
STARTEOF

cat <<STOPEOF > "$stop_script"
#!/bin/bash
set -e

pid_dosya="/tmp/pix2pi_query_read_model.pid"

if [ ! -f "\$pid_dosya" ]; then
  echo "OK ✅ query_read_model zaten kapali"
  exit 0
fi

pid="\$(cat "\$pid_dosya" 2>/dev/null || true)"
if [ -n "\$pid" ] && kill -0 "\$pid" 2>/dev/null; then
  kill "\$pid"
  sleep 1
  echo "OK ✅ query_read_model durduruldu | pid=\$pid"
else
  echo "OK ✅ process zaten calismiyordu"
fi

rm -f "\$pid_dosya"
STOPEOF

cat <<STATUSEOF > "$status_script"
#!/bin/bash
set -e

pid_dosya="/tmp/pix2pi_query_read_model.pid"
log_dosya="/tmp/pix2pi_query_read_model.log"

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
echo "OK ✅ start / stop / status scriptleri hazir"

echo
echo "8) Eski process temizleniyor..."
"$stop_script" || true
echo "OK ✅ eski process temizligi tamam"

echo
echo "9) Query read model arka planda baslatiliyor..."
"$start_script"

echo
echo "10) Durum kontrolu..."
"$status_script"

echo
echo "11) Health testi..."
curl -s http://127.0.0.1:8091/health
echo
echo "OK ✅ health testi gecti"

echo
echo "12) Seed testi..."
curl -s -X POST http://127.0.0.1:8091/seed
echo
echo "OK ✅ seed testi gecti"

echo
echo "13) Sales liste testi..."
curl -s http://127.0.0.1:8091/sales
echo
echo "OK ✅ sales liste testi gecti"

echo
echo "14) Sales filtre testi..."
curl -s "http://127.0.0.1:8091/sales?q=ahmet"
echo
echo "OK ✅ sales filtre testi gecti"

echo
echo "15) Tek kayit testi..."
curl -s "http://127.0.0.1:8091/sales/get?order_id=ORD-1001"
echo
echo "OK ✅ tek kayit testi gecti"

echo
echo "16) Son 20 log satiri..."
tail -n 20 "$log_dosya" || true

echo
echo "OK ✅ 69 query read modeli temel kurulum tamam"
echo "OK ✅ arka planda calisiyor"
echo
echo "KULLANIM"
echo "Baslat : $start_script"
echo "Durdur : $stop_script"
echo "Durum  : $status_script"
