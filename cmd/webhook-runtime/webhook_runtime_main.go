package main

import (
	"database/sql"
	"errors"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	_ "github.com/lib/pq"
)

type WebhookRuntimeConfig struct {
	Port string
	DSN  string
}

type WebhookSummaryItem struct {
	Status        string `json:"status"`
	Count         int    `json:"count"`
	EndpointCount int    `json:"endpoint_count"`
	AttemptCount  int    `json:"attempt_count"`
	GeneratedAt   string `json:"generated_at"`
}

type WebhookEndpointRow struct {
	EndpointKey         string `json:"endpoint_key"`
	DisplayName         string `json:"display_name"`
	VisibilityScope     string `json:"visibility_scope"`
	TargetURL           string `json:"target_url"`
	HTTPMethod          string `json:"http_method"`
	AuthType            string `json:"auth_type"`
	SignatureHeader     string `json:"signature_header"`
	TimeoutSeconds      int    `json:"timeout_seconds"`
	RetryLimit          int    `json:"retry_limit"`
	RetryBackoffSeconds int    `json:"retry_backoff_seconds"`
	IsEnabled           bool   `json:"is_enabled"`
	DeliveryCount       int    `json:"delivery_count"`
	FailedCount         int    `json:"failed_count"`
	DeadLetterCount     int    `json:"dead_letter_count"`
	UpdatedAt           string `json:"updated_at"`
}

type WebhookDeliveryRow struct {
	DeliveryID     string `json:"delivery_id"`
	EndpointKey    string `json:"endpoint_key"`
	DeliveryKey    string `json:"delivery_key"`
	EventType      string `json:"event_type"`
	Priority       string `json:"priority"`
	Status         string `json:"status"`
	ResponseCode   int    `json:"response_code"`
	RetryCount     int    `json:"retry_count"`
	MaxAttempts    int    `json:"max_attempts"`
	NextRetryAt    string `json:"next_retry_at"`
	DeliveredAt    string `json:"delivered_at"`
	DeadLetteredAt string `json:"dead_lettered_at"`
	SourceRefType  string `json:"source_ref_type"`
	SourceRefID    string `json:"source_ref_id"`
	LastError      string `json:"last_error"`
	CreatedAt      string `json:"created_at"`
	UpdatedAt      string `json:"updated_at"`
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
		return "5890"
	}

	return port
}

func loadConfig() WebhookRuntimeConfig {
	dsn := envOrDefault("DB_READ_DSN", "")
	if dsn == "" {
		dsn = envOrDefault("DB_WRITE_DSN", "")
	}

	return WebhookRuntimeConfig{
		Port: normalizePort(envOrDefault("WEBHOOK_RUNTIME_PORT", "5890")),
		DSN:  dsn,
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

func scanString(value sql.NullString) string {
	if value.Valid {
		return value.String
	}

	return ""
}

func scanInt(value sql.NullInt64) int {
	if value.Valid {
		return int(value.Int64)
	}

	return 0
}

func scanTime(value sql.NullTime) string {
	if value.Valid {
		return value.Time.UTC().Format(time.RFC3339)
	}

	return ""
}

func setupRoutes(app *fiber.App, db *sql.DB, cfg WebhookRuntimeConfig) {
	app.Get("/health", func(c *fiber.Ctx) error {
		if db == nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "webhook-runtime",
				"db":      "not_configured",
				"port":    cfg.Port,
			})
		}

		if err := db.PingContext(c.Context()); err != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "webhook-runtime",
				"db":      "fail",
				"port":    cfg.Port,
			})
		}

		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "webhook-runtime",
			"db":      "ok",
			"port":    cfg.Port,
		})
	})

	app.Get("/api/webhooks/summary", func(c *fiber.Ctx) error {
		const query = `
WITH delivery_counts AS (
  SELECT coalesce(status::text, 'unknown') AS status, count(*)::int AS count
  FROM runtime.webhook_deliveries
  GROUP BY coalesce(status::text, 'unknown')
),
endpoint_count AS (
  SELECT count(*)::int AS count FROM runtime.webhook_endpoints
),
attempt_count AS (
  SELECT count(*)::int AS count FROM runtime.webhook_delivery_attempts
)
SELECT
  dc.status,
  dc.count,
  (SELECT count FROM endpoint_count) AS endpoint_count,
  (SELECT count FROM attempt_count) AS attempt_count,
  now() AS generated_at
FROM delivery_counts dc
UNION ALL
SELECT
  'empty',
  0,
  (SELECT count FROM endpoint_count),
  (SELECT count FROM attempt_count),
  now()
WHERE NOT EXISTS (SELECT 1 FROM runtime.webhook_deliveries)
ORDER BY status;
`
		rows, err := db.QueryContext(c.Context(), query)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "webhook summary okunamadi",
			})
		}
		defer rows.Close()

		items := make([]WebhookSummaryItem, 0)
		for rows.Next() {
			var item WebhookSummaryItem
			var generatedAt time.Time

			if err := rows.Scan(
				&item.Status,
				&item.Count,
				&item.EndpointCount,
				&item.AttemptCount,
				&generatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "webhook summary parse edilemedi",
				})
			}

			item.GeneratedAt = generatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{
			"items": items,
		})
	})

	app.Get("/api/webhooks/endpoints", func(c *fiber.Ctx) error {
		const query = `
SELECT
  e.endpoint_key,
  e.display_name,
  e.visibility_scope::text,
  e.target_url,
  e.http_method,
  e.auth_type::text,
  coalesce(e.signature_header, ''),
  coalesce(e.timeout_seconds, 0),
  coalesce(e.retry_limit, 0),
  coalesce(e.retry_backoff_seconds, 0),
  e.is_enabled,
  count(d.id)::int AS delivery_count,
  count(d.id) FILTER (WHERE d.status::text = 'failed')::int AS failed_count,
  count(d.id) FILTER (WHERE d.status::text = 'dead_letter')::int AS dead_letter_count,
  e.updated_at
FROM runtime.webhook_endpoints e
LEFT JOIN runtime.webhook_deliveries d ON d.endpoint_id = e.id
GROUP BY
  e.endpoint_key,
  e.display_name,
  e.visibility_scope,
  e.target_url,
  e.http_method,
  e.auth_type,
  e.signature_header,
  e.timeout_seconds,
  e.retry_limit,
  e.retry_backoff_seconds,
  e.is_enabled,
  e.updated_at
ORDER BY e.endpoint_key;
`
		rows, err := db.QueryContext(c.Context(), query)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "webhook endpoints okunamadi",
			})
		}
		defer rows.Close()

		items := make([]WebhookEndpointRow, 0)
		for rows.Next() {
			var item WebhookEndpointRow
			var updatedAt time.Time

			if err := rows.Scan(
				&item.EndpointKey,
				&item.DisplayName,
				&item.VisibilityScope,
				&item.TargetURL,
				&item.HTTPMethod,
				&item.AuthType,
				&item.SignatureHeader,
				&item.TimeoutSeconds,
				&item.RetryLimit,
				&item.RetryBackoffSeconds,
				&item.IsEnabled,
				&item.DeliveryCount,
				&item.FailedCount,
				&item.DeadLetterCount,
				&updatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "webhook endpoints parse edilemedi",
				})
			}

			item.UpdatedAt = updatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{
			"items": items,
		})
	})

	app.Get("/api/webhooks/deliveries", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 25, 100)

		const query = `
SELECT
  d.id::text,
  coalesce(e.endpoint_key, ''),
  d.delivery_key,
  d.event_type,
  d.priority::text,
  d.status::text,
  d.response_code,
  coalesce(d.retry_count, 0),
  coalesce(d.max_attempts, 0),
  d.next_retry_at,
  d.delivered_at,
  d.dead_lettered_at,
  coalesce(d.source_ref_type, ''),
  coalesce(d.source_ref_id, ''),
  d.last_error,
  d.created_at,
  d.updated_at
FROM runtime.webhook_deliveries d
LEFT JOIN runtime.webhook_endpoints e ON e.id = d.endpoint_id
ORDER BY d.created_at DESC
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "webhook deliveries okunamadi",
			})
		}
		defer rows.Close()

		items := make([]WebhookDeliveryRow, 0)
		for rows.Next() {
			var item WebhookDeliveryRow
			var responseCode sql.NullInt64
			var nextRetryAt sql.NullTime
			var deliveredAt sql.NullTime
			var deadLetteredAt sql.NullTime
			var lastError sql.NullString
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(
				&item.DeliveryID,
				&item.EndpointKey,
				&item.DeliveryKey,
				&item.EventType,
				&item.Priority,
				&item.Status,
				&responseCode,
				&item.RetryCount,
				&item.MaxAttempts,
				&nextRetryAt,
				&deliveredAt,
				&deadLetteredAt,
				&item.SourceRefType,
				&item.SourceRefID,
				&lastError,
				&createdAt,
				&updatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "webhook deliveries parse edilemedi",
				})
			}

			item.ResponseCode = scanInt(responseCode)
			item.NextRetryAt = scanTime(nextRetryAt)
			item.DeliveredAt = scanTime(deliveredAt)
			item.DeadLetteredAt = scanTime(deadLetteredAt)
			item.LastError = scanString(lastError)
			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
			item.UpdatedAt = updatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{
			"items": items,
			"limit": limit,
		})
	})

	app.Get("/api/webhooks/dlq", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 25, 100)

		const query = `
SELECT
  d.id::text,
  coalesce(e.endpoint_key, ''),
  d.delivery_key,
  d.event_type,
  d.priority::text,
  d.status::text,
  d.response_code,
  coalesce(d.retry_count, 0),
  coalesce(d.max_attempts, 0),
  d.next_retry_at,
  d.delivered_at,
  d.dead_lettered_at,
  coalesce(d.source_ref_type, ''),
  coalesce(d.source_ref_id, ''),
  d.last_error,
  d.created_at,
  d.updated_at
FROM runtime.webhook_deliveries d
LEFT JOIN runtime.webhook_endpoints e ON e.id = d.endpoint_id
WHERE d.status::text = 'dead_letter'
ORDER BY d.dead_lettered_at DESC NULLS LAST, d.updated_at DESC
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "webhook dlq okunamadi",
			})
		}
		defer rows.Close()

		items := make([]WebhookDeliveryRow, 0)
		for rows.Next() {
			var item WebhookDeliveryRow
			var responseCode sql.NullInt64
			var nextRetryAt sql.NullTime
			var deliveredAt sql.NullTime
			var deadLetteredAt sql.NullTime
			var lastError sql.NullString
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(
				&item.DeliveryID,
				&item.EndpointKey,
				&item.DeliveryKey,
				&item.EventType,
				&item.Priority,
				&item.Status,
				&responseCode,
				&item.RetryCount,
				&item.MaxAttempts,
				&nextRetryAt,
				&deliveredAt,
				&deadLetteredAt,
				&item.SourceRefType,
				&item.SourceRefID,
				&lastError,
				&createdAt,
				&updatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "webhook dlq parse edilemedi",
				})
			}

			item.ResponseCode = scanInt(responseCode)
			item.NextRetryAt = scanTime(nextRetryAt)
			item.DeliveredAt = scanTime(deliveredAt)
			item.DeadLetteredAt = scanTime(deadLetteredAt)
			item.LastError = scanString(lastError)
			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
			item.UpdatedAt = updatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{
			"items": items,
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
