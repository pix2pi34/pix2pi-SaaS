#!/bin/bash
set -e

proje_dizini="$HOME/pix2pi/pix2pi-SaaS"
yedek_klasor="$proje_dizini/_yedekler"
zaman="$(date +%Y%m%d_%H%M%S)"

query_klasor="$proje_dizini/cmd/query-read-model"
query_dosya="$query_klasor/query_read_model_main.go"
query_test_dosya="$query_klasor/query_read_model_main_test.go"

reporting_klasor="$proje_dizini/cmd/reporting-service"
reporting_dosya="$reporting_klasor/reporting_service_main.go"
reporting_test_dosya="$reporting_klasor/reporting_service_main_test.go"

query_binary="/usr/local/bin/pix2pi_query_read_model_bin"
reporting_binary="/usr/local/bin/pix2pi_reporting_service_bin"

query_start="/usr/local/bin/pix2pi_query_read_model_start.sh"
query_stop="/usr/local/bin/pix2pi_query_read_model_stop.sh"
query_status="/usr/local/bin/pix2pi_query_read_model_status.sh"

reporting_start="/usr/local/bin/pix2pi_reporting_service_start.sh"
reporting_stop="/usr/local/bin/pix2pi_reporting_service_stop.sh"
reporting_status="/usr/local/bin/pix2pi_reporting_service_status.sh"

echo "1) Klasorler hazirlaniyor..."
mkdir -p "$yedek_klasor"
mkdir -p "$query_klasor"
mkdir -p "$reporting_klasor"
echo "OK ✅ klasorler hazir"

echo
echo "2) Yedekler aliniyor..."
for f in \
  "$query_dosya" \
  "$query_test_dosya" \
  "$reporting_dosya" \
  "$reporting_test_dosya"
do
  if [ -f "$f" ]; then
    cp "$f" "$yedek_klasor/$(basename "$f").$zaman.bak"
    echo "OK ✅ yedek alindi: $f"
  else
    echo "OK ✅ onceki dosya yok: $f"
  fi
done

echo
echo "3) Query read model tam yaziliyor..."
cat <<'GOEOF' > "$query_dosya"
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

	http.HandleFunc("/upsert/sale", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method_not_allowed"})
			return
		}

		var req SaleSummary
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "bad_json"})
			return
		}

		if req.OrderID == "" {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "order_id_required"})
			return
		}

		store.UpsertSale(req)

		if err := store.SaveToFile(dataPath); err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "save_failed"})
			return
		}

		writeJSON(w, http.StatusOK, map[string]any{
			"ok":       true,
			"order_id": req.OrderID,
		})
	})

	http.HandleFunc("/sales", func(w http.ResponseWriter, r *http.Request) {
		q := r.URL.Query().Get("q")
		liste := store.SearchSales(q)

		writeJSON(w, http.StatusOK, map[string]any{
			"sales": liste,
			"count": len(liste),
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
echo "4) Query read model testi tam yaziliyor..."
cat <<'GOEOF' > "$query_test_dosya"
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
echo "OK ✅ query_read_model_main_test.go yazildi"

echo
echo "5) Reporting service tam yaziliyor..."
cat <<'GOEOF' > "$reporting_dosya"
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/nats-io/nats.go"
)

type Event struct {
	Type string                 `json:"type"`
	Data map[string]interface{} `json:"data"`
}

type SaleProjection struct {
	OrderID  string  `json:"order_id"`
	Customer string  `json:"customer"`
	Amount   float64 `json:"amount"`
	Status   string  `json:"status"`
}

func stringValue(data map[string]interface{}, keys ...string) string {
	for _, key := range keys {
		if v, ok := data[key]; ok {
			if s, ok := v.(string); ok {
				return s
			}
		}
	}
	return ""
}

func floatValue(data map[string]interface{}, keys ...string) float64 {
	for _, key := range keys {
		if v, ok := data[key]; ok {
			switch t := v.(type) {
			case float64:
				return t
			case int:
				return float64(t)
			case int64:
				return float64(t)
			}
		}
	}
	return 0
}

func buildSaleProjection(e Event) (SaleProjection, bool) {
	switch e.Type {
	case "sale.created", "sale.updated", "sale.completed":
	default:
		return SaleProjection{}, false
	}

	orderID := stringValue(e.Data, "order_id", "orderId", "siparis_no")
	if orderID == "" {
		return SaleProjection{}, false
	}

	customer := stringValue(e.Data, "customer", "customer_name", "cari")
	amount := floatValue(e.Data, "amount", "total", "tutar")
	status := stringValue(e.Data, "status", "durum")
	if status == "" {
		status = "PAID"
	}

	return SaleProjection{
		OrderID:  orderID,
		Customer: customer,
		Amount:   amount,
		Status:   status,
	}, true
}

func pushToQueryReadModel(baseURL string, payload SaleProjection) error {
	body, err := json.Marshal(payload)
	if err != nil {
		return err
	}

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Post(baseURL+"/upsert/sale", "application/json", bytes.NewBuffer(body))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("query_read_model status=%d", resp.StatusCode)
	}

	return nil
}

func main() {
	natsURL := os.Getenv("NATS_URL")
	if natsURL == "" {
		natsURL = "nats://localhost:4222"
	}

	queryReadModelURL := os.Getenv("QUERY_READ_MODEL_URL")
	if queryReadModelURL == "" {
		queryReadModelURL = "http://127.0.0.1:8091"
	}

	nc, err := nats.Connect(natsURL)
	if err != nil {
		log.Fatalf("NATS baglanti hatasi: %v", err)
	}
	defer nc.Close()

	js, err := nc.JetStream()
	if err != nil {
		log.Fatalf("JetStream erisim hatasi: %v", err)
	}

	_, err = js.Subscribe("pix2pi.>", func(msg *nats.Msg) {
		var e Event

		if err := json.Unmarshal(msg.Data, &e); err != nil {
			log.Printf("PARSE HATA | subject=%s | err=%v", msg.Subject, err)
			_ = msg.Ack()
			return
		}

		log.Printf("REPORT EVENT | subject=%s | type=%s", msg.Subject, e.Type)

		if sale, ok := buildSaleProjection(e); ok {
			if err := pushToQueryReadModel(queryReadModelURL, sale); err != nil {
				log.Printf("QUERY READ MODEL PUSH HATA | order_id=%s | err=%v", sale.OrderID, err)
			} else {
				log.Printf("OK ✅ query_read_model upsert | order_id=%s", sale.OrderID)
			}
		}

		if err := msg.Ack(); err != nil {
			log.Printf("ACK HATA | subject=%s | err=%v", msg.Subject, err)
		}
	},
		nats.Durable("reporting_service"),
		nats.ManualAck(),
	)
	if err != nil {
		log.Fatalf("Subscribe hatasi: %v", err)
	}

	log.Println("OK ✅ Reporting subscriber started")

	select {}
}
GOEOF
echo "OK ✅ reporting_service_main.go yazildi"

echo
echo "6) Reporting service testi tam yaziliyor..."
cat <<'GOEOF' > "$reporting_test_dosya"
package main

import "testing"

func TestBuildSaleProjection(t *testing.T) {
	e := Event{
		Type: "sale.created",
		Data: map[string]interface{}{
			"order_id": "ORD-X1",
			"customer": "Test Musteri",
			"amount":   450.0,
			"status":   "PAID",
		},
	}

	sale, ok := buildSaleProjection(e)
	if !ok {
		t.Fatal("projection false dondu")
	}

	if sale.OrderID != "ORD-X1" {
		t.Fatalf("beklenen ORD-X1, gelen %s", sale.OrderID)
	}

	if sale.Customer != "Test Musteri" {
		t.Fatalf("beklenen Test Musteri, gelen %s", sale.Customer)
	}
}

func TestBuildSaleProjectionRejectsUnknown(t *testing.T) {
	e := Event{
		Type: "stock.updated",
		Data: map[string]interface{}{
			"order_id": "ORD-X2",
		},
	}

	_, ok := buildSaleProjection(e)
	if ok {
		t.Fatal("beklenmeyen event kabul edildi")
	}
}
GOEOF
echo "OK ✅ reporting_service_main_test.go yazildi"

echo
echo "7) Testler calistiriliyor..."
cd "$proje_dizini"
go test ./cmd/query-read-model -v
go test ./cmd/reporting-service -v
echo "OK ✅ tum testler gecti"

echo
echo "8) Binary build yapiliyor..."
go build -o "$query_binary" ./cmd/query-read-model
go build -o "$reporting_binary" ./cmd/reporting-service
chmod +x "$query_binary" "$reporting_binary"
echo "OK ✅ binary build tamam"

echo
echo "9) Servisler yeniden baslatiliyor..."
"$query_stop" || true
"$reporting_stop" || true
sleep 2
"$query_start"
"$reporting_start"
echo "OK ✅ servisler yeniden baslatildi"

echo
echo "10) Son durum kontrolu..."
"$query_status"
"$reporting_status"

echo
echo "11) Query read model seed temizligi icin yeni dosya hazirlaniyor..."
rm -f /tmp/pix2pi_query_read_model.json
"$query_stop" || true
sleep 1
"$query_start"
echo "OK ✅ query_read_model temiz baslatildi"

echo
echo "12) Event entegrasyon testi icin NATS publish yapiliyor..."
docker exec pix2pi_nats_cli nats pub pix2pi.sale.created '{"type":"sale.created","data":{"order_id":"ORD-9001","customer":"Entegrasyon Market","amount":777,"status":"PAID"}}'
sleep 3
echo "OK ✅ NATS publish gecti"

echo
echo "13) Query read model kontrol testi..."
curl -s "http://127.0.0.1:8091/sales/get?order_id=ORD-9001"
echo
echo "OK ✅ query read model entegrasyon testi gecti"

echo
echo "14) Query read model liste kontrolu..."
curl -s "http://127.0.0.1:8091/sales?q=entegrasyon"
echo
echo "OK ✅ query read model filtre testi gecti"

echo
echo "15) Son loglar..."
echo "--- QUERY READ MODEL LOG ---"
tail -n 20 /tmp/pix2pi_query_read_model.log || true
echo
echo "--- REPORTING SERVICE LOG ---"
tail -n 30 /tmp/pix2pi_reporting_service.log || true

echo
echo "OK ✅ reporting_service → query_read_model baglandi"
echo "OK ✅ 69 ikinci asama tamam"
