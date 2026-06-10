package service

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/repository"
)

type fakeRepo struct {
	err error
}

func (f fakeRepo) OperationalSummary(tenantID string) (repository.QuerySpec, error) {
	if f.err != nil {
		return repository.QuerySpec{}, f.err
	}

	return spec("operational_summary", "readmodel.tenant_operational_snapshot", tenantID, 1), nil
}

func (f fakeRepo) DailyMetrics(filter repository.DailyMetricsFilter) (repository.QuerySpec, error) {
	if f.err != nil {
		return repository.QuerySpec{}, f.err
	}

	return spec("daily_metrics", "readmodel.daily_operational_metrics", filter.TenantID, filter.Page.Limit), nil
}

func (f fakeRepo) InventoryStatus(filter repository.InventoryStatusFilter) (repository.QuerySpec, error) {
	if f.err != nil {
		return repository.QuerySpec{}, f.err
	}

	return spec("inventory_status", "readmodel.inventory_status_snapshot", filter.TenantID, filter.Page.Limit), nil
}

func (f fakeRepo) DocumentWorkQueue(filter repository.DocumentWorkQueueFilter) (repository.QuerySpec, error) {
	if f.err != nil {
		return repository.QuerySpec{}, f.err
	}

	return spec("document_work_queue", "readmodel.document_work_queue", filter.TenantID, filter.Page.Limit), nil
}

func (f fakeRepo) ReconciliationStatus(filter repository.ReconciliationStatusFilter) (repository.QuerySpec, error) {
	if f.err != nil {
		return repository.QuerySpec{}, f.err
	}

	return spec("reconciliation_status", "readmodel.reconciliation_status_snapshot", filter.TenantID, filter.Page.Limit), nil
}

func (f fakeRepo) ProjectionState(filter repository.ProjectionStateFilter) (repository.QuerySpec, error) {
	if f.err != nil {
		return repository.QuerySpec{}, f.err
	}

	return spec("projection_state", "readmodel.projection_state", filter.TenantID, filter.Page.Limit), nil
}

func spec(name string, table string, tenantID string, limit int) repository.QuerySpec {
	if limit == 0 {
		limit = repository.DefaultLimit
	}

	return repository.QuerySpec{
		Name:        name,
		SourceTable: table,
		SQL:         "SELECT * FROM " + table + " WHERE tenant_id = $1 LIMIT $2",
		Args:        []any{tenantID, limit},
		Limit:       limit,
		ReadOnly:    true,
	}
}

func TestNewUsesDefaultRepositoryWhenNil(t *testing.T) {
	t.Parallel()

	svc := New(nil)

	resp, err := svc.OperationalSummary(context.Background(), OperationalSummaryRequest{TenantID: "tenant_7"})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	assertServiceResponse(t, resp, "tenant_7", "operational_summary")
	assertContains(t, resp.Query.SourceTable, "readmodel.tenant_operational_snapshot")
}

func TestOperationalSummary(t *testing.T) {
	t.Parallel()

	svc := New(fakeRepo{})

	resp, err := svc.OperationalSummary(context.Background(), OperationalSummaryRequest{TenantID: "tenant_7"})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	assertServiceResponse(t, resp, "tenant_7", "operational_summary")

	if resp.Meta.Limit != 1 {
		t.Fatalf("expected limit 1, got %d", resp.Meta.Limit)
	}
}

func TestDailyMetricsDefaultLimit(t *testing.T) {
	t.Parallel()

	svc := New(fakeRepo{})

	resp, err := svc.DailyMetrics(context.Background(), DailyMetricsRequest{
		TenantID: "tenant_7",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	assertServiceResponse(t, resp, "tenant_7", "daily_metrics")

	if resp.Meta.Limit != repository.DefaultLimit {
		t.Fatalf("expected default limit %d, got %d", repository.DefaultLimit, resp.Meta.Limit)
	}
}

func TestDailyMetricsInvalidLimit(t *testing.T) {
	t.Parallel()

	svc := New(fakeRepo{})

	_, err := svc.DailyMetrics(context.Background(), DailyMetricsRequest{
		TenantID: "tenant_7",
		Page: PageRequest{Limit: repository.MaxLimit + 1},
	})
	assertServiceErrorCode(t, err, ErrorCodeInvalidLimit)
}

func TestDailyMetricsInvalidDate(t *testing.T) {
	t.Parallel()

	svc := New(repository.New())

	_, err := svc.DailyMetrics(context.Background(), DailyMetricsRequest{
		TenantID: "tenant_7",
		FromDate: "27-04-2026",
	})
	assertServiceErrorCode(t, err, ErrorCodeInvalidFilter)
}

func TestInventoryStatus(t *testing.T) {
	t.Parallel()

	alertOnly := true
	svc := New(fakeRepo{})

	resp, err := svc.InventoryStatus(context.Background(), InventoryStatusRequest{
		TenantID: "tenant_7",
		WarehouseID: "main",
		SKU: "SKU-1",
		AlertOnly: &alertOnly,
		Page: PageRequest{Limit: 25},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	assertServiceResponse(t, resp, "tenant_7", "inventory_status")

	if resp.Meta.Limit != 25 {
		t.Fatalf("expected limit 25, got %d", resp.Meta.Limit)
	}
}

func TestDocumentWorkQueue(t *testing.T) {
	t.Parallel()

	priority := 50
	svc := New(fakeRepo{})

	resp, err := svc.DocumentWorkQueue(context.Background(), DocumentWorkQueueRequest{
		TenantID: "tenant_7",
		DocumentType: "invoice",
		SourceModule: "sales",
		Status: "pending",
		PriorityLTE: &priority,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	assertServiceResponse(t, resp, "tenant_7", "document_work_queue")
}

func TestReconciliationStatus(t *testing.T) {
	t.Parallel()

	svc := New(fakeRepo{})

	resp, err := svc.ReconciliationStatus(context.Background(), ReconciliationStatusRequest{
		TenantID: "tenant_7",
		ScopeType: "bank",
		Status: "open",
		CurrencyCode: "TRY",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	assertServiceResponse(t, resp, "tenant_7", "reconciliation_status")
}

func TestProjectionState(t *testing.T) {
	t.Parallel()

	svc := New(fakeRepo{})

	resp, err := svc.ProjectionState(context.Background(), ProjectionStateRequest{
		TenantID: "tenant_7",
		ProjectionName: "inventory_projection",
		Status: "idle",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	assertServiceResponse(t, resp, "tenant_7", "projection_state")
}

func TestAllMethodsRequireTenant(t *testing.T) {
	t.Parallel()

	svc := New(fakeRepo{})

	tests := []struct {
		name string
		run  func() error
	}{
		{"OperationalSummary", func() error {
			_, err := svc.OperationalSummary(context.Background(), OperationalSummaryRequest{})
			return err
		}},
		{"DailyMetrics", func() error {
			_, err := svc.DailyMetrics(context.Background(), DailyMetricsRequest{})
			return err
		}},
		{"InventoryStatus", func() error {
			_, err := svc.InventoryStatus(context.Background(), InventoryStatusRequest{})
			return err
		}},
		{"DocumentWorkQueue", func() error {
			_, err := svc.DocumentWorkQueue(context.Background(), DocumentWorkQueueRequest{})
			return err
		}},
		{"ReconciliationStatus", func() error {
			_, err := svc.ReconciliationStatus(context.Background(), ReconciliationStatusRequest{})
			return err
		}},
		{"ProjectionState", func() error {
			_, err := svc.ProjectionState(context.Background(), ProjectionStateRequest{})
			return err
		}},
	}

	for _, tt := range tests {
		tt := tt

		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			assertServiceErrorCode(t, tt.run(), ErrorCodeTenantRequired)
		})
	}
}

func TestMapsRepositoryFailure(t *testing.T) {
	t.Parallel()

	svc := New(fakeRepo{err: errors.New("boom")})

	_, err := svc.OperationalSummary(context.Background(), OperationalSummaryRequest{TenantID: "tenant_7"})
	assertServiceErrorCode(t, err, ErrorCodeRepositoryFailure)
}

func TestServiceProducesReadOnlyQueries(t *testing.T) {
	t.Parallel()

	alertOnly := true
	priority := 50
	svc := New(fakeRepo{})

	responses := []QueryResponse{}

	summary, err := svc.OperationalSummary(context.Background(), OperationalSummaryRequest{TenantID: "tenant_7"})
	if err != nil {
		t.Fatalf("summary: %v", err)
	}
	responses = append(responses, summary)

	daily, err := svc.DailyMetrics(context.Background(), DailyMetricsRequest{TenantID: "tenant_7"})
	if err != nil {
		t.Fatalf("daily: %v", err)
	}
	responses = append(responses, daily)

	inventory, err := svc.InventoryStatus(context.Background(), InventoryStatusRequest{TenantID: "tenant_7", AlertOnly: &alertOnly})
	if err != nil {
		t.Fatalf("inventory: %v", err)
	}
	responses = append(responses, inventory)

	documents, err := svc.DocumentWorkQueue(context.Background(), DocumentWorkQueueRequest{TenantID: "tenant_7", PriorityLTE: &priority})
	if err != nil {
		t.Fatalf("documents: %v", err)
	}
	responses = append(responses, documents)

	reconciliation, err := svc.ReconciliationStatus(context.Background(), ReconciliationStatusRequest{TenantID: "tenant_7"})
	if err != nil {
		t.Fatalf("reconciliation: %v", err)
	}
	responses = append(responses, reconciliation)

	projection, err := svc.ProjectionState(context.Background(), ProjectionStateRequest{TenantID: "tenant_7"})
	if err != nil {
		t.Fatalf("projection: %v", err)
	}
	responses = append(responses, projection)

	for _, resp := range responses {
		assertReadOnlyQuery(t, resp.Query)
	}
}

func assertServiceResponse(t *testing.T, resp QueryResponse, tenantID string, name string) {
	t.Helper()

	if resp.TenantID != tenantID {
		t.Fatalf("expected tenant %q, got %q", tenantID, resp.TenantID)
	}

	if resp.Query.Name != name {
		t.Fatalf("expected query name %q, got %q", name, resp.Query.Name)
	}

	assertReadOnlyQuery(t, resp.Query)
}

func assertReadOnlyQuery(t *testing.T, spec repository.QuerySpec) {
	t.Helper()

	if !spec.ReadOnly {
		t.Fatalf("expected readonly query spec: %#v", spec)
	}

	lower := strings.ToLower(spec.SQL)
	blocked := []string{
		" insert ",
		" update ",
		" delete ",
		" drop ",
		" alter ",
		" create ",
		" truncate ",
	}

	for _, token := range blocked {
		if strings.Contains(" "+lower+" ", token) {
			t.Fatalf("mutation token %q found in SQL: %s", token, spec.SQL)
		}
	}

	if !strings.HasPrefix(lower, "select ") {
		t.Fatalf("query must start with select, got: %s", spec.SQL)
	}
}

func assertServiceErrorCode(t *testing.T, err error, code ErrorCode) {
	t.Helper()

	if err == nil {
		t.Fatalf("expected error code %s, got nil", code)
	}

	var svcErr ServiceError
	if !errors.As(err, &svcErr) {
		t.Fatalf("expected ServiceError, got %T: %v", err, err)
	}

	if svcErr.Code != code {
		t.Fatalf("expected code %s, got %s", code, svcErr.Code)
	}
}

func assertContains(t *testing.T, value string, expected string) {
	t.Helper()

	if !strings.Contains(value, expected) {
		t.Fatalf("expected %q to contain %q", value, expected)
	}
}
