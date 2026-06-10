package apisurface

import (
	"errors"
	"net/http"
	"testing"
)

func TestRuntimeFlowRouteManifestSuccess(t *testing.T) {
	route := RuntimeFlowRoute()

	if route.Name != RuntimeFlowAPIRouteName {
		t.Fatalf("expected route name %s, got %s", RuntimeFlowAPIRouteName, route.Name)
	}

	if route.Method != http.MethodPost {
		t.Fatalf("expected POST, got %s", route.Method)
	}

	if route.Path != RuntimeFlowAPIPath {
		t.Fatalf("expected path %s, got %s", RuntimeFlowAPIPath, route.Path)
	}

	if route.HandlerName != "RuntimeFlowHTTPHandler" {
		t.Fatalf("expected RuntimeFlowHTTPHandler, got %s", route.HandlerName)
	}

	if route.RequestType != "RuntimeFlowAPIRequest" {
		t.Fatalf("expected RuntimeFlowAPIRequest, got %s", route.RequestType)
	}

	if route.ResponseType != "RuntimeFlowAPIResponse" {
		t.Fatalf("expected RuntimeFlowAPIResponse, got %s", route.ResponseType)
	}

	if route.ErrorType != "RuntimeFlowAPIErrorResponse" {
		t.Fatalf("expected RuntimeFlowAPIErrorResponse, got %s", route.ErrorType)
	}

	if !route.Security.RequiresAuth {
		t.Fatal("expected auth required")
	}

	if !route.Security.RequiresTenantHeader {
		t.Fatal("expected tenant header required")
	}

	if !route.Security.RequiresRequestID {
		t.Fatal("expected request id required")
	}

	if !route.Security.RequiresIdempotency {
		t.Fatal("expected idempotency required")
	}

	if err := ValidateRuntimeFlowRouteManifest(route); err != nil {
		t.Fatalf("expected valid route manifest, got %v", err)
	}
}

func TestRuntimeFlowRouteManifestListSuccess(t *testing.T) {
	routes := RuntimeFlowRouteManifestList()

	if len(routes) != 1 {
		t.Fatalf("expected 1 route, got %d", len(routes))
	}

	if err := ValidateRuntimeFlowRouteManifestList(routes); err != nil {
		t.Fatalf("expected valid route list, got %v", err)
	}
}

func TestValidateRuntimeFlowRouteManifestNameRequired(t *testing.T) {
	route := RuntimeFlowRoute()
	route.Name = ""

	err := ValidateRuntimeFlowRouteManifest(route)
	if !errors.Is(err, ErrRouteNameRequired) {
		t.Fatalf("expected ErrRouteNameRequired, got %v", err)
	}
}

func TestValidateRuntimeFlowRouteManifestPathRequired(t *testing.T) {
	route := RuntimeFlowRoute()
	route.Path = ""

	err := ValidateRuntimeFlowRouteManifest(route)
	if !errors.Is(err, ErrRoutePathRequired) {
		t.Fatalf("expected ErrRoutePathRequired, got %v", err)
	}
}

func TestValidateRuntimeFlowRouteManifestMethodInvalid(t *testing.T) {
	route := RuntimeFlowRoute()
	route.Method = http.MethodGet

	err := ValidateRuntimeFlowRouteManifest(route)
	if !errors.Is(err, ErrRouteMethodInvalid) {
		t.Fatalf("expected ErrRouteMethodInvalid, got %v", err)
	}
}

func TestValidateRuntimeFlowRouteManifestHandlerRequired(t *testing.T) {
	route := RuntimeFlowRoute()
	route.HandlerName = ""

	err := ValidateRuntimeFlowRouteManifest(route)
	if !errors.Is(err, ErrRouteHandlerRequired) {
		t.Fatalf("expected ErrRouteHandlerRequired, got %v", err)
	}
}

func TestValidateRuntimeFlowRouteManifestAuthRequired(t *testing.T) {
	route := RuntimeFlowRoute()
	route.Security.RequiresAuth = false

	err := ValidateRuntimeFlowRouteManifest(route)
	if !errors.Is(err, ErrRouteAuthRequired) {
		t.Fatalf("expected ErrRouteAuthRequired, got %v", err)
	}
}

func TestValidateRuntimeFlowRouteManifestTenantHeaderRequired(t *testing.T) {
	route := RuntimeFlowRoute()
	route.Security.RequiresTenantHeader = false

	err := ValidateRuntimeFlowRouteManifest(route)
	if !errors.Is(err, ErrRouteTenantHeaderMissing) {
		t.Fatalf("expected ErrRouteTenantHeaderMissing, got %v", err)
	}
}
