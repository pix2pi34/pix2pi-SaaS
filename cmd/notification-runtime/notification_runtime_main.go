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

type NotificationRuntimeConfig struct {
	Port string
	DSN  string
}

type NotificationSummaryItem struct {
	Status            string `json:"status"`
	Count             int    `json:"count"`
	ChannelCount      int    `json:"channel_count"`
	NotificationCount int    `json:"notification_count"`
	RecipientCount    int    `json:"recipient_count"`
	DeliveredCount    int    `json:"delivered_count"`
	FailedCount       int    `json:"failed_count"`
	GeneratedAt       string `json:"generated_at"`
}

type NotificationChannelRow struct {
	ChannelKey      string `json:"channel_key"`
	DisplayName     string `json:"display_name"`
	ChannelType     string `json:"channel_type"`
	VisibilityScope string `json:"visibility_scope"`
	ProviderKey     string `json:"provider_key"`
	IsEnabled       bool   `json:"is_enabled"`
	CreatedAt       string `json:"created_at"`
	UpdatedAt       string `json:"updated_at"`
}

type NotificationRow struct {
	NotificationID   string `json:"notification_id"`
	ChannelKey       string `json:"channel_key"`
	NotificationKey  string `json:"notification_key"`
	NotificationType string `json:"notification_type"`
	Priority         string `json:"priority"`
	Status           string `json:"status"`
	Title            string `json:"title"`
	SourceRefType    string `json:"source_ref_type"`
	SourceRefID      string `json:"source_ref_id"`
	ScheduledAt      string `json:"scheduled_at"`
	SentAt           string `json:"sent_at"`
	CreatedAt        string `json:"created_at"`
	UpdatedAt        string `json:"updated_at"`
}

type NotificationRecipientRow struct {
	RecipientID     string `json:"recipient_id"`
	NotificationKey string `json:"notification_key"`
	RecipientType   string `json:"recipient_type"`
	RecipientKey    string `json:"recipient_key"`
	Destination     string `json:"destination"`
	DeliveryStatus  string `json:"delivery_status"`
	ErrorMessage    string `json:"error_message"`
	DeliveredAt     string `json:"delivered_at"`
	CreatedAt       string `json:"created_at"`
	UpdatedAt       string `json:"updated_at"`
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
		return "5930"
	}
	return port
}

func loadConfig() NotificationRuntimeConfig {
	dsn := envOrDefault("DB_READ_DSN", "")
	if dsn == "" {
		dsn = envOrDefault("DB_WRITE_DSN", "")
	}

	return NotificationRuntimeConfig{
		Port: normalizePort(envOrDefault("NOTIFICATION_RUNTIME_PORT", "5930")),
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

func scanTime(value sql.NullTime) string {
	if value.Valid {
		return value.Time.UTC().Format(time.RFC3339)
	}
	return ""
}

func setupRoutes(app *fiber.App, db *sql.DB, cfg NotificationRuntimeConfig) {
	app.Get("/health", func(c *fiber.Ctx) error {
		if db == nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "notification-runtime",
				"db":      "not_configured",
				"port":    cfg.Port,
			})
		}

		if err := db.PingContext(c.Context()); err != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "notification-runtime",
				"db":      "fail",
				"port":    cfg.Port,
			})
		}

		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "notification-runtime",
			"db":      "ok",
			"port":    cfg.Port,
		})
	})

	app.Get("/api/notifications/summary", func(c *fiber.Ctx) error {
		const query = `
WITH notification_counts AS (
  SELECT coalesce(status::text, 'unknown') AS status, count(*)::int AS count
  FROM runtime.notifications
  GROUP BY coalesce(status::text, 'unknown')
),
channel_count AS (
  SELECT count(*)::int AS count FROM runtime.notification_channels
),
notification_count AS (
  SELECT count(*)::int AS count FROM runtime.notifications
),
recipient_count AS (
  SELECT count(*)::int AS count FROM runtime.notification_recipients
),
delivery_totals AS (
  SELECT
    count(*) FILTER (WHERE delivery_status::text IN ('sent', 'delivered', 'completed'))::int AS delivered_count,
    count(*) FILTER (WHERE delivery_status::text IN ('failed', 'dead_letter', 'cancelled'))::int AS failed_count
  FROM runtime.notification_recipients
)
SELECT
  nc.status,
  nc.count,
  (SELECT count FROM channel_count) AS channel_count,
  (SELECT count FROM notification_count) AS notification_count,
  (SELECT count FROM recipient_count) AS recipient_count,
  (SELECT delivered_count FROM delivery_totals) AS delivered_count,
  (SELECT failed_count FROM delivery_totals) AS failed_count,
  now() AS generated_at
FROM notification_counts nc
UNION ALL
SELECT
  'empty',
  0,
  (SELECT count FROM channel_count),
  (SELECT count FROM notification_count),
  (SELECT count FROM recipient_count),
  (SELECT delivered_count FROM delivery_totals),
  (SELECT failed_count FROM delivery_totals),
  now()
WHERE NOT EXISTS (SELECT 1 FROM runtime.notifications)
ORDER BY status;
`
		rows, err := db.QueryContext(c.Context(), query)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "notification summary okunamadi",
			})
		}
		defer rows.Close()

		items := make([]NotificationSummaryItem, 0)
		for rows.Next() {
			var item NotificationSummaryItem
			var generatedAt time.Time

			if err := rows.Scan(
				&item.Status,
				&item.Count,
				&item.ChannelCount,
				&item.NotificationCount,
				&item.RecipientCount,
				&item.DeliveredCount,
				&item.FailedCount,
				&generatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "notification summary parse edilemedi",
				})
			}

			item.GeneratedAt = generatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{"items": items})
	})

	app.Get("/api/notifications/channels", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)

		const query = `
SELECT
  channel_key,
  display_name,
  channel_type::text,
  visibility_scope::text,
  coalesce(provider_key, ''),
  is_enabled,
  created_at,
  updated_at
FROM runtime.notification_channels
ORDER BY updated_at DESC, channel_key
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "notification channels okunamadi",
			})
		}
		defer rows.Close()

		items := make([]NotificationChannelRow, 0)
		for rows.Next() {
			var item NotificationChannelRow
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(
				&item.ChannelKey,
				&item.DisplayName,
				&item.ChannelType,
				&item.VisibilityScope,
				&item.ProviderKey,
				&item.IsEnabled,
				&createdAt,
				&updatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "notification channels parse edilemedi",
				})
			}

			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
			item.UpdatedAt = updatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{"items": items, "limit": limit})
	})

	app.Get("/api/notifications/items", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)

		const query = `
SELECT
  n.id::text,
  coalesce(c.channel_key, ''),
  n.notification_key,
  n.notification_type,
  n.priority::text,
  n.status::text,
  coalesce(n.title, ''),
  coalesce(n.source_ref_type, ''),
  coalesce(n.source_ref_id, ''),
  n.scheduled_at,
  n.sent_at,
  n.created_at,
  n.updated_at
FROM runtime.notifications n
LEFT JOIN runtime.notification_channels c ON c.id = n.channel_id
ORDER BY n.created_at DESC, n.notification_key
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "notifications okunamadi",
			})
		}
		defer rows.Close()

		items := make([]NotificationRow, 0)
		for rows.Next() {
			var item NotificationRow
			var scheduledAt sql.NullTime
			var sentAt sql.NullTime
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(
				&item.NotificationID,
				&item.ChannelKey,
				&item.NotificationKey,
				&item.NotificationType,
				&item.Priority,
				&item.Status,
				&item.Title,
				&item.SourceRefType,
				&item.SourceRefID,
				&scheduledAt,
				&sentAt,
				&createdAt,
				&updatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "notifications parse edilemedi",
				})
			}

			item.ScheduledAt = scanTime(scheduledAt)
			item.SentAt = scanTime(sentAt)
			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
			item.UpdatedAt = updatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{"items": items, "limit": limit})
	})

	app.Get("/api/notifications/recipients", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)

		const query = `
SELECT
  r.id::text,
  coalesce(n.notification_key, ''),
  r.recipient_type::text,
  r.recipient_key,
  r.destination,
  r.delivery_status::text,
  coalesce(r.error_message, ''),
  r.delivered_at,
  r.created_at,
  r.updated_at
FROM runtime.notification_recipients r
LEFT JOIN runtime.notifications n ON n.id = r.notification_id
ORDER BY r.created_at DESC, r.recipient_key
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "notification recipients okunamadi",
			})
		}
		defer rows.Close()

		items := make([]NotificationRecipientRow, 0)
		for rows.Next() {
			var item NotificationRecipientRow
			var deliveredAt sql.NullTime
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(
				&item.RecipientID,
				&item.NotificationKey,
				&item.RecipientType,
				&item.RecipientKey,
				&item.Destination,
				&item.DeliveryStatus,
				&item.ErrorMessage,
				&deliveredAt,
				&createdAt,
				&updatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "notification recipients parse edilemedi",
				})
			}

			item.DeliveredAt = scanTime(deliveredAt)
			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
			item.UpdatedAt = updatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{"items": items, "limit": limit})
	})

	app.Get("/api/notifications/dlq", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)

		const query = `
SELECT
  r.id::text,
  coalesce(n.notification_key, ''),
  r.recipient_type::text,
  r.recipient_key,
  r.destination,
  r.delivery_status::text,
  coalesce(r.error_message, ''),
  r.delivered_at,
  r.created_at,
  r.updated_at
FROM runtime.notification_recipients r
LEFT JOIN runtime.notifications n ON n.id = r.notification_id
WHERE r.delivery_status::text IN ('failed', 'dead_letter', 'cancelled')
ORDER BY r.updated_at DESC, r.created_at DESC
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "notification dlq okunamadi",
			})
		}
		defer rows.Close()

		items := make([]NotificationRecipientRow, 0)
		for rows.Next() {
			var item NotificationRecipientRow
			var deliveredAt sql.NullTime
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(
				&item.RecipientID,
				&item.NotificationKey,
				&item.RecipientType,
				&item.RecipientKey,
				&item.Destination,
				&item.DeliveryStatus,
				&item.ErrorMessage,
				&deliveredAt,
				&createdAt,
				&updatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "notification dlq parse edilemedi",
				})
			}

			item.DeliveredAt = scanTime(deliveredAt)
			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
			item.UpdatedAt = updatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{"items": items, "limit": limit})
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
