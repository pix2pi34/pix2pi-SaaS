package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/apisurface"
)

func TestRegisterERPRuntimeUnavailableProtectedRoute(t *testing.T) {
	mux := http.NewServeMux()

	err := registerERPRuntimeUnavailableProtectedRoute(mux, errERPRuntimeGatewayDSNRequired)
	if err != nil {
		t.Fatalf("expected unavailable route register success, got %v", err)
	}

	req := httptest.NewRequest(http.MethodPost, apisurface.RuntimeFlowAPIPath, nil)
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("expected HTTP 503, got %d body=%s", rec.Code, rec.Body.String())
	}

	if !strings.Contains(rec.Body.String(), "erp_runtime_service_unavailable") {
		t.Fatalf("expected erp_runtime_service_unavailable body, got %s", rec.Body.String())
	}
}

func TestRegisterERPRuntimeUnavailableProtectedRouteNilMux(t *testing.T) {
	err := registerERPRuntimeUnavailableProtectedRoute(nil, errERPRuntimeGatewayDSNRequired)
	if err != apisurface.ErrRouteRegistrarRequired {
		t.Fatalf("expected ErrRouteRegistrarRequired, got %v", err)
	}
}

func TestAPIGatewayMainContainsERPRuntimeLiveMountWiring(t *testing.T) {
	content, err := os.ReadFile("api_gateway_main.go")
	if err != nil {
		t.Fatalf("read api_gateway_main.go: %v", err)
	}

	required := []string{
		"newERPRuntimeGatewayAPIServiceBundleFromEnv(context.Background())",
		"registerERPRuntimeProtectedRoutes(protectedMux, erpRuntimeBundle.service)",
		"registerERPRuntimeUnavailableProtectedRoute(protectedMux, erpRuntimeErr)",
		"ERP Runtime protected route mounted",
	}

	for _, token := range required {
		if !strings.Contains(string(content), token) {
			t.Fatalf("expected api_gateway_main.go to contain %q", token)
		}
	}
}
