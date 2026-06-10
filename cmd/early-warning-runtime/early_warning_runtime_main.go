package main

import (
	"bufio"
	"context"
	"database/sql"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"runtime"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v2"
	_ "github.com/lib/pq"
)

type EarlyWarningRuntimeConfig struct {
	Port    string
	DSN     string
	Targets []ServiceTarget
}

type ServiceTarget struct {
	ServiceKey string `json:"service_key"`
	Display   string `json:"display"`
	URL       string `json:"url"`
}

type ServiceHealthItem struct {
	ServiceKey string `json:"service_key"`
	Display    string `json:"display"`
	Status     string `json:"status"`
	HTTPStatus int    `json:"http_status"`
	LatencyMs  int64  `json:"latency_ms"`
	Message    string `json:"message"`
	CheckedAt  string `json:"checked_at"`
}

type ResourceItem struct {
	ResourceKey string  `json:"resource_key"`
	Display     string  `json:"display"`
	Value       float64 `json:"value"`
	Unit        string  `json:"unit"`
	UsedPercent float64 `json:"used_percent"`
	Level       string  `json:"level"`
	Message     string  `json:"message"`
	CheckedAt   string  `json:"checked_at"`
}

type SignalItem struct {
	SignalKey   string `json:"signal_key"`
	Category    string `json:"category"`
	Level       string `json:"level"`
	Status      string `json:"status"`
	Message     string `json:"message"`
	GeneratedAt string `json:"generated_at"`
}

type EarlyWarningSummary struct {
	AlertLevel       string `json:"alert_level"`
	ServiceCount     int    `json:"service_count"`
	ServiceOKCount   int    `json:"service_ok_count"`
	ServiceFailCount int    `json:"service_fail_count"`
	ResourceCount    int    `json:"resource_count"`
	SignalCount      int    `json:"signal_count"`
	WarningCount     int    `json:"warning_count"`
	CriticalCount    int    `json:"critical_count"`
	IncidentCount    int    `json:"incident_count"`
	GeneratedAt      string `json:"generated_at"`
}

type IncidentSummaryItem struct {
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
		return "5940"
	}
	return port
}

func loadConfig() EarlyWarningRuntimeConfig {
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

	return EarlyWarningRuntimeConfig{
		Port: normalizePort(envOrDefault("EARLY_WARNING_RUNTIME_PORT", "5940")),
		DSN:  dsn,
		Targets: []ServiceTarget{
			{ServiceKey: "panel", Display: "Control Panel", URL: "http://127.0.0.1:" + panelPort + "/health"},
			{ServiceKey: "api_gateway", Display: "API Gateway", URL: "http://127.0.0.1:" + apiGatewayPort + "/health"},
			{ServiceKey: "mission_control", Display: "Mission Control", URL: "http://127.0.0.1:" + missionPort + "/health"},
			{ServiceKey: "service_registry", Display: "Service Registry", URL: "http://127.0.0.1:" + registryPort + "/health"},
			{ServiceKey: "jobs_runtime", Display: "Jobs Runtime", URL: "http://127.0.0.1:" + jobsRuntimePort + "/health"},
			{ServiceKey: "webhook_runtime", Display: "Webhook Runtime", URL: "http://127.0.0.1:" + webhookRuntimePort + "/health"},
			{ServiceKey: "workflow_runtime", Display: "Workflow Runtime", URL: "http://127.0.0.1:" + workflowRuntimePort + "/health"},
			{ServiceKey: "plugin_runtime", Display: "Plugin Runtime", URL: "http://127.0.0.1:" + pluginRuntimePort + "/health"},
			{ServiceKey: "publicapi_runtime", Display: "Public API Runtime", URL: "http://127.0.0.1:" + publicAPIRuntimePort + "/health"},
			{ServiceKey: "notification_runtime", Display: "Notification Runtime", URL: "http://127.0.0.1:" + notificationRuntimePort + "/health"},
		},
	}
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

func levelFromPercent(percent float64, warning float64, critical float64) string {
	if percent >= critical {
		return "critical"
	}
	if percent >= warning {
		return "warning"
	}
	return "ok"
}

func maxLevel(levels ...string) string {
	result := "ok"

	for _, level := range levels {
		switch strings.ToLower(level) {
		case "critical":
			return "critical"
		case "warning":
			if result != "critical" {
				result = "warning"
			}
		}
	}

	return result
}

func checkService(target ServiceTarget) ServiceHealthItem {
	startedAt := time.Now()
	checkedAt := startedAt.UTC().Format(time.RFC3339)

	client := &http.Client{
		Timeout: 2 * time.Second,
	}

	resp, err := client.Get(target.URL)
	latencyMs := time.Since(startedAt).Milliseconds()

	if err != nil {
		return ServiceHealthItem{
			ServiceKey: target.ServiceKey,
			Display:    target.Display,
			Status:     "fail",
			HTTPStatus: 0,
			LatencyMs:  latencyMs,
			Message:    err.Error(),
			CheckedAt:  checkedAt,
		}
	}
	defer resp.Body.Close()
	_, _ = io.Copy(io.Discard, resp.Body)

	status := "ok"
	message := "service healthy"

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		status = "fail"
		message = fmt.Sprintf("http status %d", resp.StatusCode)
	}

	return ServiceHealthItem{
		ServiceKey: target.ServiceKey,
		Display:    target.Display,
		Status:     status,
		HTTPStatus: resp.StatusCode,
		LatencyMs:  latencyMs,
		Message:    message,
		CheckedAt:  checkedAt,
	}
}

func listServiceHealth(targets []ServiceTarget) []ServiceHealthItem {
	items := make([]ServiceHealthItem, 0, len(targets))

	for _, target := range targets {
		items = append(items, checkService(target))
	}

	return items
}

func diskResource(path string) ResourceItem {
	now := time.Now().UTC().Format(time.RFC3339)
	var stat syscall.Statfs_t

	if err := syscall.Statfs(path, &stat); err != nil {
		return ResourceItem{
			ResourceKey: "disk_root",
			Display:     "Root Disk",
			Level:       "critical",
			Message:     err.Error(),
			CheckedAt:   now,
		}
	}

	total := float64(stat.Blocks) * float64(stat.Bsize)
	available := float64(stat.Bavail) * float64(stat.Bsize)
	used := total - available
	usedPercent := 0.0

	if total > 0 {
		usedPercent = used / total * 100
	}

	level := levelFromPercent(usedPercent, 80, 90)

	return ResourceItem{
		ResourceKey: "disk_root",
		Display:     "Root Disk",
		Value:       used / 1024 / 1024 / 1024,
		Unit:        "GiB used",
		UsedPercent: usedPercent,
		Level:       level,
		Message:     fmt.Sprintf("disk kullanimi %.1f%%", usedPercent),
		CheckedAt:   now,
	}
}

func memoryResource() ResourceItem {
	now := time.Now().UTC().Format(time.RFC3339)

	file, err := os.Open("/proc/meminfo")
	if err != nil {
		return ResourceItem{
			ResourceKey: "memory",
			Display:     "Memory",
			Level:       "critical",
			Message:     err.Error(),
			CheckedAt:   now,
		}
	}
	defer file.Close()

	values := map[string]float64{}
	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		fields := strings.Fields(scanner.Text())
		if len(fields) < 2 {
			continue
		}

		key := strings.TrimSuffix(fields[0], ":")
		value, err := strconv.ParseFloat(fields[1], 64)
		if err == nil {
			values[key] = value
		}
	}

	total := values["MemTotal"]
	available := values["MemAvailable"]
	usedPercent := 0.0

	if total > 0 {
		usedPercent = (total - available) / total * 100
	}

	level := levelFromPercent(usedPercent, 80, 90)

	return ResourceItem{
		ResourceKey: "memory",
		Display:     "Memory",
		Value:       (total - available) / 1024 / 1024,
		Unit:        "GiB used",
		UsedPercent: usedPercent,
		Level:       level,
		Message:     fmt.Sprintf("memory kullanimi %.1f%%", usedPercent),
		CheckedAt:   now,
	}
}

func loadResource() ResourceItem {
	now := time.Now().UTC().Format(time.RFC3339)

	content, err := os.ReadFile("/proc/loadavg")
	if err != nil {
		return ResourceItem{
			ResourceKey: "load_average",
			Display:     "Load Average",
			Level:       "critical",
			Message:     err.Error(),
			CheckedAt:   now,
		}
	}

	fields := strings.Fields(string(content))
	load1 := 0.0
	if len(fields) > 0 {
		load1, _ = strconv.ParseFloat(fields[0], 64)
	}

	cpuCount := runtime.NumCPU()
	usedPercent := 0.0

	if cpuCount > 0 {
		usedPercent = load1 / float64(cpuCount) * 100
	}

	level := levelFromPercent(usedPercent, 75, 100)

	return ResourceItem{
		ResourceKey: "load_average",
		Display:     "Load Average",
		Value:       load1,
		Unit:        "load1",
		UsedPercent: usedPercent,
		Level:       level,
		Message:     fmt.Sprintf("load1 %.2f / cpu %d", load1, cpuCount),
		CheckedAt:   now,
	}
}

func listResources() []ResourceItem {
	return []ResourceItem{
		diskResource("/"),
		memoryResource(),
		loadResource(),
	}
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

func dbStatusSignal(db *sql.DB) SignalItem {
	now := time.Now().UTC().Format(time.RFC3339)

	if db == nil {
		return SignalItem{
			SignalKey:   "database",
			Category:    "database",
			Level:       "critical",
			Status:      "fail",
			Message:     "db baglantisi yok",
			GeneratedAt: now,
		}
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		return SignalItem{
			SignalKey:   "database",
			Category:    "database",
			Level:       "critical",
			Status:      "fail",
			Message:     err.Error(),
			GeneratedAt: now,
		}
	}

	return SignalItem{
		SignalKey:   "database",
		Category:    "database",
		Level:       "ok",
		Status:      "ok",
		Message:     "database healthy",
		GeneratedAt: now,
	}
}

func buildSignals(db *sql.DB, services []ServiceHealthItem, resources []ResourceItem) []SignalItem {
	now := time.Now().UTC().Format(time.RFC3339)
	signals := make([]SignalItem, 0)

	for _, service := range services {
		level := "ok"
		status := "ok"

		if service.Status != "ok" {
			level = "critical"
			status = "fail"
		}

		signals = append(signals, SignalItem{
			SignalKey:   "service_" + service.ServiceKey,
			Category:    "service",
			Level:       level,
			Status:      status,
			Message:     service.Display + " => " + service.Message,
			GeneratedAt: now,
		})
	}

	for _, resource := range resources {
		status := "ok"
		if resource.Level != "ok" {
			status = "warning"
		}
		if resource.Level == "critical" {
			status = "fail"
		}

		signals = append(signals, SignalItem{
			SignalKey:   "resource_" + resource.ResourceKey,
			Category:    "resource",
			Level:       resource.Level,
			Status:      status,
			Message:     resource.Message,
			GeneratedAt: now,
		})
	}

	signals = append(signals, dbStatusSignal(db))

	incidentCount := countTable(db, "runtime.mission_control_incidents")
	incidentLevel := "ok"
	incidentStatus := "ok"
	message := "acik incident sayisi izleniyor"

	if incidentCount > 0 {
		incidentLevel = "warning"
		incidentStatus = "warning"
		message = fmt.Sprintf("incident kaydi var: %d", incidentCount)
	}

	signals = append(signals, SignalItem{
		SignalKey:   "mission_control_incidents",
		Category:    "incident",
		Level:       incidentLevel,
		Status:      incidentStatus,
		Message:     message,
		GeneratedAt: now,
	})

	return signals
}

func buildSummary(db *sql.DB, services []ServiceHealthItem, resources []ResourceItem, signals []SignalItem) EarlyWarningSummary {
	now := time.Now().UTC().Format(time.RFC3339)
	serviceOK := 0
	serviceFail := 0
	warningCount := 0
	criticalCount := 0
	levels := []string{"ok"}

	for _, service := range services {
		if service.Status == "ok" {
			serviceOK++
		} else {
			serviceFail++
			levels = append(levels, "critical")
		}
	}

	for _, signal := range signals {
		levels = append(levels, signal.Level)

		if signal.Level == "warning" {
			warningCount++
		}

		if signal.Level == "critical" {
			criticalCount++
		}
	}

	return EarlyWarningSummary{
		AlertLevel:       maxLevel(levels...),
		ServiceCount:     len(services),
		ServiceOKCount:   serviceOK,
		ServiceFailCount: serviceFail,
		ResourceCount:    len(resources),
		SignalCount:      len(signals),
		WarningCount:     warningCount,
		CriticalCount:    criticalCount,
		IncidentCount:    countTable(db, "runtime.mission_control_incidents"),
		GeneratedAt:      now,
	}
}

func setupRoutes(app *fiber.App, db *sql.DB, cfg EarlyWarningRuntimeConfig) {
	app.Get("/health", func(c *fiber.Ctx) error {
		if db == nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "early-warning-runtime",
				"db":      "not_configured",
				"port":    cfg.Port,
			})
		}

		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		if err := db.PingContext(ctx); err != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "early-warning-runtime",
				"db":      "fail",
				"port":    cfg.Port,
			})
		}

		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "early-warning-runtime",
			"db":      "ok",
			"port":    cfg.Port,
		})
	})

	app.Get("/api/early-warning/services", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"items": listServiceHealth(cfg.Targets),
		})
	})

	app.Get("/api/early-warning/resources", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"items": listResources(),
		})
	})

	app.Get("/api/early-warning/signals", func(c *fiber.Ctx) error {
		services := listServiceHealth(cfg.Targets)
		resources := listResources()
		signals := buildSignals(db, services, resources)
		limit := parseLimit(c.Query("limit"), 100, 300)

		if len(signals) > limit {
			signals = signals[:limit]
		}

		return c.JSON(fiber.Map{
			"items": signals,
			"limit": limit,
		})
	})

	app.Get("/api/early-warning/summary", func(c *fiber.Ctx) error {
		services := listServiceHealth(cfg.Targets)
		resources := listResources()
		signals := buildSignals(db, services, resources)
		summary := buildSummary(db, services, resources, signals)

		return c.JSON(fiber.Map{
			"items": []EarlyWarningSummary{summary},
		})
	})

	app.Get("/api/early-warning/incidents", func(c *fiber.Ctx) error {
		now := time.Now().UTC().Format(time.RFC3339)

		return c.JSON(fiber.Map{
			"items": []IncidentSummaryItem{
				{
					TableName:   "runtime.mission_control_incidents",
					Count:       countTable(db, "runtime.mission_control_incidents"),
					GeneratedAt: now,
				},
				{
					TableName:   "audit.audit_events",
					Count:       countTable(db, "audit.audit_events"),
					GeneratedAt: now,
				},
				{
					TableName:   "public.audit_logs",
					Count:       countTable(db, "public.audit_logs"),
					GeneratedAt: now,
				},
			},
		})
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
