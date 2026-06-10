package main

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	_ "github.com/lib/pq"
)

type RuntimeTopologyConfig struct {
	Port    string
	DSN     string
	Targets []TopologyTarget
	Edges   []TopologyEdge
}

type TopologyTarget struct {
	NodeKey   string `json:"node_key"`
	Display   string `json:"display"`
	NodeType  string `json:"node_type"`
	Layer     string `json:"layer"`
	CheckMode string `json:"check_mode"`
	Port      string `json:"port"`
	URL       string `json:"url"`
	Address   string `json:"address"`
}

type TopologyNode struct {
	NodeKey    string `json:"node_key"`
	Display    string `json:"display"`
	NodeType   string `json:"node_type"`
	Layer      string `json:"layer"`
	CheckMode  string `json:"check_mode"`
	Port       string `json:"port"`
	URL        string `json:"url"`
	Address    string `json:"address"`
	Status     string `json:"status"`
	HTTPStatus int    `json:"http_status"`
	LatencyMs  int64  `json:"latency_ms"`
	Message    string `json:"message"`
	CheckedAt  string `json:"checked_at"`
}

type TopologyEdge struct {
	FromNode string `json:"from_node"`
	ToNode   string `json:"to_node"`
	Relation string `json:"relation"`
	Protocol string `json:"protocol"`
}

type RuntimeTopologySummary struct {
	TopologyStatus         string `json:"topology_status"`
	NodeCount              int    `json:"node_count"`
	NodeOKCount            int    `json:"node_ok_count"`
	NodeFailCount          int    `json:"node_fail_count"`
	EdgeCount              int    `json:"edge_count"`
	RegistryServiceCount   int    `json:"registry_service_count"`
	RegistryInstanceCount  int    `json:"registry_instance_count"`
	RegistryHeartbeatCount int    `json:"registry_heartbeat_count"`
	GeneratedAt            string `json:"generated_at"`
}

type RegistryCountItem struct {
	TableName   string `json:"table_name"`
	Count       int    `json:"count"`
	GeneratedAt string `json:"generated_at"`
}

func envOrDefault(key string, fallback string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}

	return value
}

func normalizePort(port string) string {
	port = strings.TrimSpace(port)
	port = strings.TrimPrefix(port, ":")

	if port == "" {
		return "5960"
	}

	return port
}

func parseLimit(raw string, fallback int, max int) int {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return fallback
	}

	n, err := strconv.Atoi(raw)
	if err != nil || n < 1 {
		return fallback
	}

	if n > max {
		return max
	}

	return n
}

func loadConfig() RuntimeTopologyConfig {
	dsn := envOrDefault("DB_READ_DSN", "")
	if dsn == "" {
		dsn = envOrDefault("DB_WRITE_DSN", "")
	}

	panelPort := normalizePort(envOrDefault("PANEL_PORT", "7100"))
	apiGatewayPort := normalizePort(envOrDefault("API_GATEWAY_PORT", "9010"))
	missionPort := normalizePort(envOrDefault("MISSION_PORT", "5860"))
	registryPort := normalizePort(envOrDefault("REGISTRY_PORT", "5870"))
	jobsRuntimePort := normalizePort(envOrDefault("JOBS_RUNTIME_PORT", "5880"))
	webhookRuntimePort := normalizePort(envOrDefault("WEBHOOK_RUNTIME_PORT", "5890"))
	workflowRuntimePort := normalizePort(envOrDefault("WORKFLOW_RUNTIME_PORT", "5900"))
	pluginRuntimePort := normalizePort(envOrDefault("PLUGIN_RUNTIME_PORT", "5910"))
	publicAPIRuntimePort := normalizePort(envOrDefault("PUBLICAPI_RUNTIME_PORT", "5920"))
	notificationRuntimePort := normalizePort(envOrDefault("NOTIFICATION_RUNTIME_PORT", "5930"))
	earlyWarningRuntimePort := normalizePort(envOrDefault("EARLY_WARNING_RUNTIME_PORT", "5940"))
	incidentAuditRuntimePort := normalizePort(envOrDefault("INCIDENT_AUDIT_RUNTIME_PORT", "5950"))

	targets := []TopologyTarget{
		{NodeKey: "nginx_http", Display: "Nginx HTTP", NodeType: "edge", Layer: "edge", CheckMode: "tcp", Port: "80", Address: "127.0.0.1:80"},
		{NodeKey: "nginx_https", Display: "Nginx HTTPS", NodeType: "edge", Layer: "edge", CheckMode: "tcp", Port: "443", Address: "127.0.0.1:443"},
		{NodeKey: "control_panel", Display: "Control Panel", NodeType: "app", Layer: "console", CheckMode: "http", Port: panelPort, URL: "http://127.0.0.1:" + panelPort + "/health"},
		{NodeKey: "api_gateway", Display: "API Gateway", NodeType: "gateway", Layer: "gateway", CheckMode: "http", Port: apiGatewayPort, URL: "http://127.0.0.1:" + apiGatewayPort + "/health"},
		{NodeKey: "mission_control", Display: "Mission Control", NodeType: "runtime", Layer: "operations", CheckMode: "http", Port: missionPort, URL: "http://127.0.0.1:" + missionPort + "/health"},
		{NodeKey: "service_registry", Display: "Service Registry", NodeType: "runtime", Layer: "operations", CheckMode: "http", Port: registryPort, URL: "http://127.0.0.1:" + registryPort + "/health"},
		{NodeKey: "jobs_runtime", Display: "Jobs Runtime", NodeType: "runtime", Layer: "operations", CheckMode: "http", Port: jobsRuntimePort, URL: "http://127.0.0.1:" + jobsRuntimePort + "/health"},
		{NodeKey: "webhook_runtime", Display: "Webhook Runtime", NodeType: "runtime", Layer: "operations", CheckMode: "http", Port: webhookRuntimePort, URL: "http://127.0.0.1:" + webhookRuntimePort + "/health"},
		{NodeKey: "workflow_runtime", Display: "Workflow Runtime", NodeType: "runtime", Layer: "operations", CheckMode: "http", Port: workflowRuntimePort, URL: "http://127.0.0.1:" + workflowRuntimePort + "/health"},
		{NodeKey: "plugin_runtime", Display: "Plugin Runtime", NodeType: "runtime", Layer: "operations", CheckMode: "http", Port: pluginRuntimePort, URL: "http://127.0.0.1:" + pluginRuntimePort + "/health"},
		{NodeKey: "publicapi_runtime", Display: "Public API Runtime", NodeType: "runtime", Layer: "operations", CheckMode: "http", Port: publicAPIRuntimePort, URL: "http://127.0.0.1:" + publicAPIRuntimePort + "/health"},
		{NodeKey: "notification_runtime", Display: "Notification Runtime", NodeType: "runtime", Layer: "operations", CheckMode: "http", Port: notificationRuntimePort, URL: "http://127.0.0.1:" + notificationRuntimePort + "/health"},
		{NodeKey: "early_warning_runtime", Display: "Early Warning Runtime", NodeType: "runtime", Layer: "observability", CheckMode: "http", Port: earlyWarningRuntimePort, URL: "http://127.0.0.1:" + earlyWarningRuntimePort + "/health"},
		{NodeKey: "incident_audit_runtime", Display: "Incident Audit Runtime", NodeType: "runtime", Layer: "observability", CheckMode: "http", Port: incidentAuditRuntimePort, URL: "http://127.0.0.1:" + incidentAuditRuntimePort + "/health"},
	}

	edges := []TopologyEdge{
		{FromNode: "nginx_https", ToNode: "control_panel", Relation: "serves", Protocol: "https"},
		{FromNode: "control_panel", ToNode: "api_gateway", Relation: "proxies", Protocol: "http"},
		{FromNode: "control_panel", ToNode: "mission_control", Relation: "proxies", Protocol: "http"},
		{FromNode: "control_panel", ToNode: "service_registry", Relation: "proxies", Protocol: "http"},
		{FromNode: "control_panel", ToNode: "jobs_runtime", Relation: "proxies", Protocol: "http"},
		{FromNode: "control_panel", ToNode: "webhook_runtime", Relation: "proxies", Protocol: "http"},
		{FromNode: "control_panel", ToNode: "workflow_runtime", Relation: "proxies", Protocol: "http"},
		{FromNode: "control_panel", ToNode: "plugin_runtime", Relation: "proxies", Protocol: "http"},
		{FromNode: "control_panel", ToNode: "publicapi_runtime", Relation: "proxies", Protocol: "http"},
		{FromNode: "control_panel", ToNode: "notification_runtime", Relation: "proxies", Protocol: "http"},
		{FromNode: "control_panel", ToNode: "early_warning_runtime", Relation: "proxies", Protocol: "http"},
		{FromNode: "control_panel", ToNode: "incident_audit_runtime", Relation: "proxies", Protocol: "http"},
		{FromNode: "early_warning_runtime", ToNode: "api_gateway", Relation: "checks", Protocol: "http"},
		{FromNode: "early_warning_runtime", ToNode: "mission_control", Relation: "checks", Protocol: "http"},
		{FromNode: "early_warning_runtime", ToNode: "service_registry", Relation: "checks", Protocol: "http"},
		{FromNode: "incident_audit_runtime", ToNode: "mission_control", Relation: "reads incidents", Protocol: "sql"},
		{FromNode: "incident_audit_runtime", ToNode: "postgres_db", Relation: "reads audit", Protocol: "sql"},
		{FromNode: "service_registry", ToNode: "postgres_db", Relation: "stores registry", Protocol: "sql"},
	}

	return RuntimeTopologyConfig{
		Port:    normalizePort(envOrDefault("RUNTIME_TOPOLOGY_PORT", "5960")),
		DSN:     dsn,
		Targets: targets,
		Edges:   edges,
	}
}

func openDB(dsn string) (*sql.DB, error) {
	if strings.TrimSpace(dsn) == "" {
		return nil, errors.New("DB_READ_DSN veya DB_WRITE_DSN bos")
	}

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, err
	}

	db.SetMaxOpenConns(5)
	db.SetMaxIdleConns(2)
	db.SetConnMaxLifetime(5 * time.Minute)

	return db, nil
}

func checkHTTP(target TopologyTarget) TopologyNode {
	startedAt := time.Now()
	checkedAt := startedAt.UTC().Format(time.RFC3339)

	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get(target.URL)
	latencyMs := time.Since(startedAt).Milliseconds()

	if err != nil {
		return nodeFromTarget(target, "fail", 0, latencyMs, err.Error(), checkedAt)
	}
	defer resp.Body.Close()
	_, _ = io.Copy(io.Discard, resp.Body)

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nodeFromTarget(target, "fail", resp.StatusCode, latencyMs, fmt.Sprintf("http status %d", resp.StatusCode), checkedAt)
	}

	return nodeFromTarget(target, "ok", resp.StatusCode, latencyMs, "service healthy", checkedAt)
}

func checkTCP(target TopologyTarget) TopologyNode {
	startedAt := time.Now()
	checkedAt := startedAt.UTC().Format(time.RFC3339)

	conn, err := net.DialTimeout("tcp", target.Address, 2*time.Second)
	latencyMs := time.Since(startedAt).Milliseconds()

	if err != nil {
		return nodeFromTarget(target, "fail", 0, latencyMs, err.Error(), checkedAt)
	}

	_ = conn.Close()
	return nodeFromTarget(target, "ok", 0, latencyMs, "tcp listen active", checkedAt)
}

func nodeFromTarget(target TopologyTarget, status string, httpStatus int, latencyMs int64, message string, checkedAt string) TopologyNode {
	return TopologyNode{
		NodeKey:    target.NodeKey,
		Display:    target.Display,
		NodeType:   target.NodeType,
		Layer:      target.Layer,
		CheckMode:  target.CheckMode,
		Port:       target.Port,
		URL:        target.URL,
		Address:    target.Address,
		Status:     status,
		HTTPStatus: httpStatus,
		LatencyMs:  latencyMs,
		Message:    message,
		CheckedAt:  checkedAt,
	}
}

func dbNode(db *sql.DB) TopologyNode {
	now := time.Now().UTC().Format(time.RFC3339)
	startedAt := time.Now()

	if db == nil {
		return TopologyNode{
			NodeKey:   "postgres_db",
			Display:   "PostgreSQL DB",
			NodeType:  "database",
			Layer:     "data",
			CheckMode: "sql",
			Status:    "fail",
			Message:   "db baglantisi yok",
			CheckedAt: now,
		}
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		return TopologyNode{
			NodeKey:   "postgres_db",
			Display:   "PostgreSQL DB",
			NodeType:  "database",
			Layer:     "data",
			CheckMode: "sql",
			Status:    "fail",
			LatencyMs: time.Since(startedAt).Milliseconds(),
			Message:   err.Error(),
			CheckedAt: now,
		}
	}

	return TopologyNode{
		NodeKey:   "postgres_db",
		Display:   "PostgreSQL DB",
		NodeType:  "database",
		Layer:     "data",
		CheckMode: "sql",
		Status:    "ok",
		LatencyMs: time.Since(startedAt).Milliseconds(),
		Message:   "database healthy",
		CheckedAt: now,
	}
}

func listNodes(db *sql.DB, targets []TopologyTarget) []TopologyNode {
	items := make([]TopologyNode, 0, len(targets)+1)

	for _, target := range targets {
		switch strings.ToLower(target.CheckMode) {
		case "tcp":
			items = append(items, checkTCP(target))
		default:
			items = append(items, checkHTTP(target))
		}
	}

	items = append(items, dbNode(db))
	return items
}

func countTable(db *sql.DB, tableName string) int {
	if db == nil {
		return 0
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	query := fmt.Sprintf("select count(*) from %s", tableName)

	var count int
	if err := db.QueryRowContext(ctx, query).Scan(&count); err != nil {
		return 0
	}

	return count
}

func topologyStatus(nodes []TopologyNode) string {
	for _, node := range nodes {
		if node.Status != "ok" {
			return "degraded"
		}
	}

	return "ok"
}

func buildSummary(db *sql.DB, nodes []TopologyNode, edges []TopologyEdge) RuntimeTopologySummary {
	okCount := 0
	failCount := 0

	for _, node := range nodes {
		if node.Status == "ok" {
			okCount++
		} else {
			failCount++
		}
	}

	return RuntimeTopologySummary{
		TopologyStatus:         topologyStatus(nodes),
		NodeCount:              len(nodes),
		NodeOKCount:            okCount,
		NodeFailCount:          failCount,
		EdgeCount:              len(edges),
		RegistryServiceCount:   countTable(db, "runtime.service_registry_services"),
		RegistryInstanceCount:  countTable(db, "runtime.service_registry_instances"),
		RegistryHeartbeatCount: countTable(db, "runtime.service_registry_heartbeats"),
		GeneratedAt:            time.Now().UTC().Format(time.RFC3339),
	}
}

func registryCounts(db *sql.DB) []RegistryCountItem {
	now := time.Now().UTC().Format(time.RFC3339)

	return []RegistryCountItem{
		{
			TableName:   "runtime.service_registry_services",
			Count:       countTable(db, "runtime.service_registry_services"),
			GeneratedAt: now,
		},
		{
			TableName:   "runtime.service_registry_instances",
			Count:       countTable(db, "runtime.service_registry_instances"),
			GeneratedAt: now,
		},
		{
			TableName:   "runtime.service_registry_heartbeats",
			Count:       countTable(db, "runtime.service_registry_heartbeats"),
			GeneratedAt: now,
		},
	}
}

func setupRoutes(app *fiber.App, db *sql.DB, cfg RuntimeTopologyConfig) {
	app.Get("/health", func(c *fiber.Ctx) error {
		if db == nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "runtime-topology",
				"db":      "not_configured",
				"port":    cfg.Port,
			})
		}

		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		if err := db.PingContext(ctx); err != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "runtime-topology",
				"db":      "fail",
				"port":    cfg.Port,
			})
		}

		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "runtime-topology",
			"db":      "ok",
			"port":    cfg.Port,
		})
	})

	app.Get("/api/runtime-topology/nodes", func(c *fiber.Ctx) error {
		nodes := listNodes(db, cfg.Targets)
		limit := parseLimit(c.Query("limit"), 100, 300)

		if len(nodes) > limit {
			nodes = nodes[:limit]
		}

		return c.JSON(fiber.Map{"items": nodes, "limit": limit})
	})

	app.Get("/api/runtime-topology/edges", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"items": cfg.Edges})
	})

	app.Get("/api/runtime-topology/summary", func(c *fiber.Ctx) error {
		nodes := listNodes(db, cfg.Targets)
		summary := buildSummary(db, nodes, cfg.Edges)

		return c.JSON(fiber.Map{"items": []RuntimeTopologySummary{summary}})
	})

	app.Get("/api/runtime-topology/registry", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"items": registryCounts(db)})
	})
}

func main() {
	cfg := loadConfig()

	db, err := openDB(cfg.DSN)
	if err != nil {
		panic(err)
	}
	defer db.Close()

	app := fiber.New()
	setupRoutes(app, db, cfg)

	if err := app.Listen(":" + cfg.Port); err != nil {
		panic(err)
	}
}
