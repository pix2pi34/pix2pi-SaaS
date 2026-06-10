package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

type SmokeTarget struct {
	Key      string
	Name     string
	URL      string
	Expect   string
	Critical bool
}

type SmokeResult struct {
	Key       string
	Name      string
	URL       string
	OK        bool
	Status    int
	LatencyMs int64
	Message   string
}

func envOrDefault(key string, fallback string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}

	return value
}

func normalizePort(port string, fallback string) string {
	port = strings.TrimSpace(port)
	port = strings.TrimPrefix(port, ":")

	if port == "" {
		return fallback
	}

	return port
}

func baseURL() string {
	return strings.TrimRight(envOrDefault("OPS_CONSOLE_BASE_URL", "http://127.0.0.1:"+normalizePort(os.Getenv("PANEL_PORT"), "7100")), "/")
}

func directURL(port string, path string) string {
	return "http://127.0.0.1:" + port + path
}

func proxyURL(path string) string {
	return baseURL() + path
}

func buildTargets() []SmokeTarget {
	apiGatewayPort := normalizePort(os.Getenv("API_GATEWAY_PORT"), "9010")
	registryPort := normalizePort(os.Getenv("REGISTRY_PORT"), "5870")

	return []SmokeTarget{
		{
			Key:      "panel_health",
			Name:     "Control Panel Health",
			URL:      proxyURL("/health"),
			Expect:   `"status":"ok"`,
			Critical: true,
		},
		{
			Key:      "panel_index",
			Name:     "Control Panel UI Index",
			URL:      proxyURL("/"),
			Expect:   "Pix2pi Faz 1",
			Critical: true,
		},
		{
			Key:      "api_gateway_health",
			Name:     "API Gateway Health",
			URL:      directURL(apiGatewayPort, "/health"),
			Expect:   "Pix2pi API Gateway OK",
			Critical: true,
		},
		{
			Key:      "service_registry_health",
			Name:     "Service Registry Health",
			URL:      directURL(registryPort, "/health"),
			Expect:   "Pix2pi Service Registry OK",
			Critical: true,
		},
		{
			Key:      "mission_control_health",
			Name:     "Mission Control Health",
			URL:      proxyURL("/mission-control/health"),
			Expect:   "mission-control",
			Critical: true,
		},
		{
			Key:      "mission_control_services",
			Name:     "Mission Control Services",
			URL:      proxyURL("/mission-control/api/services"),
			Expect:   "service-registry",
			Critical: true,
		},
		{
			Key:      "jobs_runtime_health",
			Name:     "Jobs Runtime Health",
			URL:      proxyURL("/jobs-runtime/health"),
			Expect:   `"service":"jobs-runtime"`,
			Critical: true,
		},
		{
			Key:      "jobs_runtime_summary",
			Name:     "Jobs Runtime Summary",
			URL:      proxyURL("/jobs-runtime/api/jobs/summary"),
			Expect:   `"items"`,
			Critical: true,
		},
		{
			Key:      "webhook_runtime_health",
			Name:     "Webhook Runtime Health",
			URL:      proxyURL("/webhook-runtime/health"),
			Expect:   `"service":"webhook-runtime"`,
			Critical: true,
		},
		{
			Key:      "webhook_runtime_summary",
			Name:     "Webhook Runtime Summary",
			URL:      proxyURL("/webhook-runtime/api/webhooks/summary"),
			Expect:   `"items"`,
			Critical: true,
		},
		{
			Key:      "workflow_runtime_health",
			Name:     "Workflow Runtime Health",
			URL:      proxyURL("/workflow-runtime/health"),
			Expect:   `"service":"workflow-runtime"`,
			Critical: true,
		},
		{
			Key:      "workflow_runtime_summary",
			Name:     "Workflow Runtime Summary",
			URL:      proxyURL("/workflow-runtime/api/workflows/summary"),
			Expect:   `"items"`,
			Critical: true,
		},
		{
			Key:      "plugin_runtime_health",
			Name:     "Plugin Runtime Health",
			URL:      proxyURL("/plugin-runtime/health"),
			Expect:   `"service":"plugin-runtime"`,
			Critical: true,
		},
		{
			Key:      "plugin_runtime_summary",
			Name:     "Plugin Runtime Summary",
			URL:      proxyURL("/plugin-runtime/api/plugins/summary"),
			Expect:   `"items"`,
			Critical: true,
		},
		{
			Key:      "publicapi_runtime_health",
			Name:     "Public API Runtime Health",
			URL:      proxyURL("/publicapi-runtime/health"),
			Expect:   `"service":"publicapi-runtime"`,
			Critical: true,
		},
		{
			Key:      "publicapi_runtime_summary",
			Name:     "Public API Runtime Summary",
			URL:      proxyURL("/publicapi-runtime/api/publicapi/summary"),
			Expect:   `"items"`,
			Critical: true,
		},
		{
			Key:      "notification_runtime_health",
			Name:     "Notification Runtime Health",
			URL:      proxyURL("/notification-runtime/health"),
			Expect:   `"service":"notification-runtime"`,
			Critical: true,
		},
		{
			Key:      "notification_runtime_summary",
			Name:     "Notification Runtime Summary",
			URL:      proxyURL("/notification-runtime/api/notifications/summary"),
			Expect:   `"items"`,
			Critical: true,
		},
		{
			Key:      "early_warning_runtime_health",
			Name:     "Early Warning Runtime Health",
			URL:      proxyURL("/early-warning-runtime/health"),
			Expect:   `"service":"early-warning-runtime"`,
			Critical: true,
		},
		{
			Key:      "early_warning_runtime_summary",
			Name:     "Early Warning Runtime Summary",
			URL:      proxyURL("/early-warning-runtime/api/early-warning/summary"),
			Expect:   `"alert_level"`,
			Critical: true,
		},
		{
			Key:      "incident_audit_runtime_health",
			Name:     "Incident Audit Runtime Health",
			URL:      proxyURL("/incident-audit-runtime/health"),
			Expect:   `"service":"incident-audit-runtime"`,
			Critical: true,
		},
		{
			Key:      "incident_audit_runtime_summary",
			Name:     "Incident Audit Runtime Summary",
			URL:      proxyURL("/incident-audit-runtime/api/incident-audit/summary"),
			Expect:   `"audit_log_count"`,
			Critical: true,
		},
		{
			Key:      "runtime_topology_health",
			Name:     "Runtime Topology Health",
			URL:      proxyURL("/runtime-topology/health"),
			Expect:   `"service":"runtime-topology"`,
			Critical: true,
		},
		{
			Key:      "runtime_topology_summary",
			Name:     "Runtime Topology Summary",
			URL:      proxyURL("/runtime-topology/api/runtime-topology/summary"),
			Expect:   `"topology_status"`,
			Critical: true,
		},
		{
			Key:      "runtime_topology_nodes",
			Name:     "Runtime Topology Nodes",
			URL:      proxyURL("/runtime-topology/api/runtime-topology/nodes"),
			Expect:   `"node_key"`,
			Critical: true,
		},
		{
			Key:      "runtime_topology_edges",
			Name:     "Runtime Topology Edges",
			URL:      proxyURL("/runtime-topology/api/runtime-topology/edges"),
			Expect:   `"from_node"`,
			Critical: true,
		},
		{
			Key:      "runtime_topology_registry",
			Name:     "Runtime Topology Registry",
			URL:      proxyURL("/runtime-topology/api/runtime-topology/registry"),
			Expect:   `"runtime.service_registry_services"`,
			Critical: true,
		},
		{
			Key:      "realtime_runtime_health",
			Name:     "Realtime Runtime Health",
			URL:      proxyURL("/realtime-runtime/health"),
			Expect:   `"service":"realtime-runtime"`,
			Critical: true,
		},
		{
			Key:      "realtime_runtime_summary",
			Name:     "Realtime Runtime Summary",
			URL:      proxyURL("/realtime-runtime/api/realtime/summary"),
			Expect:   `"connection_count"`,
			Critical: true,
		},
		{
			Key:      "realtime_runtime_tables",
			Name:     "Realtime Runtime Tables",
			URL:      proxyURL("/realtime-runtime/api/realtime/tables"),
			Expect:   `"runtime.notification_channels"`,
			Critical: true,
		},
		{
			Key:      "realtime_runtime_channels",
			Name:     "Realtime Runtime Channels",
			URL:      proxyURL("/realtime-runtime/api/realtime/channels"),
			Expect:   `"items"`,
			Critical: true,
		},
		{
			Key:      "realtime_runtime_connections",
			Name:     "Realtime Runtime Connections",
			URL:      proxyURL("/realtime-runtime/api/realtime/connections"),
			Expect:   `"items"`,
			Critical: true,
		},
		{
			Key:      "realtime_runtime_presence",
			Name:     "Realtime Runtime Presence",
			URL:      proxyURL("/realtime-runtime/api/realtime/presence"),
			Expect:   `"items"`,
			Critical: true,
		},
		{
			Key:      "realtime_runtime_permissions",
			Name:     "Realtime Runtime Permissions",
			URL:      proxyURL("/realtime-runtime/api/realtime/permissions"),
			Expect:   `"items"`,
			Critical: true,
		},
	}
}

func checkTarget(client *http.Client, target SmokeTarget) SmokeResult {
	startedAt := time.Now()

	resp, err := client.Get(target.URL)
	latencyMs := time.Since(startedAt).Milliseconds()

	if err != nil {
		return SmokeResult{
			Key:       target.Key,
			Name:      target.Name,
			URL:       target.URL,
			OK:        false,
			Status:    0,
			LatencyMs: latencyMs,
			Message:   err.Error(),
		}
	}

	defer resp.Body.Close()

	bodyBytes, err := io.ReadAll(io.LimitReader(resp.Body, 1024*1024))
	if err != nil {
		return SmokeResult{
			Key:       target.Key,
			Name:      target.Name,
			URL:       target.URL,
			OK:        false,
			Status:    resp.StatusCode,
			LatencyMs: latencyMs,
			Message:   err.Error(),
		}
	}

	body := string(bodyBytes)

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return SmokeResult{
			Key:       target.Key,
			Name:      target.Name,
			URL:       target.URL,
			OK:        false,
			Status:    resp.StatusCode,
			LatencyMs: latencyMs,
			Message:   fmt.Sprintf("beklenmeyen http status: %d", resp.StatusCode),
		}
	}

	if target.Expect != "" && !strings.Contains(body, target.Expect) {
		return SmokeResult{
			Key:       target.Key,
			Name:      target.Name,
			URL:       target.URL,
			OK:        false,
			Status:    resp.StatusCode,
			LatencyMs: latencyMs,
			Message:   "beklenen icerik bulunamadi: " + target.Expect,
		}
	}

	return SmokeResult{
		Key:       target.Key,
		Name:      target.Name,
		URL:       target.URL,
		OK:        true,
		Status:    resp.StatusCode,
		LatencyMs: latencyMs,
		Message:   "OK",
	}
}

func runSmoke(targets []SmokeTarget) []SmokeResult {
	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	results := make([]SmokeResult, 0, len(targets))

	for _, target := range targets {
		results = append(results, checkTarget(client, target))
	}

	return results
}

func hasFailures(results []SmokeResult) bool {
	for _, result := range results {
		if !result.OK {
			return true
		}
	}

	return false
}

func main() {
	targets := buildTargets()
	results := runSmoke(targets)

	fmt.Println("===== OPS CONSOLE GENERAL SMOKE REPORT =====")
	fmt.Printf("base_url=%s\n", baseURL())
	fmt.Printf("target_count=%d\n", len(targets))

	okCount := 0
	failCount := 0

	for _, result := range results {
		status := "OK"
		if !result.OK {
			status = "FAIL"
			failCount++
		} else {
			okCount++
		}

		fmt.Printf(
			"[%s] %-36s status=%d latency_ms=%d url=%s message=%s\n",
			status,
			result.Key,
			result.Status,
			result.LatencyMs,
			result.URL,
			result.Message,
		)
	}

	fmt.Printf("summary_ok=%d summary_fail=%d\n", okCount, failCount)

	if hasFailures(results) {
		os.Exit(1)
	}
}
