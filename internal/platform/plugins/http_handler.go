package plugins

import (
	"encoding/json"
	"net/http"
)

func RegistryHandler(reg *Registry) http.HandlerFunc {

	return func(w http.ResponseWriter, r *http.Request) {

		w.Header().Set("Content-Type", "application/json")

		json.NewEncoder(w).Encode(reg.List())
	}
}
