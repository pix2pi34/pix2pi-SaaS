package handler

import (
	"encoding/json"
	"net/http"
)

type PluginInfo struct {
	Name    string `json:"name"`
	Version string `json:"version"`
	Type    string `json:"type"`
}

func InfoHandler(w http.ResponseWriter, r *http.Request) {

	info := PluginInfo{
		Name:    "pix2pi-erp-plugin",
		Version: "0.1",
		Type:    "plugin",
	}

	w.Header().Set("Content-Type", "application/json")

	json.NewEncoder(w).Encode(info)
}
