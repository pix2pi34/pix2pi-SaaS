package main

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/nats-io/nats.go"
)

type ReplayRequest struct {
	Subject string `json:"subject"`
	Data    string `json:"data"`
}

func main() {

	nc, err := nats.Connect(nats.DefaultURL)
	if err != nil {
		log.Fatal(err)
	}

	http.HandleFunc("/replay", func(w http.ResponseWriter, r *http.Request) {

		var req ReplayRequest

		err := json.NewDecoder(r.Body).Decode(&req)
		if err != nil {
			http.Error(w, "bad request", 400)
			return
		}

		err = nc.Publish(req.Subject, []byte(req.Data))
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}

		log.Println("event replay edildi:", req.Subject)

		w.Write([]byte("OK"))
	})

	log.Println("replay service basladi :9012")

	http.ListenAndServe(":9012", nil)
}
