package e2eflow

import (
	"context"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var _ RuntimeFlowStore = (*PostgresRuntimeFlowStore)(nil)

type PostgresRuntimeFlowStore struct {
	pool *pgxpool.Pool
}

func NewPostgresRuntimeFlowStore(pool *pgxpool.Pool) *PostgresRuntimeFlowStore {
	return &PostgresRuntimeFlowStore{pool: pool}
}

func (s *PostgresRuntimeFlowStore) PersistFlowPlan(ctx context.Context, plan RuntimeFlowPlan) (RuntimeFlowPlan, error) {
	if err := ValidateRuntimeFlowPlan(plan); err != nil {
		return RuntimeFlowPlan{}, err
	}

	tx, err := s.beginTenantTx(ctx, plan.TenantID)
	if err != nil {
		return RuntimeFlowPlan{}, err
	}
	defer tx.Rollback(ctx)

	flowID, err := upsertRuntimeFlow(ctx, tx, plan)
	if err != nil {
		return RuntimeFlowPlan{}, err
	}

	if _, err := tx.Exec(ctx, `
DELETE FROM erp_runtime_flow_steps
WHERE tenant_id = $1
  AND flow_id = $2;
`, plan.TenantID, flowID); err != nil {
		return RuntimeFlowPlan{}, err
	}

	for _, step := range plan.Steps {
		if err := insertRuntimeFlowStep(ctx, tx, plan.TenantID, flowID, step); err != nil {
			return RuntimeFlowPlan{}, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return RuntimeFlowPlan{}, err
	}

	return plan, nil
}

func (s *PostgresRuntimeFlowStore) MarkFlowCompleted(ctx context.Context, plan RuntimeFlowPlan) (RuntimeFlowPlan, error) {
	if err := ValidateRuntimeFlowPlan(plan); err != nil {
		return RuntimeFlowPlan{}, err
	}

	tx, err := s.beginTenantTx(ctx, plan.TenantID)
	if err != nil {
		return RuntimeFlowPlan{}, err
	}
	defer tx.Rollback(ctx)

	flowID, err := findRuntimeFlowID(ctx, tx, plan.TenantID, plan.IdempotencyKey)
	if err != nil {
		return RuntimeFlowPlan{}, err
	}

	commandTag, err := tx.Exec(ctx, `
UPDATE erp_runtime_flows
SET flow_status = 'completed',
    completed_at = COALESCE(completed_at, now()),
    failure_reason = NULL,
    updated_at = now(),
    updated_by = 'runtime'
WHERE tenant_id = $1
  AND flow_id = $2
  AND deleted_at IS NULL;
`, plan.TenantID, flowID)
	if err != nil {
		return RuntimeFlowPlan{}, err
	}

	if commandTag.RowsAffected() == 0 {
		return RuntimeFlowPlan{}, ErrFlowNotFound
	}

	for _, step := range plan.Steps {
		if _, err := tx.Exec(ctx, `
UPDATE erp_runtime_flow_steps
SET step_status = $3,
    message = COALESCE(NULLIF($4, ''), message, 'completed'),
    started_at = COALESCE(started_at, now()),
    completed_at = COALESCE(completed_at, now()),
    updated_at = now(),
    updated_by = 'runtime'
WHERE tenant_id = $1
  AND flow_id = $2
  AND step_no = $5
  AND deleted_at IS NULL;
`, plan.TenantID, flowID, string(step.Status), step.Message, step.StepNo); err != nil {
			return RuntimeFlowPlan{}, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return RuntimeFlowPlan{}, err
	}

	plan.Status = FlowStatusCompleted
	return plan, nil
}

func (s *PostgresRuntimeFlowStore) MarkFlowFailed(ctx context.Context, plan RuntimeFlowPlan, cause error) (RuntimeFlowPlan, error) {
	if err := ValidateRuntimeFlowPlan(plan); err != nil {
		return RuntimeFlowPlan{}, err
	}

	tx, err := s.beginTenantTx(ctx, plan.TenantID)
	if err != nil {
		return RuntimeFlowPlan{}, err
	}
	defer tx.Rollback(ctx)

	flowID, err := findRuntimeFlowID(ctx, tx, plan.TenantID, plan.IdempotencyKey)
	if err != nil {
		return RuntimeFlowPlan{}, err
	}

	failureReason := "unknown failure"
	if cause != nil && strings.TrimSpace(cause.Error()) != "" {
		failureReason = cause.Error()
	}

	commandTag, err := tx.Exec(ctx, `
UPDATE erp_runtime_flows
SET flow_status = 'failed',
    failed_at = now(),
    failure_reason = $3,
    updated_at = now(),
    updated_by = 'runtime'
WHERE tenant_id = $1
  AND flow_id = $2
  AND deleted_at IS NULL;
`, plan.TenantID, flowID, failureReason)
	if err != nil {
		return RuntimeFlowPlan{}, err
	}

	if commandTag.RowsAffected() == 0 {
		return RuntimeFlowPlan{}, ErrFlowNotFound
	}

	if _, err := tx.Exec(ctx, `
UPDATE erp_runtime_flow_steps
SET step_status = CASE
        WHEN step_status = 'completed' THEN step_status
        ELSE 'failed'
    END,
    failure_reason = CASE
        WHEN step_status = 'completed' THEN failure_reason
        ELSE $3
    END,
    updated_at = now(),
    updated_by = 'runtime'
WHERE tenant_id = $1
  AND flow_id = $2
  AND deleted_at IS NULL;
`, plan.TenantID, flowID, failureReason); err != nil {
		return RuntimeFlowPlan{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return RuntimeFlowPlan{}, err
	}

	plan.Status = FlowStatusFailed
	return plan, nil
}

func (s *PostgresRuntimeFlowStore) beginTenantTx(ctx context.Context, tenantID string) (pgx.Tx, error) {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}

	if _, err := tx.Exec(ctx, "SELECT set_config('app.tenant_id', $1, true);", tenantID); err != nil {
		_ = tx.Rollback(ctx)
		return nil, err
	}

	return tx, nil
}

func upsertRuntimeFlow(ctx context.Context, tx pgx.Tx, plan RuntimeFlowPlan) (string, error) {
	var flowID string

	if err := tx.QueryRow(ctx, `
INSERT INTO erp_runtime_flows (
    tenant_id,
    request_id,
    transaction_kind,
    source_module,
    source_document_type,
    source_document_id,
    source_document_no,
    total_amount,
    currency_code,
    exchange_rate,
    idempotency_key,
    correlation_id,
    flow_status,
    started_at,
    created_by,
    updated_by
) VALUES (
    $1, $2, $3, $4, $5, NULLIF($6, ''), NULLIF($7, ''),
    $8, $9, $10,
    $11, NULLIF($12, ''),
    $13,
    CASE WHEN $13 = 'running' THEN now() ELSE NULL END,
    'runtime',
    'runtime'
)
ON CONFLICT (tenant_id, idempotency_key)
DO UPDATE SET
    request_id = EXCLUDED.request_id,
    transaction_kind = EXCLUDED.transaction_kind,
    source_module = EXCLUDED.source_module,
    source_document_type = EXCLUDED.source_document_type,
    source_document_id = EXCLUDED.source_document_id,
    source_document_no = EXCLUDED.source_document_no,
    total_amount = EXCLUDED.total_amount,
    currency_code = EXCLUDED.currency_code,
    exchange_rate = EXCLUDED.exchange_rate,
    correlation_id = EXCLUDED.correlation_id,
    flow_status = EXCLUDED.flow_status,
    updated_at = now(),
    updated_by = 'runtime',
    deleted_at = NULL
RETURNING flow_id::text;
`,
		plan.TenantID,
		plan.RequestID,
		string(plan.TransactionKind),
		plan.Source.SourceModule,
		plan.Source.SourceDocumentType,
		plan.Source.SourceDocumentID,
		plan.Source.SourceDocumentNo,
		plan.Money.TotalAmount,
		plan.Money.CurrencyCode,
		plan.Money.ExchangeRate,
		plan.IdempotencyKey,
		plan.CorrelationID,
		string(plan.Status),
	).Scan(&flowID); err != nil {
		return "", err
	}

	if strings.TrimSpace(flowID) == "" {
		return "", ErrFlowPersistFailed
	}

	return flowID, nil
}

func insertRuntimeFlowStep(ctx context.Context, tx pgx.Tx, tenantID string, flowID string, step RuntimeFlowStep) error {
	_, err := tx.Exec(ctx, `
INSERT INTO erp_runtime_flow_steps (
    tenant_id,
    flow_id,
    step_no,
    step_kind,
    step_status,
    message,
    started_at,
    completed_at,
    created_by,
    updated_by
) VALUES (
    $1, $2, $3, $4, $5, NULLIF($6, ''),
    NULLIF($7::text, '')::timestamptz,
    NULLIF($8::text, '')::timestamptz,
    'runtime',
    'runtime'
);
`,
		tenantID,
		flowID,
		step.StepNo,
		string(step.Kind),
		string(step.Status),
		step.Message,
		nullableTimeString(step.StartedAt),
		nullableTimeString(step.CompletedAt),
	)

	return err
}

func findRuntimeFlowID(ctx context.Context, tx pgx.Tx, tenantID string, idempotencyKey string) (string, error) {
	var flowID string

	if err := tx.QueryRow(ctx, `
SELECT flow_id::text
FROM erp_runtime_flows
WHERE tenant_id = $1
  AND idempotency_key = $2
  AND deleted_at IS NULL
LIMIT 1;
`, tenantID, idempotencyKey).Scan(&flowID); err != nil {
		if errorsIsNoRows(err) {
			return "", ErrFlowNotFound
		}

		return "", err
	}

	if strings.TrimSpace(flowID) == "" {
		return "", ErrFlowNotFound
	}

	return flowID, nil
}

func nullableTimeString(value time.Time) string {
	if value.IsZero() {
		return ""
	}

	return value.UTC().Format(time.RFC3339Nano)
}

func errorsIsNoRows(err error) bool {
	return err == pgx.ErrNoRows
}
