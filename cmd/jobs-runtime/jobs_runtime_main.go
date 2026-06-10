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

type JobsRuntimeConfig struct {
	Port string
	DSN  string
}

type JobsSummary struct {
	Status       string `json:"status"`
	Count        int    `json:"count"`
	QueueCount   int    `json:"queue_count"`
	AttemptCount int    `json:"attempt_count"`
	GeneratedAt  string `json:"generated_at"`
}

type QueueRow struct {
	QueueKey             string `json:"queue_key"`
	DisplayName          string `json:"display_name"`
	VisibilityScope      string `json:"visibility_scope"`
	IsEnabled            bool   `json:"is_enabled"`
	MaxConcurrency       int    `json:"max_concurrency"`
	RetryLimit           int    `json:"retry_limit"`
	RetryBackoffSeconds  int    `json:"retry_backoff_seconds"`
	DeadLetterQueueKey   string `json:"dead_letter_queue_key"`
	QueuedCount          int    `json:"queued_count"`
	ProcessingCount      int    `json:"processing_count"`
	FailedCount          int    `json:"failed_count"`
	DeadLetterCount      int    `json:"dead_letter_count"`
	UpdatedAt            string `json:"updated_at"`
}

type JobRow struct {
	JobID        string `json:"job_id"`
	QueueKey     string `json:"queue_key"`
	JobKey       string `json:"job_key"`
	JobType      string `json:"job_type"`
	Priority     string `json:"priority"`
	Status       string `json:"status"`
	RetryCount   int    `json:"retry_count"`
	MaxAttempts  int    `json:"max_attempts"`
	LastError    string `json:"last_error"`
	LockedBy     string `json:"locked_by"`
	AvailableAt  string `json:"available_at"`
	CreatedAt    string `json:"created_at"`
	UpdatedAt    string `json:"updated_at"`
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
		return "5880"
	}

	return port
}

func loadConfig() JobsRuntimeConfig {
	dsn := envOrDefault("DB_READ_DSN", "")
	if dsn == "" {
		dsn = envOrDefault("DB_WRITE_DSN", "")
	}

	return JobsRuntimeConfig{
		Port: normalizePort(envOrDefault("JOBS_RUNTIME_PORT", "5880")),
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

func setupRoutes(app *fiber.App, db *sql.DB, cfg JobsRuntimeConfig) {
	app.Get("/health", func(c *fiber.Ctx) error {
		if db == nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "jobs-runtime",
				"db":      "not_configured",
				"port":    cfg.Port,
			})
		}

		if err := db.PingContext(c.Context()); err != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "jobs-runtime",
				"db":      "fail",
				"port":    cfg.Port,
			})
		}

		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "jobs-runtime",
			"db":      "ok",
			"port":    cfg.Port,
		})
	})

	app.Get("/api/jobs/summary", func(c *fiber.Ctx) error {
		const query = `
WITH job_counts AS (
  SELECT coalesce(status::text, 'unknown') AS status, count(*)::int AS count
  FROM runtime.jobs
  GROUP BY coalesce(status::text, 'unknown')
),
queue_count AS (
  SELECT count(*)::int AS count FROM runtime.job_queues
),
attempt_count AS (
  SELECT count(*)::int AS count FROM runtime.job_attempts
)
SELECT
  jc.status,
  jc.count,
  (SELECT count FROM queue_count) AS queue_count,
  (SELECT count FROM attempt_count) AS attempt_count,
  now() AS generated_at
FROM job_counts jc
UNION ALL
SELECT
  'empty',
  0,
  (SELECT count FROM queue_count),
  (SELECT count FROM attempt_count),
  now()
WHERE NOT EXISTS (SELECT 1 FROM runtime.jobs)
ORDER BY status;
`
		rows, err := db.QueryContext(c.Context(), query)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "jobs summary okunamadi",
			})
		}
		defer rows.Close()

		items := make([]JobsSummary, 0)
		for rows.Next() {
			var item JobsSummary
			var generatedAt time.Time
			if err := rows.Scan(
				&item.Status,
				&item.Count,
				&item.QueueCount,
				&item.AttemptCount,
				&generatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "jobs summary parse edilemedi",
				})
			}
			item.GeneratedAt = generatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{
			"items": items,
		})
	})

	app.Get("/api/jobs/queues", func(c *fiber.Ctx) error {
		const query = `
SELECT
  q.queue_key,
  q.display_name,
  q.visibility_scope::text,
  q.is_enabled,
  coalesce(q.max_concurrency, 0),
  coalesce(q.retry_limit, 0),
  coalesce(q.retry_backoff_seconds, 0),
  coalesce(q.dead_letter_queue_key, ''),
  count(j.id) FILTER (WHERE j.status::text IN ('queued', 'scheduled'))::int AS queued_count,
  count(j.id) FILTER (WHERE j.status::text = 'processing')::int AS processing_count,
  count(j.id) FILTER (WHERE j.status::text = 'failed')::int AS failed_count,
  count(j.id) FILTER (WHERE j.status::text = 'dead_letter')::int AS dead_letter_count,
  q.updated_at
FROM runtime.job_queues q
LEFT JOIN runtime.jobs j ON j.queue_id = q.id
GROUP BY
  q.queue_key,
  q.display_name,
  q.visibility_scope,
  q.is_enabled,
  q.max_concurrency,
  q.retry_limit,
  q.retry_backoff_seconds,
  q.dead_letter_queue_key,
  q.updated_at
ORDER BY q.queue_key;
`
		rows, err := db.QueryContext(c.Context(), query)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "jobs queues okunamadi",
			})
		}
		defer rows.Close()

		items := make([]QueueRow, 0)
		for rows.Next() {
			var item QueueRow
			var updatedAt time.Time
			if err := rows.Scan(
				&item.QueueKey,
				&item.DisplayName,
				&item.VisibilityScope,
				&item.IsEnabled,
				&item.MaxConcurrency,
				&item.RetryLimit,
				&item.RetryBackoffSeconds,
				&item.DeadLetterQueueKey,
				&item.QueuedCount,
				&item.ProcessingCount,
				&item.FailedCount,
				&item.DeadLetterCount,
				&updatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "jobs queues parse edilemedi",
				})
			}
			item.UpdatedAt = updatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{
			"items": items,
		})
	})

	app.Get("/api/jobs/recent", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 25, 100)

		const query = `
SELECT
  j.id::text,
  q.queue_key,
  j.job_key,
  j.job_type,
  j.priority::text,
  j.status::text,
  coalesce(j.retry_count, 0),
  coalesce(j.max_attempts, 0),
  j.last_error,
  j.locked_by,
  j.available_at,
  j.created_at,
  j.updated_at
FROM runtime.jobs j
JOIN runtime.job_queues q ON q.id = j.queue_id
ORDER BY j.created_at DESC
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "recent jobs okunamadi",
			})
		}
		defer rows.Close()

		items := make([]JobRow, 0)
		for rows.Next() {
			var item JobRow
			var lastError sql.NullString
			var lockedBy sql.NullString
			var availableAt sql.NullTime
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(
				&item.JobID,
				&item.QueueKey,
				&item.JobKey,
				&item.JobType,
				&item.Priority,
				&item.Status,
				&item.RetryCount,
				&item.MaxAttempts,
				&lastError,
				&lockedBy,
				&availableAt,
				&createdAt,
				&updatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "recent jobs parse edilemedi",
				})
			}

			item.LastError = scanString(lastError)
			item.LockedBy = scanString(lockedBy)
			item.AvailableAt = scanTime(availableAt)
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
