package repository

import (
	"errors"
	"strings"
	"testing"
)

func TestValidateTenantID(t *testing.T) {
	t.Parallel()

	if err := ValidateTenantID("tenant_7"); err != nil {
		t.Fatalf("expected valid tenant, got %v", err)
	}

	if err := ValidateTenantID(""); !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}

	if err := ValidateTenantID("tenant 7"); !errors.Is(err, ErrInvalidTenant) {
		t.Fatalf("expected ErrInvalidTenant, got %v", err)
	}
}

func TestNormalizePage(t *testing.T) {
	t.Parallel()

	page, err := NormalizePage(PageRequest{})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if page.Limit != DefaultLimit {
		t.Fatalf("expected default limit %d, got %d", DefaultLimit, page.Limit)
	}

	page, err = NormalizePage(PageRequest{Limit: MaxLimit})
	if err != nil {
		t.Fatalf("unexpected max limit error: %v", err)
	}

	if page.Limit != MaxLimit {
		t.Fatalf("expected max limit %d, got %d", MaxLimit, page.Limit)
	}

	if _, err := NormalizePage(PageRequest{Limit: MaxLimit + 1}); !errors.Is(err, ErrInvalidLimit) {
		t.Fatalf("expected ErrInvalidLimit, got %v", err)
	}
}

func TestOperationalSummary(t *testing.T) {
	t.Parallel()

	spec, err := New().OperationalSummary("tenant_7")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	assertReadOnlySpec(t, spec)
	assertContains(t, spec.SQL, "readmodel.tenant_operational_snapshot")
	assertContains(t, spec.SQL, "tenant_id = $1")

	if len(spec.Args) != 1 || spec.Args[0] != "tenant_7" {
		t.Fatalf("unexpected args: %#v", spec.Args)
	}

	if spec.Limit != 1 {
		t.Fatalf("expected limit 1, got %d", spec.Limit)
	}
}

func TestDailyMetrics(t *testing.T) {
	t.Parallel()

	spec, err := New().DailyMetrics(DailyMetricsFilter{
		TenantID: "tenant_7",
		FromDate: "2026-04-01",
		ToDate: "2026-04-30",
		Page: PageRequest{Limit: 25, Cursor: "2026-04-10"},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	assertReadOnlySpec(t, spec)
	assertContains(t, spec.SQL, "readmodel.daily_operational_metrics")
	assertContains(t, spec.SQL, "tenant_id = $1")
	assertContains(t, spec.SQL, "metric_date >= $2")
	assertContains(t, spec.SQL, "metric_date <= $3")
	assertContains(t, spec.SQL, "metric_date::text > $4")
	assertContains(t, spec.SQL, "LIMIT $5")

	if spec.Limit != 25 {
		t.Fatalf("expected limit 25, got %d", spec.Limit)
	}
}

func TestDailyMetricsInvalidDate(t *testing.T) {
	t.Parallel()

	_, err := New().DailyMetrics(DailyMetricsFilter{
		TenantID: "tenant_7",
		FromDate: "27-04-2026",
	})

	if !errors.Is(err, ErrInvalidDate) {
		t.Fatalf("expected ErrInvalidDate, got %v", err)
	}
}

func TestInventoryStatusAlertOnly(t *testing.T) {
	t.Parallel()

	alertOnly := true

	spec, err := New().InventoryStatus(InventoryStatusFilter{
		TenantID: "tenant_7",
		WarehouseID: "main",
		SKU: "SKU-1",
		AlertOnly: &alertOnly,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	assertReadOnlySpec(t, spec)
	assertContains(t, spec.SQL, "readmodel.inventory_status_snapshot")
	assertContains(t, spec.SQL, "warehouse_id = $2")
	assertContains(t, spec.SQL, "sku = $3")
	assertContains(t, spec.SQL, "negative_stock_flag = true OR below_min_stock_flag = true")
}

func TestDocumentWorkQueue(t *testing.T) {
	t.Parallel()

	priority := 50

	spec, err := New().DocumentWorkQueue(DocumentWorkQueueFilter{
		TenantID: "tenant_7",
		DocumentType: "invoice",
		SourceModule: "sales",
		Status: "pending",
		PriorityLTE: &priority,
		Page: PageRequest{Limit: 10},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	assertReadOnlySpec(t, spec)
	assertContains(t, spec.SQL, "readmodel.document_work_queue")
	assertContains(t, spec.SQL, "document_type = $2")
	assertContains(t, spec.SQL, "source_module = $3")
	assertContains(t, spec.SQL, "status = $4")
	assertContains(t, spec.SQL, "priority <= $5")
}

func TestReconciliationStatus(t *testing.T) {
	t.Parallel()

	spec, err := New().ReconciliationStatus(ReconciliationStatusFilter{
		TenantID: "tenant_7",
		ScopeType: "bank",
		Status: "open",
		CurrencyCode: "TRY",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	assertReadOnlySpec(t, spec)
	assertContains(t, spec.SQL, "readmodel.reconciliation_status_snapshot")
	assertContains(t, spec.SQL, "scope_type = $2")
	assertContains(t, spec.SQL, "status = $3")
	assertContains(t, spec.SQL, "currency_code = $4")
}

func TestProjectionState(t *testing.T) {
	t.Parallel()

	spec, err := New().ProjectionState(ProjectionStateFilter{
		TenantID: "tenant_7",
		ProjectionName: "inventory_projection",
		Status: "idle",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	assertReadOnlySpec(t, spec)
	assertContains(t, spec.SQL, "readmodel.projection_state")
	assertContains(t, spec.SQL, "projection_name = $2")
	assertContains(t, spec.SQL, "status = $3")
}

func TestRepositoryMethodsRequireTenant(t *testing.T) {
	t.Parallel()

	repo := New()

	tests := []struct {
		name string
		run  func() error
	}{
		{"OperationalSummary", func() error { _, err := repo.OperationalSummary(""); return err }},
		{"DailyMetrics", func() error { _, err := repo.DailyMetrics(DailyMetricsFilter{}); return err }},
		{"InventoryStatus", func() error { _, err := repo.InventoryStatus(InventoryStatusFilter{}); return err }},
		{"DocumentWorkQueue", func() error { _, err := repo.DocumentWorkQueue(DocumentWorkQueueFilter{}); return err }},
		{"ReconciliationStatus", func() error { _, err := repo.ReconciliationStatus(ReconciliationStatusFilter{}); return err }},
		{"ProjectionState", func() error { _, err := repo.ProjectionState(ProjectionStateFilter{}); return err }},
	}

	for _, tt := range tests {
		tt := tt

		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			if err := tt.run(); !errors.Is(err, ErrTenantRequired) {
				t.Fatalf("expected ErrTenantRequired, got %v", err)
			}
		})
	}
}

func TestNoMutationSQL(t *testing.T) {
	t.Parallel()

	alertOnly := true
	priority := 50
	repo := New()

	specs := []QuerySpec{}

	summary, err := repo.OperationalSummary("tenant_7")
	if err != nil {
		t.Fatalf("summary: %v", err)
	}
	specs = append(specs, summary)

	daily, err := repo.DailyMetrics(DailyMetricsFilter{TenantID: "tenant_7"})
	if err != nil {
		t.Fatalf("daily: %v", err)
	}
	specs = append(specs, daily)

	inventory, err := repo.InventoryStatus(InventoryStatusFilter{TenantID: "tenant_7", AlertOnly: &alertOnly})
	if err != nil {
		t.Fatalf("inventory: %v", err)
	}
	specs = append(specs, inventory)

	documents, err := repo.DocumentWorkQueue(DocumentWorkQueueFilter{TenantID: "tenant_7", PriorityLTE: &priority})
	if err != nil {
		t.Fatalf("documents: %v", err)
	}
	specs = append(specs, documents)

	reconciliation, err := repo.ReconciliationStatus(ReconciliationStatusFilter{TenantID: "tenant_7"})
	if err != nil {
		t.Fatalf("reconciliation: %v", err)
	}
	specs = append(specs, reconciliation)

	projection, err := repo.ProjectionState(ProjectionStateFilter{TenantID: "tenant_7"})
	if err != nil {
		t.Fatalf("projection: %v", err)
	}
	specs = append(specs, projection)

	for _, spec := range specs {
		assertReadOnlySpec(t, spec)
	}
}

func assertReadOnlySpec(t *testing.T, spec QuerySpec) {
	t.Helper()

	if !spec.ReadOnly {
		t.Fatalf("expected read only spec: %#v", spec)
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
		t.Fatalf("query must start with SELECT, got: %s", spec.SQL)
	}
}

func assertContains(t *testing.T, value string, expected string) {
	t.Helper()

	if !strings.Contains(value, expected) {
		t.Fatalf("expected %q to contain %q", value, expected)
	}
}
