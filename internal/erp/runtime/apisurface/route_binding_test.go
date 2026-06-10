package apisurface

import (
	"errors"
	"net/http"
	"testing"
)

type fakeRuntimeFlowRouteRegistrar struct {
	err error

	called  bool
	method  string
	path    string
	handler http.Handler
}

func (r *fakeRuntimeFlowRouteRegistrar) RegisterRoute(method string, path string, handler http.Handler) error {
	r.called = true
	r.method = method
	r.path = path
	r.handler = handler

	if r.err != nil {
		return r.err
	}

	return nil
}

func TestBuildRuntimeFlowRouteBindingSuccess(t *testing.T) {
	service := &fakeRuntimeFlowAPIService{}

	binding, err := BuildRuntimeFlowRouteBinding(service)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if binding.Manifest.Name != RuntimeFlowAPIRouteName {
		t.Fatalf("expected route name %s, got %s", RuntimeFlowAPIRouteName, binding.Manifest.Name)
	}

	if binding.Manifest.Method != http.MethodPost {
		t.Fatalf("expected POST, got %s", binding.Manifest.Method)
	}

	if binding.Manifest.Path != RuntimeFlowAPIPath {
		t.Fatalf("expected path %s, got %s", RuntimeFlowAPIPath, binding.Manifest.Path)
	}

	if binding.Handler == nil {
		t.Fatal("expected handler")
	}
}

func TestBuildRuntimeFlowRouteBindingServiceRequired(t *testing.T) {
	_, err := BuildRuntimeFlowRouteBinding(nil)
	if !errors.Is(err, ErrRuntimeFlowAPIServiceRequired) {
		t.Fatalf("expected ErrRuntimeFlowAPIServiceRequired, got %v", err)
	}
}

func TestBindRuntimeFlowRoutesSuccess(t *testing.T) {
	registrar := &fakeRuntimeFlowRouteRegistrar{}
	service := &fakeRuntimeFlowAPIService{}

	bindings, err := BindRuntimeFlowRoutes(registrar, service)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if len(bindings) != 1 {
		t.Fatalf("expected 1 binding, got %d", len(bindings))
	}

	if !registrar.called {
		t.Fatal("expected registrar to be called")
	}

	if registrar.method != http.MethodPost {
		t.Fatalf("expected POST, got %s", registrar.method)
	}

	if registrar.path != RuntimeFlowAPIPath {
		t.Fatalf("expected path %s, got %s", RuntimeFlowAPIPath, registrar.path)
	}

	if registrar.handler == nil {
		t.Fatal("expected registered handler")
	}
}

func TestBindRuntimeFlowRoutesRegistrarRequired(t *testing.T) {
	service := &fakeRuntimeFlowAPIService{}

	_, err := BindRuntimeFlowRoutes(nil, service)
	if !errors.Is(err, ErrRouteRegistrarRequired) {
		t.Fatalf("expected ErrRouteRegistrarRequired, got %v", err)
	}
}

func TestBindRuntimeFlowRoutesServiceRequired(t *testing.T) {
	registrar := &fakeRuntimeFlowRouteRegistrar{}

	_, err := BindRuntimeFlowRoutes(registrar, nil)
	if !errors.Is(err, ErrRuntimeFlowAPIServiceRequired) {
		t.Fatalf("expected ErrRuntimeFlowAPIServiceRequired, got %v", err)
	}

	if registrar.called {
		t.Fatal("registrar should not be called when service is nil")
	}
}

func TestBindRuntimeFlowRoutesRegistrationFailed(t *testing.T) {
	registrar := &fakeRuntimeFlowRouteRegistrar{
		err: ErrRouteRegistrationFailed,
	}
	service := &fakeRuntimeFlowAPIService{}

	_, err := BindRuntimeFlowRoutes(registrar, service)
	if !errors.Is(err, ErrRouteRegistrationFailed) {
		t.Fatalf("expected ErrRouteRegistrationFailed, got %v", err)
	}

	if !registrar.called {
		t.Fatal("expected registrar to be called")
	}
}
