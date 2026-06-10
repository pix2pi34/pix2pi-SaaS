package main

import (
	"strings"
	"testing"
)

func TestNormalizePort(t *testing.T) {
	if got := normalizePort(":7100", "9999"); got != "7100" {
		t.Fatalf("beklenen 7100, gelen %s", got)
	}

	if got := normalizePort("", "9999"); got != "9999" {
		t.Fatalf("bos port fallback olmali, gelen %s", got)
	}
}

func TestBuildTargets(t *testing.T) {
	t.Setenv("PANEL_PORT", "7100")
	t.Setenv("API_GATEWAY_PORT", "9010")
	t.Setenv("REGISTRY_PORT", "5870")

	targets := buildTargets()

	if len(targets) < 20 {
		t.Fatalf("ops console target sayisi az: %d", len(targets))
	}

	required := []string{
		"panel_health",
		"mission_control_health",
		"jobs_runtime_summary",
		"webhook_runtime_summary",
		"workflow_runtime_summary",
		"plugin_runtime_summary",
		"publicapi_runtime_summary",
		"notification_runtime_summary",
		"early_warning_runtime_summary",
		"incident_audit_runtime_summary",
		"runtime_topology_summary",
		"runtime_topology_nodes",
		"runtime_topology_edges",
		"runtime_topology_registry",
		"realtime_runtime_health",
		"realtime_runtime_summary",
		"realtime_runtime_tables",
		"realtime_runtime_channels",
		"realtime_runtime_connections",
		"realtime_runtime_presence",
		"realtime_runtime_permissions",
	}

	seen := map[string]bool{}
	for _, target := range targets {
		seen[target.Key] = true
		if strings.TrimSpace(target.URL) == "" {
			t.Fatalf("%s url bos olmamali", target.Key)
		}
	}

	for _, key := range required {
		if !seen[key] {
			t.Fatalf("zorunlu target eksik: %s", key)
		}
	}
}

func TestHasFailures(t *testing.T) {
	if hasFailures([]SmokeResult{{OK: true}, {OK: true}}) {
		t.Fatalf("hepsi OK iken failure olmamali")
	}

	if !hasFailures([]SmokeResult{{OK: true}, {OK: false}}) {
		t.Fatalf("bir FAIL varsa failure olmali")
	}
}
