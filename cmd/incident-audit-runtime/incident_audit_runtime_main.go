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

type IncidentAuditRuntimeConfig struct {
	Port string
	DSN  string
}

type IncidentAuditSummaryItem struct {
	AlertLevel            string `json:"alert_level"`
	IncidentCount         int    `json:"incident_count"`
	OpenIncidentCount     int    `json:"open_incident_count"`
	CriticalIncidentCount int    `json:"critical_incident_count"`
	AuditEventCount       int    `json:"audit_event_count"`
	AuditLogCount         int    `json:"audit_log_count"`
	RecentAuditLogCount   int    `json:"recent_audit_log_count"`
	GeneratedAt           string `json:"generated_at"`
}

type IncidentRow struct {
	IncidentID     string `json:"incident_id"`
	TenantID       string `json:"tenant_id"`
	BusinessCode   string `json:"business_code"`
	IncidentKey    string `json:"incident_key"`
	Title          string `json:"title"`
	Summary        string `json:"summary"`
	Severity       string `json:"severity"`
	Status         string `json:"status"`
	Source         string `json:"source"`
	OwnerTeam      string `json:"owner_team"`
	OpenedBy       string `json:"opened_by"`
	AcknowledgedBy string `json:"acknowledged_by"`
	ResolvedBy     string `json:"resolved_by"`
	DetectedAt     string `json:"detected_at"`
	AcknowledgedAt string `json:"acknowledged_at"`
	ResolvedAt     string `json:"resolved_at"`
	ClosedAt       string `json:"closed_at"`
	CreatedAt      string `json:"created_at"`
	UpdatedAt      string `json:"updated_at"`
}

type AuditEventRow struct {
	EventID       string `json:"event_id"`
	TenantID      string `json:"tenant_id"`
	ActorUserID   string `json:"actor_user_id"`
	EventCode     string `json:"event_code"`
	EntitySchema  string `json:"entity_schema"`
	EntityTable   string `json:"entity_table"`
	EntityID      string `json:"entity_id"`
	Payload       string `json:"payload"`
	CreatedAt     string `json:"created_at"`
}

type AuditLogRow struct {
	LogID      int64  `json:"log_id"`
	TenantID   string `json:"tenant_id"`
	ActorType  string `json:"actor_type"`
	ActorID    string `json:"actor_id"`
	Action     string `json:"action"`
	EntityType string `json:"entity_type"`
	EntityID   string `json:"entity_id"`
	Status     string `json:"status"`
	Details    string `json:"details"`
	CreatedAt  string `json:"created_at"`
}

type TimelineRow struct {
	Source    string `json:"source"`
	RefID     string `json:"ref_id"`
	Title     string `json:"title"`
	Status    string `json:"status"`
	Severity  string `json:"severity"`
	Actor     string `json:"actor"`
	Entity    string `json:"entity"`
	CreatedAt string `json:"created_at"`
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
		return "5950"
	}

	return port
}

func loadConfig() IncidentAuditRuntimeConfig {
	dsn := envOrDefault("DB_READ_DSN", "")
	if dsn == "" {
		dsn = envOrDefault("DB_WRITE_DSN", "")
	}

	return IncidentAuditRuntimeConfig{
		Port: normalizePort(envOrDefault("INCIDENT_AUDIT_RUNTIME_PORT", "5950")),
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

func alertLevel(openIncidents int, criticalIncidents int) string {
	if criticalIncidents > 0 {
		return "critical"
	}

	if openIncidents > 0 {
		return "warning"
	}

	return "ok"
}

func setupRoutes(app *fiber.App, db *sql.DB, cfg IncidentAuditRuntimeConfig) {
	app.Get("/health", func(c *fiber.Ctx) error {
		if db == nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "incident-audit-runtime",
				"db":      "not_configured",
				"port":    cfg.Port,
			})
		}

		if err := db.PingContext(c.Context()); err != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "incident-audit-runtime",
				"db":      "fail",
				"port":    cfg.Port,
			})
		}

		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "incident-audit-runtime",
			"db":      "ok",
			"port":    cfg.Port,
		})
	})

	app.Get("/api/incident-audit/summary", func(c *fiber.Ctx) error {
		const query = `
SELECT
  (SELECT count(*)::int FROM runtime.mission_control_incidents) AS incident_count,
  (
    SELECT count(*)::int
    FROM runtime.mission_control_incidents
    WHERE lower(status::text) NOT IN ('resolved', 'closed')
  ) AS open_incident_count,
  (
    SELECT count(*)::int
    FROM runtime.mission_control_incidents
    WHERE lower(severity::text) IN ('critical', 'p0', 'p1', 'sev1')
      AND lower(status::text) NOT IN ('resolved', 'closed')
  ) AS critical_incident_count,
  (SELECT count(*)::int FROM audit.audit_events) AS audit_event_count,
  (SELECT count(*)::int FROM public.audit_logs) AS audit_log_count,
  (
    SELECT count(*)::int
    FROM public.audit_logs
    WHERE created_at >= now() - interval '24 hours'
  ) AS recent_audit_log_count,
  now() AS generated_at;
`
		var item IncidentAuditSummaryItem
		var generatedAt time.Time

		if err := db.QueryRowContext(c.Context(), query).Scan(
			&item.IncidentCount,
			&item.OpenIncidentCount,
			&item.CriticalIncidentCount,
			&item.AuditEventCount,
			&item.AuditLogCount,
			&item.RecentAuditLogCount,
			&generatedAt,
		); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "incident audit summary okunamadi",
			})
		}

		item.AlertLevel = alertLevel(item.OpenIncidentCount, item.CriticalIncidentCount)
		item.GeneratedAt = generatedAt.UTC().Format(time.RFC3339)

		return c.JSON(fiber.Map{
			"items": []IncidentAuditSummaryItem{item},
		})
	})

	app.Get("/api/incident-audit/incidents", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)

		const query = `
SELECT
  id::text,
  tenant_id::text,
  business_code,
  incident_key,
  title,
  coalesce(summary, ''),
  severity::text,
  status::text,
  coalesce(source, ''),
  coalesce(owner_team, ''),
  coalesce(opened_by, ''),
  coalesce(acknowledged_by, ''),
  coalesce(resolved_by, ''),
  detected_at,
  acknowledged_at,
  resolved_at,
  closed_at,
  created_at,
  updated_at
FROM runtime.mission_control_incidents
ORDER BY created_at DESC, incident_key
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "incidents okunamadi",
			})
		}
		defer rows.Close()

		items := make([]IncidentRow, 0)
		for rows.Next() {
			var item IncidentRow
			var detectedAt sql.NullTime
			var acknowledgedAt sql.NullTime
			var resolvedAt sql.NullTime
			var closedAt sql.NullTime
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(
				&item.IncidentID,
				&item.TenantID,
				&item.BusinessCode,
				&item.IncidentKey,
				&item.Title,
				&item.Summary,
				&item.Severity,
				&item.Status,
				&item.Source,
				&item.OwnerTeam,
				&item.OpenedBy,
				&item.AcknowledgedBy,
				&item.ResolvedBy,
				&detectedAt,
				&acknowledgedAt,
				&resolvedAt,
				&closedAt,
				&createdAt,
				&updatedAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "incidents parse edilemedi",
				})
			}

			item.DetectedAt = scanTime(detectedAt)
			item.AcknowledgedAt = scanTime(acknowledgedAt)
			item.ResolvedAt = scanTime(resolvedAt)
			item.ClosedAt = scanTime(closedAt)
			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
			item.UpdatedAt = updatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{"items": items, "limit": limit})
	})

	app.Get("/api/incident-audit/audit-events", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)

		const query = `
SELECT
  id::text,
  tenant_id::text,
  coalesce(actor_user_id::text, ''),
  event_code,
  coalesce(entity_schema, ''),
  coalesce(entity_table, ''),
  coalesce(entity_id::text, ''),
  coalesce(payload::text, '{}'),
  created_at
FROM audit.audit_events
ORDER BY created_at DESC, event_code
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "audit events okunamadi",
			})
		}
		defer rows.Close()

		items := make([]AuditEventRow, 0)
		for rows.Next() {
			var item AuditEventRow
			var createdAt time.Time

			if err := rows.Scan(
				&item.EventID,
				&item.TenantID,
				&item.ActorUserID,
				&item.EventCode,
				&item.EntitySchema,
				&item.EntityTable,
				&item.EntityID,
				&item.Payload,
				&createdAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "audit events parse edilemedi",
				})
			}

			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{"items": items, "limit": limit})
	})

	app.Get("/api/incident-audit/audit-logs", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)

		const query = `
SELECT
  id,
  coalesce(tenant_id, ''),
  coalesce(actor_type, ''),
  coalesce(actor_id, ''),
  coalesce(action, ''),
  coalesce(entity_type, ''),
  coalesce(entity_id, ''),
  coalesce(status, ''),
  coalesce(details::text, '{}'),
  created_at
FROM public.audit_logs
ORDER BY created_at DESC, id DESC
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "audit logs okunamadi",
			})
		}
		defer rows.Close()

		items := make([]AuditLogRow, 0)
		for rows.Next() {
			var item AuditLogRow
			var createdAt time.Time

			if err := rows.Scan(
				&item.LogID,
				&item.TenantID,
				&item.ActorType,
				&item.ActorID,
				&item.Action,
				&item.EntityType,
				&item.EntityID,
				&item.Status,
				&item.Details,
				&createdAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "audit logs parse edilemedi",
				})
			}

			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{"items": items, "limit": limit})
	})

	app.Get("/api/incident-audit/timeline", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 50, 200)

		const query = `
SELECT *
FROM (
  SELECT
    'incident' AS source,
    id::text AS ref_id,
    title AS title,
    status::text AS status,
    severity::text AS severity,
    coalesce(opened_by, '') AS actor,
    coalesce(service_id::text, '') AS entity,
    created_at AS created_at
  FROM runtime.mission_control_incidents

  UNION ALL

  SELECT
    'audit_event' AS source,
    id::text AS ref_id,
    event_code AS title,
    'recorded' AS status,
    '' AS severity,
    coalesce(actor_user_id::text, '') AS actor,
    coalesce(entity_table, '') || ':' || coalesce(entity_id::text, '') AS entity,
    created_at AS created_at
  FROM audit.audit_events

  UNION ALL

  SELECT
    'audit_log' AS source,
    id::text AS ref_id,
    action AS title,
    coalesce(status, '') AS status,
    '' AS severity,
    coalesce(actor_type, '') || ':' || coalesce(actor_id, '') AS actor,
    coalesce(entity_type, '') || ':' || coalesce(entity_id, '') AS entity,
    created_at AS created_at
  FROM public.audit_logs
) timeline
ORDER BY created_at DESC
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error": "incident audit timeline okunamadi",
			})
		}
		defer rows.Close()

		items := make([]TimelineRow, 0)
		for rows.Next() {
			var item TimelineRow
			var createdAt time.Time

			if err := rows.Scan(
				&item.Source,
				&item.RefID,
				&item.Title,
				&item.Status,
				&item.Severity,
				&item.Actor,
				&item.Entity,
				&createdAt,
			); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
					"error": "incident audit timeline parse edilemedi",
				})
			}

			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
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
