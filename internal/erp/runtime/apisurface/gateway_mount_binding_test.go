package apisurface

import (
	"errors"
	"net/http"
	"testing"
)

type fakeRuntimeFlowGatewayMountRegistrar struct {
	err error

	called  bool
	method  string
	path    string
	handler http.Handler
}

func (r *fakeRuntimeFlowGatewayMountRegistrar) RegisterRoute(method string, path string, handler http.Handler) error {
	r.called = true
	r.method = method
	r.path = path
	r.handler = handler

	if r.err != nil {
		return r.err
	}

	return nil
}

func TestBuildRuntimeFlowGatewayMountBindingSuccess(t *testing.T) {
	service := &fakeRuntimeFlowAPIService{}

	binding, err := BuildRuntimeFlowGatewayMountBinding(service)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if binding.Plan.Name != RuntimeFlowGatewayMountName {
		t.Fatalf("expected mount name %s, got %s", RuntimeFlowGatewayMountName, binding.Plan.Name)
	}

	if binding.Plan.ServiceName != RuntimeFlowGatewayServiceName {
		t.Fatalf("expected service name %s, got %s", RuntimeFlowGatewayServiceName, binding.Plan.ServiceName)
	}

	if binding.Plan.MountPath != RuntimeFlowGatewayMountPath {
		t.Fatalf("expected mount path %s, got %s", RuntimeFlowGatewayMountPath, binding.Plan.MountPath)
	}

	if len(binding.RouteBindings) != 1 {
		t.Fatalf("expected 1 route binding, got %d", len(binding.RouteBindings))
	}

	if binding.RouteBindings[0].Manifest.Path != RuntimeFlowAPIPath {
		t.Fatalf("expected route path %s, got %s", RuntimeFlowAPIPath, binding.RouteBindings[0].Manifest.Path)
	}

	if binding.RouteBindings[0].Handler == nil {
		t.Fatal("expected route handler")
	}
}

func TestBuildRuntimeFlowGatewayMountBindingServiceRequired(t *testing.T) {
	_, err := BuildRuntimeFlowGatewayMountBinding(nil)
	if !errors.Is(err, ErrRuntimeFlowAPIServiceRequired) {
		t.Fatalf("expected ErrRuntimeFlowAPIServiceRequired, got %v", err)
	}
}

func TestMountRuntimeFlowGatewayRoutesSuccess(t *testing.T) {
	registrar := &fakeRuntimeFlowGatewayMountRegistrar{}
	service := &fakeRuntimeFlowAPIService{}

	binding, err := MountRuntimeFlowGatewayRoutes(registrar, service)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
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

	if binding.Plan.Name != RuntimeFlowGatewayMountName {
		t.Fatalf("expected mount name %s, got %s", RuntimeFlowGatewayMountName, binding.Plan.Name)
	}

	if len(binding.RouteBindings) != 1 {
		t.Fatalf("expected 1 route binding, got %d", len(binding.RouteBindings))
	}
}

func TestMountRuntimeFlowGatewayRoutesRegistrarRequired(t *testing.T) {
	service := &fakeRuntimeFlowAPIService{}

	_, err := MountRuntimeFlowGatewayRoutes(nil, service)
	if !errors.Is(err, ErrRouteRegistrarRequired) {
		t.Fatalf("expected ErrRouteRegistrarRequired, got %v", err)
	}
}

func TestMountRuntimeFlowGatewayRoutesServiceRequired(t *testing.T) {
	registrar := &fakeRuntimeFlowGatewayMountRegistrar{}

	_, err := MountRuntimeFlowGatewayRoutes(registrar, nil)
	if !errors.Is(err, ErrRuntimeFlowAPIServiceRequired) {
		t.Fatalf("expected ErrRuntimeFlowAPIServiceRequired, got %v", err)
	}

	if registrar.called {
		t.Fatal("registrar should not be called when service is nil")
	}
}

func TestMountRuntimeFlowGatewayRoutesRegistrationFailed(t *testing.T) {
	registrar := &fakeRuntimeFlowGatewayMountRegistrar{
		err: ErrRouteRegistrationFailed,
	}
	service := &fakeRuntimeFlowAPIService{}

	_, err := MountRuntimeFlowGatewayRoutes(registrar, service)
	if !errors.Is(err, ErrRouteRegistrationFailed) {
		t.Fatalf("expected ErrRouteRegistrationFailed, got %v", err)
	}

	if !registrar.called {
		t.Fatal("expected registrar to be called")
	}
}
