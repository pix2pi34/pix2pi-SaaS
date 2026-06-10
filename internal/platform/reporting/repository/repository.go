package repository

import (
	"errors"
	"fmt"
	"strings"
	"time"
)

var (
	ErrTenantRequired = errors.New("tenant_id is required")
	ErrInvalidTenant  = errors.New("tenant_id is invalid")
	ErrInvalidLimit   = errors.New("limit is invalid")
	ErrInvalidDate    = errors.New("date must be YYYY-MM-DD")
)

// Repository builds read-only query specs for reporting readmodels.
type Repository struct{}

// New returns a readmodel repository query builder.
func New() Repository {
	return Repository{}
}

// NormalizePage applies reporting pagination defaults and limits.
func NormalizePage(page PageRequest) (PageRequest, error) {
	if page.Limit == 0 {
		page.Limit = DefaultLimit
	}

	if page.Limit < 0 || page.Limit > MaxLimit {
		return page, ErrInvalidLimit
	}

	page.Cursor = strings.TrimSpace(page.Cursor)
	return page, nil
}

// ValidateTenantID enforces tenant scoped repository calls.
func ValidateTenantID(tenantID string) error {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return ErrTenantRequired
	}

	if strings.ContainsAny(tenantID, " \t\r\n") {
		return ErrInvalidTenant
	}

	return nil
}

// OperationalSummary builds a tenant scoped summary query.
func (r Repository) OperationalSummary(tenantID string) (QuerySpec, error) {
	if err := ValidateTenantID(tenantID); err != nil {
		return QuerySpec{}, err
	}

	sql := strings.Join([]string{
		"SELECT tenant_id, legal_entity_count, branch_count, active_user_count,",
		"customer_count, vendor_count, product_count, open_sales_document_count,",
		"open_purchase_document_count, stock_alert_count, pending_document_count,",
		"pending_payment_count, last_event_time, refreshed_at",
		"FROM readmodel.tenant_operational_snapshot",
		"WHERE tenant_id = $1",
		"LIMIT 1",
	}, " ")

	return QuerySpec{
		Name:        "operational_summary",
		SourceTable: "readmodel.tenant_operational_snapshot",
		SQL:         sql,
		Args:        []any{tenantID},
		Limit:       1,
		ReadOnly:    true,
	}, nil
}

// DailyMetrics builds a tenant scoped daily metrics query.
func (r Repository) DailyMetrics(filter DailyMetricsFilter) (QuerySpec, error) {
	if err := ValidateTenantID(filter.TenantID); err != nil {
		return QuerySpec{}, err
	}

	page, err := NormalizePage(filter.Page)
	if err != nil {
		return QuerySpec{}, err
	}

	if err := validateDate(filter.FromDate); err != nil {
		return QuerySpec{}, err
	}

	if err := validateDate(filter.ToDate); err != nil {
		return QuerySpec{}, err
	}

	args := []any{filter.TenantID}
	where := []string{"tenant_id = $1"}

	addCondition(&where, &args, "metric_date >= %s", filter.FromDate)
	addCondition(&where, &args, "metric_date <= %s", filter.ToDate)
	addCondition(&where, &args, "metric_date::text > %s", page.Cursor)

	return buildQuery(
		"daily_metrics",
		"readmodel.daily_operational_metrics",
		"tenant_id, metric_date, sales_document_count, sales_total, purchase_document_count, purchase_total, payment_in_total, payment_out_total, stock_movement_count, journal_count, error_count, refreshed_at",
		where,
		args,
		"metric_date ASC",
		page.Limit,
	), nil
}

// InventoryStatus builds a tenant scoped inventory status query.
func (r Repository) InventoryStatus(filter InventoryStatusFilter) (QuerySpec, error) {
	if err := ValidateTenantID(filter.TenantID); err != nil {
		return QuerySpec{}, err
	}

	page, err := NormalizePage(filter.Page)
	if err != nil {
		return QuerySpec{}, err
	}

	args := []any{filter.TenantID}
	where := []string{"tenant_id = $1"}

	addCondition(&where, &args, "warehouse_id = %s", filter.WarehouseID)
	addCondition(&where, &args, "sku = %s", filter.SKU)
	addCondition(&where, &args, "item_id > %s", page.Cursor)

	if filter.AlertOnly != nil && *filter.AlertOnly {
		where = append(where, "(negative_stock_flag = true OR below_min_stock_flag = true)")
	}

	return buildQuery(
		"inventory_status",
		"readmodel.inventory_status_snapshot",
		"tenant_id, item_id, warehouse_id, sku, item_name, on_hand_qty, reserved_qty, available_qty, min_stock_qty, negative_stock_flag, below_min_stock_flag, last_movement_at, refreshed_at",
		where,
		args,
		"item_id ASC, warehouse_id ASC",
		page.Limit,
	), nil
}

// DocumentWorkQueue builds a tenant scoped document work queue query.
func (r Repository) DocumentWorkQueue(filter DocumentWorkQueueFilter) (QuerySpec, error) {
	if err := ValidateTenantID(filter.TenantID); err != nil {
		return QuerySpec{}, err
	}

	page, err := NormalizePage(filter.Page)
	if err != nil {
		return QuerySpec{}, err
	}

	args := []any{filter.TenantID}
	where := []string{"tenant_id = $1"}

	addCondition(&where, &args, "document_type = %s", filter.DocumentType)
	addCondition(&where, &args, "source_module = %s", filter.SourceModule)
	addCondition(&where, &args, "status = %s", filter.Status)
	addCondition(&where, &args, "document_id > %s", page.Cursor)

	if filter.PriorityLTE != nil {
		addConditionValue(&where, &args, "priority <= %s", *filter.PriorityLTE)
	}

	return buildQuery(
		"document_work_queue",
		"readmodel.document_work_queue",
		"tenant_id, document_type, document_id, source_module, status, priority, due_at, retry_count, last_event_id, created_at, updated_at",
		where,
		args,
		"priority ASC, updated_at DESC, document_id ASC",
		page.Limit,
	), nil
}

// ReconciliationStatus builds a tenant scoped reconciliation status query.
func (r Repository) ReconciliationStatus(filter ReconciliationStatusFilter) (QuerySpec, error) {
	if err := ValidateTenantID(filter.TenantID); err != nil {
		return QuerySpec{}, err
	}

	page, err := NormalizePage(filter.Page)
	if err != nil {
		return QuerySpec{}, err
	}

	args := []any{filter.TenantID}
	where := []string{"tenant_id = $1"}

	addCondition(&where, &args, "scope_type = %s", filter.ScopeType)
	addCondition(&where, &args, "status = %s", filter.Status)
	addCondition(&where, &args, "currency_code = %s", filter.CurrencyCode)
	addCondition(&where, &args, "scope_id > %s", page.Cursor)

	return buildQuery(
		"reconciliation_status",
		"readmodel.reconciliation_status_snapshot",
		"tenant_id, scope_type, scope_id, status, unreconciled_count, difference_amount, currency_code, last_reconciled_at, refreshed_at",
		where,
		args,
		"scope_type ASC, scope_id ASC",
		page.Limit,
	), nil
}

// ProjectionState builds a tenant scoped projection state query.
func (r Repository) ProjectionState(filter ProjectionStateFilter) (QuerySpec, error) {
	if err := ValidateTenantID(filter.TenantID); err != nil {
		return QuerySpec{}, err
	}

	page, err := NormalizePage(filter.Page)
	if err != nil {
		return QuerySpec{}, err
	}

	args := []any{filter.TenantID}
	where := []string{"tenant_id = $1"}

	addCondition(&where, &args, "projection_name = %s", filter.ProjectionName)
	addCondition(&where, &args, "status = %s", filter.Status)
	addCondition(&where, &args, "projection_name > %s", page.Cursor)

	return buildQuery(
		"projection_state",
		"readmodel.projection_state",
		"tenant_id, projection_name, projection_version, source_stream, last_event_id, last_event_time, last_sequence, status, error_count, updated_at",
		where,
		args,
		"projection_name ASC",
		page.Limit,
	), nil
}

func validateDate(value string) error {
	value = strings.TrimSpace(value)
	if value == "" {
		return nil
	}

	if _, err := time.Parse("2006-01-02", value); err != nil {
		return fmt.Errorf("%w: %s", ErrInvalidDate, value)
	}

	return nil
}

func addCondition(where *[]string, args *[]any, template string, value string) {
	value = strings.TrimSpace(value)
	if value == "" {
		return
	}

	addConditionValue(where, args, template, value)
}

func addConditionValue(where *[]string, args *[]any, template string, value any) {
	*args = append(*args, value)
	placeholder := fmt.Sprintf("$%d", len(*args))
	*where = append(*where, fmt.Sprintf(template, placeholder))
}

func buildQuery(name string, sourceTable string, columns string, where []string, args []any, orderBy string, limit int) QuerySpec {
	args = append(args, limit)
	limitPlaceholder := fmt.Sprintf("$%d", len(args))

	sql := fmt.Sprintf(
		"SELECT %s FROM %s WHERE %s ORDER BY %s LIMIT %s",
		columns,
		sourceTable,
		strings.Join(where, " AND "),
		orderBy,
		limitPlaceholder,
	)

	return QuerySpec{
		Name:        name,
		SourceTable: sourceTable,
		SQL:         sql,
		Args:        args,
		Limit:       limit,
		ReadOnly:    true,
	}
}
