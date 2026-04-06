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
