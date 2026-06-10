package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/nats-io/nats.go"
)

type User struct {
	ID       string `json:"id"`
	Username string `json:"username"`
}

type RegisterRequest struct {
	Username string `json:"username"`
}

var nc *nats.Conn

func main() {

	var err error
	nc, err = nats.Connect(nats.DefaultURL)
	if err != nil {
		log.Fatal("❌ NATS bağlantı hatası:", err)
	}
	log.Println("OK ✅ NATS bağlı")

	http.HandleFunc("/register", registerHandler)

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(map[string]string{
			"status": "ok",
			"service": "identity",
		})
	})

	log.Println("🚀 Identity API running on :9012")

	err = http.ListenAndServe(":9012", nil)
	if err != nil {
		log.Fatal("❌ SERVER CRASH:", err)
	}
}

func registerHandler(w http.ResponseWriter, r *http.Request) {

	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid json", http.StatusBadRequest)
		return
	}

	user := User{
		ID:       fmt.Sprintf("%d", time.Now().UnixNano()),
		Username: req.Username,
	}

	event := map[string]interface{}{
		"event":      "user.created",
		"user_id":    user.ID,
		"username":   user.Username,
		"created_at": time.Now(),
	}

	data, _ := json.Marshal(event)

	err := nc.Publish("pix2pi.user.created", data)
	if err != nil {
		log.Println("❌ event publish hatası:", err)
		http.Error(w, "event error", 500)
		return
	}

	log.Println("OK ✅ event gönderildi:", string(data))

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "ok",
		"user":   user,
	})
}
