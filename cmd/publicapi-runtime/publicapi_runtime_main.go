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

type PublicAPIRuntimeConfig struct {
	Port string
	DSN  string
}

type PublicAPISummaryItem struct {
	Status        string `json:"status"`
	Count         int    `json:"count"`
	KeyCount      int    `json:"key_count"`
	PolicyCount   int    `json:"policy_count"`
	UsageCount    int    `json:"usage_count"`
	RequestCount  int64  `json:"request_count"`
	RejectedCount int64  `json:"rejected_count"`
	GeneratedAt   string `json:"generated_at"`
}

type APIKeyRow struct {
	KeyRef          string `json:"key_ref"`
	DisplayName     string `json:"display_name"`
	VisibilityScope string `json:"visibility_scope"`
	KeyPrefix       string `json:"key_prefix"`
	Status          string `json:"status"`
	LastUsedAt      string `json:"last_used_at"`
	ExpiresAt       string `json:"expires_at"`
	RevokedAt       string `json:"revoked_at"`
	CreatedAt       string `json:"created_at"`
	UpdatedAt       string `json:"updated_at"`
}

type APIQuotaPolicyRow struct {
	PolicyKey     string `json:"policy_key"`
	KeyRef        string `json:"key_ref"`
	EndpointScope string `json:"endpoint_scope"`
	QuotaPeriod   string `json:"quota_period"`
	RequestLimit  int    `json:"request_limit"`
	BurstLimit    int    `json:"burst_limit"`
	IsEnabled     bool   `json:"is_enabled"`
	CreatedAt     string `json:"created_at"`
	UpdatedAt     string `json:"updated_at"`
}

type APIUsageRow struct {
	UsageID          string `json:"usage_id"`
	KeyRef           string `json:"key_ref"`
	PolicyKey        string `json:"policy_key"`
	UsageWindowStart string `json:"usage_window_start"`
	UsageWindowEnd   string `json:"usage_window_end"`
	RequestCount     int64  `json:"request_count"`
	RejectedCount    int64  `json:"rejected_count"`
	LastRequestAt    string `json:"last_request_at"`
	CreatedAt        string `json:"created_at"`
	UpdatedAt        string `json:"updated_at"`
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
		return "5920"
	}
	return port
}

func loadConfig() PublicAPIRuntimeConfig {
	dsn := envOrDefault("DB_READ_DSN", "")
	if dsn == "" {
		dsn = envOrDefault("DB_WRITE_DSN", "")
	}

	return PublicAPIRuntimeConfig{
		Port: normalizePort(envOrDefault("PUBLICAPI_RUNTIME_PORT", "5920")),
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

func scanInt64(value sql.NullInt64) int64 {
	if value.Valid {
		return value.Int64
	}
	return 0
}

func scanBool(value sql.NullBool) bool {
	if value.Valid {
		return value.Bool
	}
	return false
}

func scanTime(value sql.NullTime) string {
	if value.Valid {
		return value.Time.UTC().Format(time.RFC3339)
	}
	return ""
}

func setupRoutes(app *fiber.App, db *sql.DB, cfg PublicAPIRuntimeConfig) {
	app.Get("/health", func(c *fiber.Ctx) error {
		if db == nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "publicapi-runtime",
				"db":      "not_configured",
				"port":    cfg.Port,
			})
		}

		if err := db.PingContext(c.Context()); err != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "publicapi-runtime",
				"db":      "fail",
				"port":    cfg.Port,
			})
		}

		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "publicapi-runtime",
			"db":      "ok",
			"port":    cfg.Port,
		})
	})

	app.Get("/api/publicapi/summary", func(c *fiber.Ctx) error {
		const query = `
WITH key_counts AS (
  SELECT coalesce(status::text, 'unknown') AS status, count(*)::int AS count
  FROM runtime.api_keys
  GROUP BY coalesce(status::text, 'unknown')
),
key_count AS (
  SELECT count(*)::int AS count FROM runtime.api_keys
),
policy_count AS (
  SELECT count(*)::int AS count FROM runtime.api_quota_policies
),
usage_count AS (
  SELECT count(*)::int AS count FROM runtime.api_key_usage
),
usage_totals AS (
  SELECT
    coalesce(sum(request_count), 0)::bigint AS request_count,
    coalesce(sum(rejected_count), 0)::bigint AS rejected_count
  FROM runtime.api_key_usage
)
SELECT
  kc.status,
  kc.count,
  (SELECT count FROM key_count) AS key_count,
  (SELECT count FROM policy_count) AS policy_count,
  (SELECT count FROM usage_count) AS usage_count,
  (SELECT request_count FROM usage_totals) AS request_count,
  (SELECT rejected_count FROM usage_totals) AS rejected_count,
  now() AS generated_at
FROM key_counts kc
UNION ALL
SELECT
  'empty',
  0,
  (SELECT count FROM key_count),
  (SELECT count FROM policy_count),
  (SELECT count FROM usage_count),
  (SELECT request_count FROM usage_totals),
  (SELECT rejected_count FROM usage_totals),
  now()
WHERE NOT EXISTS (SELECT 1 FROM runtime.api_keys)
ORDER BY status;
`
		rows, err := db.QueryContext(c.Context(), query)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "public api summary okunamadi",
			})
		}
		defer rows.Close()

		items := make([]PublicAPISummaryItem, 0)
		for rows.Next() {
			var item PublicAPISummaryItem
			var generatedAt time.Time

			if err := rows.Scan(
				&item.Status,
				&item.Count,
				&item.KeyCount,
				&item.PolicyCount,
				&item.UsageCount,
				&item.RequestCount,
				&item.RejectedCount,
				&generatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "public api summary parse edilemedi",
				})
			}

			item.GeneratedAt = generatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{"items": items})
	})

	app.Get("/api/publicapi/api-keys", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)

		const query = `
SELECT
  key_ref,
  display_name,
  visibility_scope::text,
  key_prefix,
  status::text,
  last_used_at,
  expires_at,
  revoked_at,
  created_at,
  updated_at
FROM runtime.api_keys
ORDER BY updated_at DESC, key_ref
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "api keys okunamadi",
			})
		}
		defer rows.Close()

		items := make([]APIKeyRow, 0)
		for rows.Next() {
			var item APIKeyRow
			var lastUsedAt sql.NullTime
			var expiresAt sql.NullTime
			var revokedAt sql.NullTime
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(
				&item.KeyRef,
				&item.DisplayName,
				&item.VisibilityScope,
				&item.KeyPrefix,
				&item.Status,
				&lastUsedAt,
				&expiresAt,
				&revokedAt,
				&createdAt,
				&updatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "api keys parse edilemedi",
				})
			}

			item.LastUsedAt = scanTime(lastUsedAt)
			item.ExpiresAt = scanTime(expiresAt)
			item.RevokedAt = scanTime(revokedAt)
			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
			item.UpdatedAt = updatedAt.UTC().Format(time.RFC3339)

			items = append(items, item)
		}

		return c.JSON(fiber.Map{"items": items, "limit": limit})
	})

	app.Get("/api/publicapi/quota-policies", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)

		const query = `
SELECT
  p.policy_key,
  coalesce(k.key_ref, ''),
  p.endpoint_scope,
  p.quota_period::text,
  p.request_limit,
  p.burst_limit,
  p.is_enabled,
  p.created_at,
  p.updated_at
FROM runtime.api_quota_policies p
LEFT JOIN runtime.api_keys k ON k.id = p.api_key_id
ORDER BY p.updated_at DESC, p.policy_key
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "quota policies okunamadi",
			})
		}
		defer rows.Close()

		items := make([]APIQuotaPolicyRow, 0)
		for rows.Next() {
			var item APIQuotaPolicyRow
			var requestLimit sql.NullInt64
			var burstLimit sql.NullInt64
			var isEnabled sql.NullBool
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(
				&item.PolicyKey,
				&item.KeyRef,
				&item.EndpointScope,
				&item.QuotaPeriod,
				&requestLimit,
				&burstLimit,
				&isEnabled,
				&createdAt,
				&updatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "quota policies parse edilemedi",
				})
			}

			item.RequestLimit = scanInt(requestLimit)
			item.BurstLimit = scanInt(burstLimit)
			item.IsEnabled = scanBool(isEnabled)
			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
			item.UpdatedAt = updatedAt.UTC().Format(time.RFC3339)

			items = append(items, item)
		}

		return c.JSON(fiber.Map{"items": items, "limit": limit})
	})

	app.Get("/api/publicapi/usage", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)

		const query = `
SELECT
  u.id::text,
  coalesce(k.key_ref, ''),
  coalesce(p.policy_key, ''),
  u.usage_window_start,
  u.usage_window_end,
  u.request_count,
  u.rejected_count,
  u.last_request_at,
  u.created_at,
  u.updated_at
FROM runtime.api_key_usage u
LEFT JOIN runtime.api_keys k ON k.id = u.api_key_id
LEFT JOIN runtime.api_quota_policies p ON p.id = u.policy_id
ORDER BY u.updated_at DESC, u.usage_window_start DESC
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "api usage okunamadi",
			})
		}
		defer rows.Close()

		items := make([]APIUsageRow, 0)
		for rows.Next() {
			var item APIUsageRow
			var windowStart sql.NullTime
			var windowEnd sql.NullTime
			var requestCount sql.NullInt64
			var rejectedCount sql.NullInt64
			var lastRequestAt sql.NullTime
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(
				&item.UsageID,
				&item.KeyRef,
				&item.PolicyKey,
				&windowStart,
				&windowEnd,
				&requestCount,
				&rejectedCount,
				&lastRequestAt,
				&createdAt,
				&updatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "api usage parse edilemedi",
				})
			}

			item.UsageWindowStart = scanTime(windowStart)
			item.UsageWindowEnd = scanTime(windowEnd)
			item.RequestCount = scanInt64(requestCount)
			item.RejectedCount = scanInt64(rejectedCount)
			item.LastRequestAt = scanTime(lastRequestAt)
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
