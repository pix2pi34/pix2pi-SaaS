package apisurface

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

type gatewayMountMuxRegistrar struct {
	mux *http.ServeMux
}

func newGatewayMountMuxRegistrar() *gatewayMountMuxRegistrar {
	return &gatewayMountMuxRegistrar{
		mux: http.NewServeMux(),
	}
}

func (r *gatewayMountMuxRegistrar) RegisterRoute(method string, path string, handler http.Handler) error {
	if r.mux == nil {
		r.mux = http.NewServeMux()
	}

	r.mux.Handle(path, handler)
	return nil
}

func TestRuntimeFlowGatewayMountBindingMuxSmokeSuccess(t *testing.T) {
	registrar := newGatewayMountMuxRegistrar()
	service := &fakeRuntimeFlowAPIService{}

	binding, err := MountRuntimeFlowGatewayRoutes(registrar, service)
	if err != nil {
		t.Fatalf("mount runtime flow gateway routes: %v", err)
	}

	if binding.Plan.Name != RuntimeFlowGatewayMountName {
		t.Fatalf("expected mount name %s, got %s", RuntimeFlowGatewayMountName, binding.Plan.Name)
	}

	if len(binding.RouteBindings) != 1 {
		t.Fatalf("expected 1 route binding, got %d", len(binding.RouteBindings))
	}

	body := mustRuntimeFlowAPIJSON(t, validRuntimeFlowAPIRequest())

	req := httptest.NewRequest(http.MethodPost, RuntimeFlowAPIPath, bytes.NewReader(body))
	rec := httptest.NewRecorder()

	registrar.mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected HTTP 200, got %d body=%s", rec.Code, rec.Body.String())
	}

	if !service.called {
		t.Fatal("expected service to be called through gateway mount mux")
	}

	var resp RuntimeFlowAPIResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	if !resp.OK {
		t.Fatal("expected OK response")
	}

	if resp.Status != "completed" {
		t.Fatalf("expected completed status, got %s", resp.Status)
	}

	if resp.StepCount != 6 {
		t.Fatalf("expected step_count 6, got %d", resp.StepCount)
	}
}

func TestRuntimeFlowGatewayMountBindingMuxSmokeMethodNotAllowed(t *testing.T) {
	registrar := newGatewayMountMuxRegistrar()
	service := &fakeRuntimeFlowAPIService{}

	_, err := MountRuntimeFlowGatewayRoutes(registrar, service)
	if err != nil {
		t.Fatalf("mount runtime flow gateway routes: %v", err)
	}

	req := httptest.NewRequest(http.MethodGet, RuntimeFlowAPIPath, nil)
	rec := httptest.NewRecorder()

	registrar.mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("expected HTTP 405, got %d body=%s", rec.Code, rec.Body.String())
	}

	if service.called {
		t.Fatal("service should not be called on invalid method")
	}

	var resp RuntimeFlowAPIErrorResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode error response: %v", err)
	}

	if resp.ErrorCode != "INVALID_HTTP_METHOD" {
		t.Fatalf("expected INVALID_HTTP_METHOD, got %s", resp.ErrorCode)
	}
}

func TestRuntimeFlowGatewayMountBindingMuxSmokeNotFound(t *testing.T) {
	registrar := newGatewayMountMuxRegistrar()
	service := &fakeRuntimeFlowAPIService{}

	_, err := MountRuntimeFlowGatewayRoutes(registrar, service)
	if err != nil {
		t.Fatalf("mount runtime flow gateway routes: %v", err)
	}

	req := httptest.NewRequest(http.MethodPost, "/api/v1/erp/runtime/unknown", bytes.NewReader([]byte("{}")))
	rec := httptest.NewRecorder()

	registrar.mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected HTTP 404, got %d body=%s", rec.Code, rec.Body.String())
	}

	if service.called {
		t.Fatal("service should not be called on wrong path")
	}
}

func TestRuntimeFlowGatewayMountBindingMuxSmokeServiceRequired(t *testing.T) {
	registrar := newGatewayMountMuxRegistrar()

	_, err := MountRuntimeFlowGatewayRoutes(registrar, nil)
	if err == nil {
		t.Fatal("expected error")
	}

	if err != ErrRuntimeFlowAPIServiceRequired {
		t.Fatalf("expected ErrRuntimeFlowAPIServiceRequired, got %v", err)
	}
}
