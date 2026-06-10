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

type PluginRuntimeConfig struct {
	Port string
	DSN  string
}

type PluginSummaryItem struct {
	Status      string `json:"status"`
	Count       int    `json:"count"`
	PluginCount int    `json:"plugin_count"`
	StateCount  int    `json:"state_count"`
	GeneratedAt string `json:"generated_at"`
}

type PluginRow struct {
	PluginKey               string `json:"plugin_key"`
	DisplayName             string `json:"display_name"`
	VersionNo               string `json:"version_no"`
	VisibilityScope         string `json:"visibility_scope"`
	SourceType              string `json:"source_type"`
	LifecycleStatus         string `json:"lifecycle_status"`
	EntrypointRef           string `json:"entrypoint_ref"`
	Checksum                string `json:"checksum"`
	RequiredPlatformVersion string `json:"required_platform_version"`
	IsEnabled               bool   `json:"is_enabled"`
	PublishedAt             string `json:"published_at"`
	DeprecatedAt            string `json:"deprecated_at"`
	ArchivedAt              string `json:"archived_at"`
	CreatedAt               string `json:"created_at"`
	UpdatedAt               string `json:"updated_at"`
}

type PluginStateRow struct {
	StateID       string `json:"state_id"`
	PluginKey     string `json:"plugin_key"`
	StateKey      string `json:"state_key"`
	DesiredState  string `json:"desired_state"`
	CurrentState  string `json:"current_state"`
	InstallRef    string `json:"install_ref"`
	InstalledAt   string `json:"installed_at"`
	ActivatedAt   string `json:"activated_at"`
	DeactivatedAt string `json:"deactivated_at"`
	LastHealthAt  string `json:"last_health_at"`
	LastError     string `json:"last_error"`
	CreatedAt     string `json:"created_at"`
	UpdatedAt     string `json:"updated_at"`
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
		return "5910"
	}
	return port
}

func loadConfig() PluginRuntimeConfig {
	dsn := envOrDefault("DB_READ_DSN", "")
	if dsn == "" {
		dsn = envOrDefault("DB_WRITE_DSN", "")
	}

	return PluginRuntimeConfig{
		Port: normalizePort(envOrDefault("PLUGIN_RUNTIME_PORT", "5910")),
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

func setupRoutes(app *fiber.App, db *sql.DB, cfg PluginRuntimeConfig) {
	app.Get("/health", func(c *fiber.Ctx) error {
		if db == nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "plugin-runtime",
				"db":      "not_configured",
				"port":    cfg.Port,
			})
		}

		if err := db.PingContext(c.Context()); err != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "plugin-runtime",
				"db":      "fail",
				"port":    cfg.Port,
			})
		}

		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "plugin-runtime",
			"db":      "ok",
			"port":    cfg.Port,
		})
	})

	app.Get("/api/plugins/summary", func(c *fiber.Ctx) error {
		const query = `
WITH plugin_counts AS (
  SELECT coalesce(lifecycle_status::text, 'unknown') AS status, count(*)::int AS count
  FROM runtime.plugins
  GROUP BY coalesce(lifecycle_status::text, 'unknown')
),
plugin_count AS (
  SELECT count(*)::int AS count FROM runtime.plugins
),
state_count AS (
  SELECT count(*)::int AS count FROM runtime.plugin_states
)
SELECT
  pc.status,
  pc.count,
  (SELECT count FROM plugin_count) AS plugin_count,
  (SELECT count FROM state_count) AS state_count,
  now() AS generated_at
FROM plugin_counts pc
UNION ALL
SELECT
  'empty',
  0,
  (SELECT count FROM plugin_count),
  (SELECT count FROM state_count),
  now()
WHERE NOT EXISTS (SELECT 1 FROM runtime.plugins)
ORDER BY status;
`
		rows, err := db.QueryContext(c.Context(), query)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "plugin summary okunamadi",
			})
		}
		defer rows.Close()

		items := make([]PluginSummaryItem, 0)
		for rows.Next() {
			var item PluginSummaryItem
			var generatedAt time.Time

			if err := rows.Scan(
				&item.Status,
				&item.Count,
				&item.PluginCount,
				&item.StateCount,
				&generatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "plugin summary parse edilemedi",
				})
			}

			item.GeneratedAt = generatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{
			"items": items,
		})
	})

	app.Get("/api/plugins/catalog", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)

		const query = `
SELECT
  plugin_key,
  display_name,
  version_no,
  visibility_scope::text,
  source_type::text,
  lifecycle_status::text,
  entrypoint_ref,
  checksum,
  required_platform_version,
  is_enabled,
  published_at,
  deprecated_at,
  archived_at,
  created_at,
  updated_at
FROM runtime.plugins
ORDER BY updated_at DESC, plugin_key
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "plugin catalog okunamadi",
			})
		}
		defer rows.Close()

		items := make([]PluginRow, 0)
		for rows.Next() {
			var item PluginRow
			var entrypointRef sql.NullString
			var checksum sql.NullString
			var requiredPlatformVersion sql.NullString
			var publishedAt sql.NullTime
			var deprecatedAt sql.NullTime
			var archivedAt sql.NullTime
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(
				&item.PluginKey,
				&item.DisplayName,
				&item.VersionNo,
				&item.VisibilityScope,
				&item.SourceType,
				&item.LifecycleStatus,
				&entrypointRef,
				&checksum,
				&requiredPlatformVersion,
				&item.IsEnabled,
				&publishedAt,
				&deprecatedAt,
				&archivedAt,
				&createdAt,
				&updatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "plugin catalog parse edilemedi",
				})
			}

			item.EntrypointRef = scanString(entrypointRef)
			item.Checksum = scanString(checksum)
			item.RequiredPlatformVersion = scanString(requiredPlatformVersion)
			item.PublishedAt = scanTime(publishedAt)
			item.DeprecatedAt = scanTime(deprecatedAt)
			item.ArchivedAt = scanTime(archivedAt)
			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
			item.UpdatedAt = updatedAt.UTC().Format(time.RFC3339)

			items = append(items, item)
		}

		return c.JSON(fiber.Map{
			"items": items,
			"limit": limit,
		})
	})

	app.Get("/api/plugins/states", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)

		const query = `
SELECT
  s.id::text,
  coalesce(p.plugin_key, ''),
  s.state_key,
  s.desired_state::text,
  s.current_state::text,
  coalesce(s.install_ref, ''),
  s.installed_at,
  s.activated_at,
  s.deactivated_at,
  s.last_health_at,
  coalesce(s.last_error, ''),
  s.created_at,
  s.updated_at
FROM runtime.plugin_states s
LEFT JOIN runtime.plugins p ON p.id = s.plugin_id
ORDER BY s.updated_at DESC, s.state_key
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "plugin states okunamadi",
			})
		}
		defer rows.Close()

		items := make([]PluginStateRow, 0)
		for rows.Next() {
			var item PluginStateRow
			var installedAt sql.NullTime
			var activatedAt sql.NullTime
			var deactivatedAt sql.NullTime
			var lastHealthAt sql.NullTime
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(
				&item.StateID,
				&item.PluginKey,
				&item.StateKey,
				&item.DesiredState,
				&item.CurrentState,
				&item.InstallRef,
				&installedAt,
				&activatedAt,
				&deactivatedAt,
				&lastHealthAt,
				&item.LastError,
				&createdAt,
				&updatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "plugin states parse edilemedi",
				})
			}

			item.InstalledAt = scanTime(installedAt)
			item.ActivatedAt = scanTime(activatedAt)
			item.DeactivatedAt = scanTime(deactivatedAt)
			item.LastHealthAt = scanTime(lastHealthAt)
			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
			item.UpdatedAt = updatedAt.UTC().Format(time.RFC3339)

			items = append(items, item)
		}

		return c.JSON(fiber.Map{
			"items": items,
			"limit": limit,
		})
	})

	app.Get("/api/plugins/runtime", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)

		const query = `
SELECT
  s.id::text,
  coalesce(p.plugin_key, ''),
  s.state_key,
  s.desired_state::text,
  s.current_state::text,
  coalesce(s.install_ref, ''),
  s.installed_at,
  s.activated_at,
  s.deactivated_at,
  s.last_health_at,
  coalesce(s.last_error, ''),
  s.created_at,
  s.updated_at
FROM runtime.plugin_states s
LEFT JOIN runtime.plugins p ON p.id = s.plugin_id
ORDER BY s.last_health_at DESC NULLS LAST, s.updated_at DESC
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "plugin runtime okunamadi",
			})
		}
		defer rows.Close()

		items := make([]PluginStateRow, 0)
		for rows.Next() {
			var item PluginStateRow
			var installedAt sql.NullTime
			var activatedAt sql.NullTime
			var deactivatedAt sql.NullTime
			var lastHealthAt sql.NullTime
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(
				&item.StateID,
				&item.PluginKey,
				&item.StateKey,
				&item.DesiredState,
				&item.CurrentState,
				&item.InstallRef,
				&installedAt,
				&activatedAt,
				&deactivatedAt,
				&lastHealthAt,
				&item.LastError,
				&createdAt,
				&updatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "plugin runtime parse edilemedi",
				})
			}

			item.InstalledAt = scanTime(installedAt)
			item.ActivatedAt = scanTime(activatedAt)
			item.DeactivatedAt = scanTime(deactivatedAt)
			item.LastHealthAt = scanTime(lastHealthAt)
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
