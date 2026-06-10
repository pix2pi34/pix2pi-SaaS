package runtime

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/api"
)

func TestRoutes(t *testing.T) {
	t.Parallel()

	routes := Routes()

	if len(routes) != 6 {
		t.Fatalf("expected 6 routes, got %d", len(routes))
	}

	expected := map[string]bool{
		api.PathOperationalSummary:   false,
		api.PathDailyMetrics:         false,
		api.PathInventoryStatus:      false,
		api.PathDocumentWorkQueue:    false,
		api.PathReconciliationStatus: false,
		api.PathProjectionState:      false,
	}

	for _, route := range routes {
		if route.Method != http.MethodGet {
			t.Fatalf("expected GET method, got %s for %s", route.Method, route.Path)
		}

		if route.Auth != "bearer_required" {
			t.Fatalf("expected bearer auth for %s", route.Path)
		}

		if route.Tenant != "x_tenant_id_required" {
			t.Fatalf("expected tenant header for %s", route.Path)
		}

		if _, ok := expected[route.Path]; !ok {
			t.Fatalf("unexpected route path: %s", route.Path)
		}

		expected[route.Path] = true
	}

	for path, found := range expected {
		if !found {
			t.Fatalf("missing route: %s", path)
		}
	}
}

func TestRegisterReportingRoutesNilMux(t *testing.T) {
	t.Parallel()

	err := RegisterReportingRoutes(nil)

	if !errors.Is(err, ErrNilMux) {
		t.Fatalf("expected ErrNilMux, got %v", err)
	}
}

func TestRegisterReportingRoutes(t *testing.T) {
	t.Parallel()

	mux := http.NewServeMux()

	if err := RegisterReportingRoutes(mux); err != nil {
		t.Fatalf("unexpected register error: %v", err)
	}

	for _, route := range Routes() {
		route := route

		t.Run(route.Path, func(t *testing.T) {
			req := httptest.NewRequest(route.Method, route.Path, nil)
			req.Header.Set("Authorization", "Bearer test-token")
			req.Header.Set("X-Tenant-ID", "tenant_7")
			req.Header.Set("X-Request-ID", "req_test")

			rr := httptest.NewRecorder()
			mux.ServeHTTP(rr, req)

			if rr.Code != http.StatusOK {
				t.Fatalf("expected 200, got %d body=%s", rr.Code, rr.Body.String())
			}

			body := rr.Body.String()

			if strings.Contains(body, "SELECT ") || strings.Contains(body, "WHERE tenant_id") {
				t.Fatalf("response leaked query text: %s", body)
			}

			var envelope api.SuccessEnvelope
			if err := json.Unmarshal(rr.Body.Bytes(), &envelope); err != nil {
				t.Fatalf("decode success envelope: %v", err)
			}

			if envelope.Status != "ok" {
				t.Fatalf("expected status ok, got %s", envelope.Status)
			}

			if envelope.TenantID != "tenant_7" {
				t.Fatalf("expected tenant_7, got %s", envelope.TenantID)
			}

			if !envelope.Data.ReadOnly {
				t.Fatalf("expected readonly query data")
			}
		})
	}
}

func TestRegisterReportingRoutesAuthGate(t *testing.T) {
	t.Parallel()

	mux := http.NewServeMux()

	if err := RegisterReportingRoutes(mux); err != nil {
		t.Fatalf("unexpected register error: %v", err)
	}

	req := httptest.NewRequest(http.MethodGet, api.PathOperationalSummary, nil)
	req.Header.Set("X-Tenant-ID", "tenant_7")

	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)

	if rr.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d body=%s", rr.Code, rr.Body.String())
	}

	if !strings.Contains(rr.Body.String(), api.ErrorCodeAuthRequired) {
		t.Fatalf("expected auth error, got %s", rr.Body.String())
	}
}

func TestRegisterReportingRoutesTenantGate(t *testing.T) {
	t.Parallel()

	mux := http.NewServeMux()

	if err := RegisterReportingRoutes(mux); err != nil {
		t.Fatalf("unexpected register error: %v", err)
	}

	req := httptest.NewRequest(http.MethodGet, api.PathOperationalSummary, nil)
	req.Header.Set("Authorization", "Bearer test-token")

	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)

	if rr.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d body=%s", rr.Code, rr.Body.String())
	}

	if !strings.Contains(rr.Body.String(), api.ErrorCodeTenantHeaderRequired) {
		t.Fatalf("expected tenant header error, got %s", rr.Body.String())
	}
}
