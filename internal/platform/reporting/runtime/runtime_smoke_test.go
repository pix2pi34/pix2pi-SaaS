package runtime

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/api"
)


func reportingSmokeEndpointPaths() []string {
	return []string{
		api.PathOperationalSummary,
		api.PathDailyMetrics,
		api.PathInventoryStatus,
		api.PathDocumentWorkQueue,
		api.PathReconciliationStatus,
		api.PathProjectionState,
	}
}

func TestReportingRuntimeSmoke_AllEndpoints(t *testing.T) {
	t.Parallel()

	mux := http.NewServeMux()
	if err := RegisterReportingRoutes(mux); err != nil {
		t.Fatalf("register reporting routes: %v", err)
	}

	for _, route := range Routes() {
		route := route

		t.Run(route.Path, func(t *testing.T) {
			t.Parallel()

			req := httptest.NewRequest(route.Method, route.Path, nil)
			req.Header.Set("Authorization", "Bearer smoke-token")
			req.Header.Set("X-Tenant-ID", "tenant_smoke_17_4")
			req.Header.Set("X-Request-ID", "req_smoke_17_4")

			rr := httptest.NewRecorder()
			mux.ServeHTTP(rr, req)

			if rr.Code != http.StatusOK {
				t.Fatalf("expected 200, got %d body=%s", rr.Code, rr.Body.String())
			}

			body := rr.Body.String()

			assertNoQueryTextLeak(t, body)

			var envelope api.SuccessEnvelope
			if err := json.Unmarshal(rr.Body.Bytes(), &envelope); err != nil {
				t.Fatalf("decode success envelope: %v body=%s", err, body)
			}

			if envelope.Status != "ok" {
				t.Fatalf("expected status ok, got %s", envelope.Status)
			}

			if envelope.TenantID != "tenant_smoke_17_4" {
				t.Fatalf("expected tenant_smoke_17_4, got %s", envelope.TenantID)
			}

			if envelope.RequestID != "req_smoke_17_4" {
				t.Fatalf("expected req_smoke_17_4, got %s", envelope.RequestID)
			}

			if !envelope.Data.ReadOnly {
				t.Fatalf("expected read_only true")
			}

			if envelope.Data.QueryName == "" {
				t.Fatalf("expected query_name")
			}

			if envelope.Data.SourceTable == "" {
				t.Fatalf("expected source_table")
			}
		})
	}
}

func TestReportingRuntimeSmoke_AuthTenantAndMethodGates(t *testing.T) {
	t.Parallel()

	mux := http.NewServeMux()
	if err := RegisterReportingRoutes(mux); err != nil {
		t.Fatalf("register reporting routes: %v", err)
	}

	tests := []struct {
		name       string
		method     string
		path       string
		authHeader string
		tenantID   string
		claimID    string
		wantStatus int
		wantCode   string
	}{
		{
			name:       "missing bearer",
			method:     http.MethodGet,
			path:       api.PathOperationalSummary,
			authHeader: "",
			tenantID:   "tenant_smoke_17_4",
			wantStatus: http.StatusUnauthorized,
			wantCode:   api.ErrorCodeAuthRequired,
		},
		{
			name:       "missing tenant header",
			method:     http.MethodGet,
			path:       api.PathOperationalSummary,
			authHeader: "Bearer smoke-token",
			tenantID:   "",
			wantStatus: http.StatusBadRequest,
			wantCode:   api.ErrorCodeTenantHeaderRequired,
		},
		{
			name:       "tenant mismatch",
			method:     http.MethodGet,
			path:       api.PathOperationalSummary,
			authHeader: "Bearer smoke-token",
			tenantID:   "tenant_smoke_17_4",
			claimID:    "tenant_other",
			wantStatus: http.StatusForbidden,
			wantCode:   api.ErrorCodeTenantMismatch,
		},
		{
			name:       "method not allowed",
			method:     http.MethodPost,
			path:       api.PathOperationalSummary,
			authHeader: "Bearer smoke-token",
			tenantID:   "tenant_smoke_17_4",
			wantStatus: http.StatusMethodNotAllowed,
			wantCode:   api.ErrorCodeMethodNotAllowed,
		},
	}

	for _, tt := range tests {
		tt := tt

		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			req := httptest.NewRequest(tt.method, tt.path, nil)
			req.Header.Set("X-Request-ID", "req_gate_17_4")

			if tt.authHeader != "" {
				req.Header.Set("Authorization", tt.authHeader)
			}

			if tt.tenantID != "" {
				req.Header.Set("X-Tenant-ID", tt.tenantID)
			}

			if tt.claimID != "" {
				req = req.WithContext(api.WithTenantClaim(req.Context(), tt.claimID))
			}

			rr := httptest.NewRecorder()
			mux.ServeHTTP(rr, req)

			if rr.Code != tt.wantStatus {
				t.Fatalf("expected status %d, got %d body=%s", tt.wantStatus, rr.Code, rr.Body.String())
			}

			body := rr.Body.String()

			assertNoQueryTextLeak(t, body)

			var envelope api.ErrorEnvelope
			if err := json.Unmarshal(rr.Body.Bytes(), &envelope); err != nil {
				t.Fatalf("decode error envelope: %v body=%s", err, body)
			}

			if envelope.Status != "error" {
				t.Fatalf("expected status error, got %s", envelope.Status)
			}

			if envelope.Error.Code != tt.wantCode {
				t.Fatalf("expected error code %s, got %s", tt.wantCode, envelope.Error.Code)
			}
		})
	}
}

func TestReportingRuntimeSmoke_RoutesAreReadOnlyGET(t *testing.T) {
	t.Parallel()

	for _, route := range Routes() {
		if route.Method != http.MethodGet {
			t.Fatalf("expected GET route, got %s for %s", route.Method, route.Path)
		}

		if route.Auth != "bearer_required" {
			t.Fatalf("expected bearer_required for %s", route.Path)
		}

		if route.Tenant != "x_tenant_id_required" {
			t.Fatalf("expected x_tenant_id_required for %s", route.Path)
		}
	}
}

func assertNoQueryTextLeak(t *testing.T, body string) {
	t.Helper()

	leaks := []string{
		"SELECT ",
		" WHERE ",
		"WHERE tenant_id",
		" FROM readmodel",
		"INSERT ",
		"UPDATE ",
		"DELETE ",
		"DROP ",
		"ALTER ",
	}

	upperBody := strings.ToUpper(body)

	for _, leak := range leaks {
		if strings.Contains(upperBody, strings.ToUpper(leak)) {
			t.Fatalf("response leaked query text token %q in body=%s", leak, body)
		}
	}
}
