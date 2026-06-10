package apisurface

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

type muxRuntimeFlowRouteRegistrar struct {
	mux *http.ServeMux
}

func newMuxRuntimeFlowRouteRegistrar() *muxRuntimeFlowRouteRegistrar {
	return &muxRuntimeFlowRouteRegistrar{
		mux: http.NewServeMux(),
	}
}

func (r *muxRuntimeFlowRouteRegistrar) RegisterRoute(method string, path string, handler http.Handler) error {
	if r.mux == nil {
		r.mux = http.NewServeMux()
	}

	r.mux.Handle(path, handler)
	return nil
}

func TestRuntimeFlowRouteBindingMuxSmokeSuccess(t *testing.T) {
	registrar := newMuxRuntimeFlowRouteRegistrar()
	service := &fakeRuntimeFlowAPIService{}

	bindings, err := BindRuntimeFlowRoutes(registrar, service)
	if err != nil {
		t.Fatalf("bind runtime flow routes: %v", err)
	}

	if len(bindings) != 1 {
		t.Fatalf("expected 1 binding, got %d", len(bindings))
	}

	body := mustRuntimeFlowAPIJSON(t, validRuntimeFlowAPIRequest())

	req := httptest.NewRequest(http.MethodPost, RuntimeFlowAPIPath, bytes.NewReader(body))
	rec := httptest.NewRecorder()

	registrar.mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected HTTP 200, got %d body=%s", rec.Code, rec.Body.String())
	}

	if !service.called {
		t.Fatal("expected service to be called through mux binding")
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

func TestRuntimeFlowRouteBindingMuxSmokeMethodNotAllowed(t *testing.T) {
	registrar := newMuxRuntimeFlowRouteRegistrar()
	service := &fakeRuntimeFlowAPIService{}

	_, err := BindRuntimeFlowRoutes(registrar, service)
	if err != nil {
		t.Fatalf("bind runtime flow routes: %v", err)
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

func TestRuntimeFlowRouteBindingMuxSmokeNotFound(t *testing.T) {
	registrar := newMuxRuntimeFlowRouteRegistrar()
	service := &fakeRuntimeFlowAPIService{}

	_, err := BindRuntimeFlowRoutes(registrar, service)
	if err != nil {
		t.Fatalf("bind runtime flow routes: %v", err)
	}

	req := httptest.NewRequest(http.MethodPost, "/api/v1/erp/runtime/wrong", bytes.NewReader([]byte("{}")))
	rec := httptest.NewRecorder()

	registrar.mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected HTTP 404, got %d body=%s", rec.Code, rec.Body.String())
	}

	if service.called {
		t.Fatal("service should not be called on wrong path")
	}
}
