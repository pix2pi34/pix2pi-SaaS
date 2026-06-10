package main

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	_ "github.com/lib/pq"
)

type RealtimeRuntimeConfig struct {
	Port string
	DSN  string
}

type RealtimeSummaryItem struct {
	Status                 string `json:"status"`
	ChannelCount           int    `json:"channel_count"`
	ConnectionCount        int    `json:"connection_count"`
	ActiveConnectionCount  int    `json:"active_connection_count"`
	WebSocketCount         int    `json:"websocket_count"`
	SSECount               int    `json:"sse_count"`
	PresenceCount          int    `json:"presence_count"`
	OnlinePresenceCount    int    `json:"online_presence_count"`
	ChannelPermissionCount int    `json:"channel_permission_count"`
	GeneratedAt            string `json:"generated_at"`
}

type GenericRealtimeRow struct {
	TableName  string `json:"table_name"`
	RecordJSON string `json:"record_json"`
	ObservedAt string `json:"observed_at"`
}

type RealtimeTableStatusItem struct {
	TableName   string `json:"table_name"`
	Exists      bool   `json:"exists"`
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
		return "5970"
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

func loadConfig() RealtimeRuntimeConfig {
	dsn := envOrDefault("DB_READ_DSN", "")
	if dsn == "" {
		dsn = envOrDefault("DB_WRITE_DSN", "")
	}

	return RealtimeRuntimeConfig{
		Port: normalizePort(envOrDefault("REALTIME_RUNTIME_PORT", "5970")),
		DSN:  dsn,
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

func quoteIdent(value string) string {
	return `"` + strings.ReplaceAll(value, `"`, `""`) + `"`
}

func fullTableName(schemaName string, tableName string) string {
	return quoteIdent(schemaName) + "." + quoteIdent(tableName)
}

func tableExists(db *sql.DB, schemaName string, tableName string) bool {
	if db == nil {
		return false
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	var exists bool
	err := db.QueryRowContext(
		ctx,
		`
SELECT EXISTS (
  SELECT 1
  FROM information_schema.tables
  WHERE table_schema = $1
    AND table_name = $2
);
`,
		schemaName,
		tableName,
	).Scan(&exists)

	return err == nil && exists
}

func columnExists(db *sql.DB, schemaName string, tableName string, columnName string) bool {
	if db == nil {
		return false
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	var exists bool
	err := db.QueryRowContext(
		ctx,
		`
SELECT EXISTS (
  SELECT 1
  FROM information_schema.columns
  WHERE table_schema = $1
    AND table_name = $2
    AND column_name = $3
);
`,
		schemaName,
		tableName,
		columnName,
	).Scan(&exists)

	return err == nil && exists
}

func countTable(db *sql.DB, schemaName string, tableName string) int {
	if !tableExists(db, schemaName, tableName) {
		return 0
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	query := "SELECT count(*)::int FROM " + fullTableName(schemaName, tableName)

	var count int
	if err := db.QueryRowContext(ctx, query).Scan(&count); err != nil {
		return 0
	}

	return count
}

func countWhere(db *sql.DB, schemaName string, tableName string, whereSQL string) int {
	if !tableExists(db, schemaName, tableName) {
		return 0
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	query := "SELECT count(*)::int FROM " + fullTableName(schemaName, tableName) + " WHERE " + whereSQL

	var count int
	if err := db.QueryRowContext(ctx, query).Scan(&count); err != nil {
		return 0
	}

	return count
}

func orderColumn(db *sql.DB, schemaName string, tableName string) string {
	preferred := []string{
		"updated_at",
		"created_at",
		"connected_at",
		"stream_opened_at",
		"last_seen_at",
		"heartbeat_at",
		"applied_at",
	}

	for _, column := range preferred {
		if columnExists(db, schemaName, tableName, column) {
			return column
		}
	}

	return ""
}

func readGenericRows(db *sql.DB, schemaName string, tableName string, limit int) []GenericRealtimeRow {
	if !tableExists(db, schemaName, tableName) {
		return []GenericRealtimeRow{}
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	orderBy := orderColumn(db, schemaName, tableName)
	query := "SELECT row_to_json(t)::text FROM (SELECT * FROM " + fullTableName(schemaName, tableName)

	if orderBy != "" {
		query += " ORDER BY " + quoteIdent(orderBy) + " DESC"
	}

	query += " LIMIT $1) t"

	rows, err := db.QueryContext(ctx, query, limit)
	if err != nil {
		return []GenericRealtimeRow{}
	}
	defer rows.Close()

	items := make([]GenericRealtimeRow, 0)
	now := time.Now().UTC().Format(time.RFC3339)

	for rows.Next() {
		var recordJSON string
		if err := rows.Scan(&recordJSON); err != nil {
			return []GenericRealtimeRow{}
		}

		items = append(items, GenericRealtimeRow{
			TableName:  schemaName + "." + tableName,
			RecordJSON: recordJSON,
			ObservedAt: now,
		})
	}

	return items
}

func connectionStatusColumn(db *sql.DB) string {
	if columnExists(db, "runtime", "realtime_connections", "connection_status") {
		return "connection_status"
	}

	if columnExists(db, "runtime", "realtime_connections", "status") {
		return "status"
	}

	return ""
}

func presenceStatusColumn(db *sql.DB) string {
	if columnExists(db, "runtime", "realtime_presence", "presence_status") {
		return "presence_status"
	}

	if columnExists(db, "runtime", "realtime_presence", "status") {
		return "status"
	}

	return ""
}

func realtimeSummary(db *sql.DB) RealtimeSummaryItem {
	connectionStatus := connectionStatusColumn(db)
	presenceStatus := presenceStatusColumn(db)

	activeConnectionCount := 0
	onlinePresenceCount := 0

	if connectionStatus != "" {
		activeConnectionCount = countWhere(
			db,
			"runtime",
			"realtime_connections",
			fmt.Sprintf(
				"lower(%s::text) in ('connected','streaming','online','active')",
				quoteIdent(connectionStatus),
			),
		)
	}

	if presenceStatus != "" {
		onlinePresenceCount = countWhere(
			db,
			"runtime",
			"realtime_presence",
			fmt.Sprintf(
				"lower(%s::text) in ('online','active','connected')",
				quoteIdent(presenceStatus),
			),
		)
	}

	websocketCount := 0
	sseCount := 0
	if columnExists(db, "runtime", "realtime_connections", "protocol") {
		websocketCount = countWhere(db, "runtime", "realtime_connections", "lower(protocol::text) = 'websocket'")
		sseCount = countWhere(db, "runtime", "realtime_connections", "lower(protocol::text) = 'sse'")
	}

	status := "empty"
	total := countTable(db, "runtime", "notification_channels") +
		countTable(db, "runtime", "realtime_connections") +
		countTable(db, "runtime", "realtime_presence") +
		countTable(db, "runtime", "realtime_channel_permissions")

	if total > 0 {
		status = "ok"
	}

	return RealtimeSummaryItem{
		Status:                 status,
		ChannelCount:           countTable(db, "runtime", "notification_channels"),
		ConnectionCount:        countTable(db, "runtime", "realtime_connections"),
		ActiveConnectionCount:  activeConnectionCount,
		WebSocketCount:         websocketCount,
		SSECount:               sseCount,
		PresenceCount:          countTable(db, "runtime", "realtime_presence"),
		OnlinePresenceCount:    onlinePresenceCount,
		ChannelPermissionCount: countTable(db, "runtime", "realtime_channel_permissions"),
		GeneratedAt:            time.Now().UTC().Format(time.RFC3339),
	}
}

func realtimeTableStatus(db *sql.DB) []RealtimeTableStatusItem {
	now := time.Now().UTC().Format(time.RFC3339)

	tables := []struct {
		schemaName string
		tableName  string
	}{
		{"runtime", "notification_channels"},
		{"runtime", "realtime_connections"},
		{"runtime", "realtime_presence"},
		{"runtime", "realtime_channel_permissions"},
	}

	items := make([]RealtimeTableStatusItem, 0, len(tables))
	for _, table := range tables {
		exists := tableExists(db, table.schemaName, table.tableName)
		count := 0
		if exists {
			count = countTable(db, table.schemaName, table.tableName)
		}

		items = append(items, RealtimeTableStatusItem{
			TableName:   table.schemaName + "." + table.tableName,
			Exists:      exists,
			Count:       count,
			GeneratedAt: now,
		})
	}

	return items
}

func setupRoutes(app *fiber.App, db *sql.DB, cfg RealtimeRuntimeConfig) {
	app.Get("/health", func(c *fiber.Ctx) error {
		if db == nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "realtime-runtime",
				"db":      "not_configured",
				"port":    cfg.Port,
			})
		}

		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()

		if err := db.PingContext(ctx); err != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "realtime-runtime",
				"db":      "fail",
				"port":    cfg.Port,
			})
		}

		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "realtime-runtime",
			"db":      "ok",
			"port":    cfg.Port,
		})
	})

	app.Get("/api/realtime/summary", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"items": []RealtimeSummaryItem{realtimeSummary(db)},
		})
	})

	app.Get("/api/realtime/tables", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"items": realtimeTableStatus(db),
		})
	})

	app.Get("/api/realtime/channels", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)
		return c.JSON(fiber.Map{
			"items": readGenericRows(db, "runtime", "notification_channels", limit),
			"limit": limit,
		})
	})

	app.Get("/api/realtime/connections", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)
		return c.JSON(fiber.Map{
			"items": readGenericRows(db, "runtime", "realtime_connections", limit),
			"limit": limit,
		})
	})

	app.Get("/api/realtime/presence", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)
		return c.JSON(fiber.Map{
			"items": readGenericRows(db, "runtime", "realtime_presence", limit),
			"limit": limit,
		})
	})

	app.Get("/api/realtime/permissions", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)
		return c.JSON(fiber.Map{
			"items": readGenericRows(db, "runtime", "realtime_channel_permissions", limit),
			"limit": limit,
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
