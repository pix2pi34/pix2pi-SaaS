package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/apisurface"
)

func TestERPRuntimeGatewayRouteRuleContract(t *testing.T) {
	rule := erpRuntimeGatewayRouteRule()

	if rule.Name != apisurface.RuntimeFlowAPIRouteName {
		t.Fatalf("expected route name %s, got %s", apisurface.RuntimeFlowAPIRouteName, rule.Name)
	}

	if rule.Path != apisurface.RuntimeFlowAPIPath {
		t.Fatalf("expected route path %s, got %s", apisurface.RuntimeFlowAPIPath, rule.Path)
	}

	if rule.Scope != routeScopeProtected {
		t.Fatalf("expected protected scope, got %s", rule.Scope)
	}

	if len(rule.Methods) != 1 || rule.Methods[0] != http.MethodPost {
		t.Fatalf("expected POST method, got %#v", rule.Methods)
	}

	if rule.Prefix {
		t.Fatal("expected exact route, prefix=false")
	}

	if !rule.AuthRequired {
		t.Fatal("expected auth required")
	}

	if !rule.TenantRequired {
		t.Fatal("expected tenant required")
	}
}

func TestAppendERPRuntimeGatewayRouteRuleAddsOnce(t *testing.T) {
	baseRules := []routeRule{
		{
			Name:           "existing",
			Path:           "/api/existing",
			Scope:          routeScopeProtected,
			Methods:        []string{http.MethodGet},
			Prefix:         false,
			AuthRequired:   true,
			TenantRequired: true,
			Description:    "existing route",
		},
	}

	withERP := appendERPRuntimeGatewayRouteRule(baseRules)

	if len(withERP) != 2 {
		t.Fatalf("expected 2 routes after append, got %d", len(withERP))
	}

	withERPAgain := appendERPRuntimeGatewayRouteRule(withERP)

	if len(withERPAgain) != 2 {
		t.Fatalf("expected duplicate protection with 2 routes, got %d", len(withERPAgain))
	}

	found := false
	for _, rule := range withERPAgain {
		if rule.Path == apisurface.RuntimeFlowAPIPath {
			found = true
			if rule.Name != apisurface.RuntimeFlowAPIRouteName {
				t.Fatalf("expected ERP route name %s, got %s", apisurface.RuntimeFlowAPIRouteName, rule.Name)
			}
		}
	}

	if !found {
		t.Fatal("expected ERP runtime route rule to be found")
	}
}

func TestRegisterERPRuntimeProtectedRoutesSuccess(t *testing.T) {
	protectedMux := http.NewServeMux()
	service := &fakeGatewayERPRuntimeAPIService{}

	binding, err := registerERPRuntimeProtectedRoutes(protectedMux, service)
	if err != nil {
		t.Fatalf("expected register success, got %v", err)
	}

	if binding.Plan.Name != apisurface.RuntimeFlowGatewayMountName {
		t.Fatalf("expected mount name %s, got %s", apisurface.RuntimeFlowGatewayMountName, binding.Plan.Name)
	}

	if len(binding.RouteBindings) != 1 {
		t.Fatalf("expected 1 route binding, got %d", len(binding.RouteBindings))
	}

	body, err := json.Marshal(validGatewayERPRuntimeAPIRequest())
	if err != nil {
		t.Fatalf("marshal request: %v", err)
	}

	req := httptest.NewRequest(http.MethodPost, apisurface.RuntimeFlowAPIPath, bytes.NewReader(body))
	rec := httptest.NewRecorder()

	protectedMux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected HTTP 200, got %d body=%s", rec.Code, rec.Body.String())
	}

	if !service.called {
		t.Fatal("expected service to be called")
	}

	var resp apisurface.RuntimeFlowAPIResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	if !resp.OK {
		t.Fatal("expected OK response")
	}

	if resp.Status != "completed" {
		t.Fatalf("expected completed status, got %s", resp.Status)
	}
}

func TestRegisterERPRuntimeProtectedRoutesNilMux(t *testing.T) {
	service := &fakeGatewayERPRuntimeAPIService{}

	_, err := registerERPRuntimeProtectedRoutes(nil, service)
	if err != apisurface.ErrRouteRegistrarRequired {
		t.Fatalf("expected ErrRouteRegistrarRequired, got %v", err)
	}
}

func TestRegisterERPRuntimeProtectedRoutesNilService(t *testing.T) {
	protectedMux := http.NewServeMux()

	_, err := registerERPRuntimeProtectedRoutes(protectedMux, nil)
	if err != apisurface.ErrRuntimeFlowAPIServiceRequired {
		t.Fatalf("expected ErrRuntimeFlowAPIServiceRequired, got %v", err)
	}
}
