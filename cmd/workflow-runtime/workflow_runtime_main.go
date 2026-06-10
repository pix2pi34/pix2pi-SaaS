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

type WorkflowRuntimeConfig struct {
	Port string
	DSN  string
}

type WorkflowSummaryItem struct {
	Status          string `json:"status"`
	Count           int    `json:"count"`
	DefinitionCount int    `json:"definition_count"`
	StepCount       int    `json:"step_count"`
	ApprovalCount   int    `json:"approval_count"`
	GeneratedAt     string `json:"generated_at"`
}

type WorkflowDefinitionRow struct {
	WorkflowKey      string `json:"workflow_key"`
	DisplayName      string `json:"display_name"`
	VersionNo        int    `json:"version_no"`
	VisibilityScope string `json:"visibility_scope"`
	DefinitionStatus string `json:"definition_status"`
	TriggerEvent     string `json:"trigger_event"`
	IsEnabled        bool   `json:"is_enabled"`
	CreatedAt        string `json:"created_at"`
	UpdatedAt        string `json:"updated_at"`
}

type WorkflowInstanceRow struct {
	InstanceID     string `json:"instance_id"`
	WorkflowKey    string `json:"workflow_key"`
	InstanceKey    string `json:"instance_key"`
	WorkflowStatus string `json:"workflow_status"`
	SubjectRefType string `json:"subject_ref_type"`
	SubjectRefID   string `json:"subject_ref_id"`
	CurrentStepKey string `json:"current_step_key"`
	StartedAt      string `json:"started_at"`
	FinishedAt     string `json:"finished_at"`
	CreatedAt      string `json:"created_at"`
	UpdatedAt      string `json:"updated_at"`
}

type WorkflowStepRow struct {
	StepID      string `json:"step_id"`
	InstanceKey string `json:"instance_key"`
	StepKey     string `json:"step_key"`
	StepOrder   int    `json:"step_order"`
	StepType    string `json:"step_type"`
	StepStatus  string `json:"step_status"`
	AssignedTo  string `json:"assigned_to"`
	StartedAt   string `json:"started_at"`
	FinishedAt  string `json:"finished_at"`
	CreatedAt   string `json:"created_at"`
	UpdatedAt   string `json:"updated_at"`
}

type WorkflowApprovalRow struct {
	ApprovalID     string `json:"approval_id"`
	InstanceKey    string `json:"instance_key"`
	StepID         string `json:"step_id"`
	ApprovalKey    string `json:"approval_key"`
	ApproverRef    string `json:"approver_ref"`
	ApprovalStatus string `json:"approval_status"`
	RequestedAt    string `json:"requested_at"`
	RespondedAt    string `json:"responded_at"`
	ResponseNote   string `json:"response_note"`
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
		return "5900"
	}
	return port
}

func loadConfig() WorkflowRuntimeConfig {
	dsn := envOrDefault("DB_READ_DSN", "")
	if dsn == "" {
		dsn = envOrDefault("DB_WRITE_DSN", "")
	}

	return WorkflowRuntimeConfig{
		Port: normalizePort(envOrDefault("WORKFLOW_RUNTIME_PORT", "5900")),
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

func scanTime(value sql.NullTime) string {
	if value.Valid {
		return value.Time.UTC().Format(time.RFC3339)
	}
	return ""
}

func setupRoutes(app *fiber.App, db *sql.DB, cfg WorkflowRuntimeConfig) {
	app.Get("/health", func(c *fiber.Ctx) error {
		if db == nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "workflow-runtime",
				"db":      "not_configured",
				"port":    cfg.Port,
			})
		}

		if err := db.PingContext(c.Context()); err != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "error",
				"service": "workflow-runtime",
				"db":      "fail",
				"port":    cfg.Port,
			})
		}

		return c.JSON(fiber.Map{
			"status":  "ok",
			"service": "workflow-runtime",
			"db":      "ok",
			"port":    cfg.Port,
		})
	})

	app.Get("/api/workflows/summary", func(c *fiber.Ctx) error {
		const query = `
WITH instance_counts AS (
  SELECT coalesce(workflow_status::text, 'unknown') AS status, count(*)::int AS count
  FROM runtime.workflow_instances
  GROUP BY coalesce(workflow_status::text, 'unknown')
),
definition_count AS (
  SELECT count(*)::int AS count FROM runtime.workflow_definitions
),
step_count AS (
  SELECT count(*)::int AS count FROM runtime.workflow_steps
),
approval_count AS (
  SELECT count(*)::int AS count FROM runtime.workflow_approvals
)
SELECT
  ic.status,
  ic.count,
  (SELECT count FROM definition_count) AS definition_count,
  (SELECT count FROM step_count) AS step_count,
  (SELECT count FROM approval_count) AS approval_count,
  now() AS generated_at
FROM instance_counts ic
UNION ALL
SELECT
  'empty',
  0,
  (SELECT count FROM definition_count),
  (SELECT count FROM step_count),
  (SELECT count FROM approval_count),
  now()
WHERE NOT EXISTS (SELECT 1 FROM runtime.workflow_instances)
ORDER BY status;
`
		rows, err := db.QueryContext(c.Context(), query)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "workflow summary okunamadi"})
		}
		defer rows.Close()

		items := make([]WorkflowSummaryItem, 0)
		for rows.Next() {
			var item WorkflowSummaryItem
			var generatedAt time.Time

			if err := rows.Scan(&item.Status, &item.Count, &item.DefinitionCount, &item.StepCount, &item.ApprovalCount, &generatedAt); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "workflow summary parse edilemedi"})
			}

			item.GeneratedAt = generatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{"items": items})
	})

	app.Get("/api/workflows/definitions", func(c *fiber.Ctx) error {
		const query = `
SELECT
  workflow_key,
  display_name,
  coalesce(version_no, 0),
  visibility_scope::text,
  definition_status::text,
  coalesce(trigger_event, ''),
  is_enabled,
  created_at,
  updated_at
FROM runtime.workflow_definitions
ORDER BY updated_at DESC, workflow_key;
`
		rows, err := db.QueryContext(c.Context(), query)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "workflow definitions okunamadi"})
		}
		defer rows.Close()

		items := make([]WorkflowDefinitionRow, 0)
		for rows.Next() {
			var item WorkflowDefinitionRow
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(&item.WorkflowKey, &item.DisplayName, &item.VersionNo, &item.VisibilityScope, &item.DefinitionStatus, &item.TriggerEvent, &item.IsEnabled, &createdAt, &updatedAt); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "workflow definitions parse edilemedi"})
			}

			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
			item.UpdatedAt = updatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{"items": items})
	})

	app.Get("/api/workflows/instances", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 25, 100)

		const query = `
SELECT
  i.id::text,
  coalesce(d.workflow_key, ''),
  i.instance_key,
  i.workflow_status::text,
  coalesce(i.subject_ref_type, ''),
  coalesce(i.subject_ref_id, ''),
  coalesce(i.current_step_key, ''),
  i.started_at,
  i.finished_at,
  i.created_at,
  i.updated_at
FROM runtime.workflow_instances i
LEFT JOIN runtime.workflow_definitions d ON d.id = i.definition_id
ORDER BY i.created_at DESC
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "workflow instances okunamadi"})
		}
		defer rows.Close()

		items := make([]WorkflowInstanceRow, 0)
		for rows.Next() {
			var item WorkflowInstanceRow
			var startedAt sql.NullTime
			var finishedAt sql.NullTime
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(&item.InstanceID, &item.WorkflowKey, &item.InstanceKey, &item.WorkflowStatus, &item.SubjectRefType, &item.SubjectRefID, &item.CurrentStepKey, &startedAt, &finishedAt, &createdAt, &updatedAt); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "workflow instances parse edilemedi"})
			}

			item.StartedAt = scanTime(startedAt)
			item.FinishedAt = scanTime(finishedAt)
			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
			item.UpdatedAt = updatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{"items": items, "limit": limit})
	})

	app.Get("/api/workflows/steps", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 25, 100)

		const query = `
SELECT
  s.id::text,
  coalesce(i.instance_key, ''),
  s.step_key,
  coalesce(s.step_order, 0),
  s.step_type,
  s.step_status::text,
  coalesce(s.assigned_to, ''),
  s.started_at,
  s.finished_at,
  s.created_at,
  s.updated_at
FROM runtime.workflow_steps s
LEFT JOIN runtime.workflow_instances i ON i.id = s.instance_id
ORDER BY s.created_at DESC
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "workflow steps okunamadi"})
		}
		defer rows.Close()

		items := make([]WorkflowStepRow, 0)
		for rows.Next() {
			var item WorkflowStepRow
			var startedAt sql.NullTime
			var finishedAt sql.NullTime
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(&item.StepID, &item.InstanceKey, &item.StepKey, &item.StepOrder, &item.StepType, &item.StepStatus, &item.AssignedTo, &startedAt, &finishedAt, &createdAt, &updatedAt); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "workflow steps parse edilemedi"})
			}

			item.StartedAt = scanTime(startedAt)
			item.FinishedAt = scanTime(finishedAt)
			item.CreatedAt = createdAt.UTC().Format(time.RFC3339)
			item.UpdatedAt = updatedAt.UTC().Format(time.RFC3339)
			items = append(items, item)
		}

		return c.JSON(fiber.Map{"items": items, "limit": limit})
	})

	app.Get("/api/workflows/approvals", func(c *fiber.Ctx) error {
		limit := parseLimit(c.Query("limit"), 25, 100)

		const query = `
SELECT
  a.id::text,
  coalesce(i.instance_key, ''),
  coalesce(a.step_id::text, ''),
  a.approval_key,
  a.approver_ref,
  a.approval_status::text,
  a.requested_at,
  a.responded_at,
  coalesce(a.response_note, ''),
  a.created_at,
  a.updated_at
FROM runtime.workflow_approvals a
LEFT JOIN runtime.workflow_instances i ON i.id = a.instance_id
ORDER BY a.created_at DESC
LIMIT $1;
`
		rows, err := db.QueryContext(c.Context(), query, limit)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "workflow approvals okunamadi"})
		}
		defer rows.Close()

		items := make([]WorkflowApprovalRow, 0)
		for rows.Next() {
			var item WorkflowApprovalRow
			var requestedAt sql.NullTime
			var respondedAt sql.NullTime
			var createdAt time.Time
			var updatedAt time.Time

			if err := rows.Scan(&item.ApprovalID, &item.InstanceKey, &item.StepID, &item.ApprovalKey, &item.ApproverRef, &item.ApprovalStatus, &requestedAt, &respondedAt, &item.ResponseNote, &createdAt, &updatedAt); err != nil {
				return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "workflow approvals parse edilemedi"})
			}

			item.RequestedAt = scanTime(requestedAt)
			item.RespondedAt = scanTime(respondedAt)
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
