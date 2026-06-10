package api

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/repository"
	reportingservice "github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/service"
)

type fakeReportingService struct {
	lastMethod string
	lastTenant string
	lastLimit  int
	err       error
}

func (f *fakeReportingService) OperationalSummary(ctx context.Context, req reportingservice.OperationalSummaryRequest) (reportingservice.QueryResponse, error) {
	f.lastMethod = "OperationalSummary"
	f.lastTenant = req.TenantID

	if f.err != nil {
		return reportingservice.QueryResponse{}, f.err
	}

	return fakeResponse(req.TenantID, "operational_summary", "readmodel.tenant_operational_snapshot", 1), nil
}

func (f *fakeReportingService) DailyMetrics(ctx context.Context, req reportingservice.DailyMetricsRequest) (reportingservice.QueryResponse, error) {
	f.lastMethod = "DailyMetrics"
	f.lastTenant = req.TenantID
	f.lastLimit = req.Page.Limit

	if f.err != nil {
		return reportingservice.QueryResponse{}, f.err
	}

	return fakeResponse(req.TenantID, "daily_metrics", "readmodel.daily_operational_metrics", req.Page.Limit), nil
}

func (f *fakeReportingService) InventoryStatus(ctx context.Context, req reportingservice.InventoryStatusRequest) (reportingservice.QueryResponse, error) {
	f.lastMethod = "InventoryStatus"
	f.lastTenant = req.TenantID
	f.lastLimit = req.Page.Limit

	if f.err != nil {
		return reportingservice.QueryResponse{}, f.err
	}

	return fakeResponse(req.TenantID, "inventory_status", "readmodel.inventory_status_snapshot", req.Page.Limit), nil
}

func (f *fakeReportingService) DocumentWorkQueue(ctx context.Context, req reportingservice.DocumentWorkQueueRequest) (reportingservice.QueryResponse, error) {
	f.lastMethod = "DocumentWorkQueue"
	f.lastTenant = req.TenantID
	f.lastLimit = req.Page.Limit

	if f.err != nil {
		return reportingservice.QueryResponse{}, f.err
	}

	return fakeResponse(req.TenantID, "document_work_queue", "readmodel.document_work_queue", req.Page.Limit), nil
}

func (f *fakeReportingService) ReconciliationStatus(ctx context.Context, req reportingservice.ReconciliationStatusRequest) (reportingservice.QueryResponse, error) {
	f.lastMethod = "ReconciliationStatus"
	f.lastTenant = req.TenantID
	f.lastLimit = req.Page.Limit

	if f.err != nil {
		return reportingservice.QueryResponse{}, f.err
	}

	return fakeResponse(req.TenantID, "reconciliation_status", "readmodel.reconciliation_status_snapshot", req.Page.Limit), nil
}

func (f *fakeReportingService) ProjectionState(ctx context.Context, req reportingservice.ProjectionStateRequest) (reportingservice.QueryResponse, error) {
	f.lastMethod = "ProjectionState"
	f.lastTenant = req.TenantID
	f.lastLimit = req.Page.Limit

	if f.err != nil {
		return reportingservice.QueryResponse{}, f.err
	}

	return fakeResponse(req.TenantID, "projection_state", "readmodel.projection_state", req.Page.Limit), nil
}

func fakeResponse(tenantID string, name string, sourceTable string, limit int) reportingservice.QueryResponse {
	if limit == 0 {
		limit = repository.DefaultLimit
	}

	return reportingservice.QueryResponse{
		TenantID: tenantID,
		Query: repository.QuerySpec{
			Name:        name,
			SourceTable: sourceTable,
			SQL:         "SELECT * FROM " + sourceTable + " WHERE tenant_id = $1",
			Args:        []any{tenantID},
			Limit:       limit,
			ReadOnly:    true,
		},
		Meta: reportingservice.PageMeta{
			Limit:      limit,
			NextCursor: "",
			HasMore:    false,
		},
	}
}

func TestAllReportingEndpointsRoute(t *testing.T) {
	paths := []string{
		PathOperationalSummary,
		PathDailyMetrics,
		PathInventoryStatus,
		PathDocumentWorkQueue,
		PathReconciliationStatus,
		PathProjectionState,
	}

	for _, path := range paths {
		path := path

		t.Run(path, func(t *testing.T) {
			service := &fakeReportingService{}
			handler := NewHandler(service)

			req := newRequest(http.MethodGet, path)
			rr := httptest.NewRecorder()

			handler.ServeHTTP(rr, req)

			if rr.Code != http.StatusOK {
				t.Fatalf("expected 200, got %d body=%s", rr.Code, rr.Body.String())
			}

			body := rr.Body.String()
			if strings.Contains(body, "SELECT ") || strings.Contains(body, "WHERE tenant_id") {
				t.Fatalf("response leaked query text: %s", body)
			}

			assertContains(t, body, `"status":"ok"`)
			assertContains(t, body, `"tenant_id":"tenant_7"`)
			assertContains(t, body, `"read_only":true`)
		})
	}
}

func TestRegisterAttachesRoutes(t *testing.T) {
	service := &fakeReportingService{}
	handler := NewHandler(service)
	mux := http.NewServeMux()

	handler.Register(mux)

	req := newRequest(http.MethodGet, PathProjectionState)
	rr := httptest.NewRecorder()

	mux.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d body=%s", rr.Code, rr.Body.String())
	}

	if service.lastMethod != "ProjectionState" {
		t.Fatalf("expected ProjectionState, got %s", service.lastMethod)
	}
}

func TestMissingBearerToken(t *testing.T) {
	handler := NewHandler(&fakeReportingService{})

	req := httptest.NewRequest(http.MethodGet, PathOperationalSummary, nil)
	req.Header.Set("X-Tenant-ID", "tenant_7")
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	assertErrorCode(t, rr, http.StatusUnauthorized, ErrorCodeAuthRequired)
}

func TestMissingTenantHeader(t *testing.T) {
	handler := NewHandler(&fakeReportingService{})

	req := httptest.NewRequest(http.MethodGet, PathOperationalSummary, nil)
	req.Header.Set("Authorization", "Bearer test-token")
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	assertErrorCode(t, rr, http.StatusBadRequest, ErrorCodeTenantHeaderRequired)
}

func TestTenantClaimMismatch(t *testing.T) {
	handler := NewHandler(&fakeReportingService{})

	req := newRequest(http.MethodGet, PathOperationalSummary)
	req = req.WithContext(WithTenantClaim(req.Context(), "tenant_99"))
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	assertErrorCode(t, rr, http.StatusForbidden, ErrorCodeTenantMismatch)
}

func TestMethodNotAllowed(t *testing.T) {
	handler := NewHandler(&fakeReportingService{})

	req := newRequest(http.MethodPost, PathOperationalSummary)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	assertErrorCode(t, rr, http.StatusMethodNotAllowed, ErrorCodeMethodNotAllowed)
}

func TestInvalidLimitFilter(t *testing.T) {
	handler := NewHandler(&fakeReportingService{})

	req := newRequest(http.MethodGet, PathDailyMetrics+"?limit=abc")
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	assertErrorCode(t, rr, http.StatusBadRequest, ErrorCodeReportingInvalidFilter)
}

func TestDailyMetricsLimitForwarding(t *testing.T) {
	service := &fakeReportingService{}
	handler := NewHandler(service)

	req := newRequest(http.MethodGet, PathDailyMetrics+"?limit=25")
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d body=%s", rr.Code, rr.Body.String())
	}

	if service.lastLimit != 25 {
		t.Fatalf("expected limit 25, got %d", service.lastLimit)
	}

	assertContains(t, rr.Body.String(), `"limit":25`)
}

func TestServiceErrorMapping(t *testing.T) {
	service := &fakeReportingService{
		err: reportingservice.ServiceError{
			Code:    reportingservice.ErrorCodeInvalidLimit,
			Message: "reporting limit exceeded",
			Err:     errors.New("limit"),
		},
	}

	handler := NewHandler(service)

	req := newRequest(http.MethodGet, PathOperationalSummary)
	rr := httptest.NewRecorder()

	handler.ServeHTTP(rr, req)

	assertErrorCode(t, rr, http.StatusBadRequest, ErrorCodeReportingLimitExceeded)
}

func newRequest(method string, target string) *http.Request {
	req := httptest.NewRequest(method, target, nil)
	req.Header.Set("Authorization", "Bearer test-token")
	req.Header.Set("X-Tenant-ID", "tenant_7")
	req.Header.Set("X-Request-ID", "req_test")
	return req
}

func assertErrorCode(t *testing.T, rr *httptest.ResponseRecorder, expectedStatus int, expectedCode string) {
	t.Helper()

	if rr.Code != expectedStatus {
		t.Fatalf("expected status %d, got %d body=%s", expectedStatus, rr.Code, rr.Body.String())
	}

	var envelope ErrorEnvelope
	if err := json.Unmarshal(rr.Body.Bytes(), &envelope); err != nil {
		t.Fatalf("decode error envelope: %v", err)
	}

	if envelope.Status != "error" {
		t.Fatalf("expected status error, got %s", envelope.Status)
	}

	if envelope.Error.Code != expectedCode {
		t.Fatalf("expected error code %s, got %s", expectedCode, envelope.Error.Code)
	}
}

func assertContains(t *testing.T, value string, expected string) {
	t.Helper()

	if !strings.Contains(value, expected) {
		t.Fatalf("expected %q to contain %q", value, expected)
	}
}
