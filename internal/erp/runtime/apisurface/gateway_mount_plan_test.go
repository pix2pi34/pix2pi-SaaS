package apisurface

import (
	"errors"
	"testing"
)

func TestBuildRuntimeFlowGatewayMountPlanSuccess(t *testing.T) {
	plan := BuildRuntimeFlowGatewayMountPlan()

	if plan.Name != RuntimeFlowGatewayMountName {
		t.Fatalf("expected mount name %s, got %s", RuntimeFlowGatewayMountName, plan.Name)
	}

	if plan.ServiceName != RuntimeFlowGatewayServiceName {
		t.Fatalf("expected service name %s, got %s", RuntimeFlowGatewayServiceName, plan.ServiceName)
	}

	if plan.MountPath != RuntimeFlowGatewayMountPath {
		t.Fatalf("expected mount path %s, got %s", RuntimeFlowGatewayMountPath, plan.MountPath)
	}

	if plan.UpstreamMode != RuntimeFlowGatewayUpstreamMode {
		t.Fatalf("expected upstream mode %s, got %s", RuntimeFlowGatewayUpstreamMode, plan.UpstreamMode)
	}

	if len(plan.Routes) != 1 {
		t.Fatalf("expected 1 route, got %d", len(plan.Routes))
	}

	if plan.Routes[0].Path != RuntimeFlowAPIPath {
		t.Fatalf("expected route path %s, got %s", RuntimeFlowAPIPath, plan.Routes[0].Path)
	}

	if !plan.Security.RequiresAuth {
		t.Fatal("expected auth required")
	}

	if !plan.Security.RequiresTenantHeader {
		t.Fatal("expected tenant header required")
	}

	if !plan.Security.RequiresRequestID {
		t.Fatal("expected request id required")
	}

	if !plan.Security.RequiresIdempotency {
		t.Fatal("expected idempotency required")
	}

	if err := ValidateRuntimeFlowGatewayMountPlan(plan); err != nil {
		t.Fatalf("expected valid mount plan, got %v", err)
	}
}

func TestRuntimeFlowGatewayMountRoutesSuccess(t *testing.T) {
	plan := BuildRuntimeFlowGatewayMountPlan()

	routes, err := RuntimeFlowGatewayMountRoutes(plan)
	if err != nil {
		t.Fatalf("expected routes success, got %v", err)
	}

	if len(routes) != 1 {
		t.Fatalf("expected 1 route, got %d", len(routes))
	}

	if routes[0].Name != RuntimeFlowAPIRouteName {
		t.Fatalf("expected route name %s, got %s", RuntimeFlowAPIRouteName, routes[0].Name)
	}
}

func TestValidateRuntimeFlowGatewayMountPlanNameRequired(t *testing.T) {
	plan := BuildRuntimeFlowGatewayMountPlan()
	plan.Name = ""

	err := ValidateRuntimeFlowGatewayMountPlan(plan)
	if !errors.Is(err, ErrGatewayMountNameRequired) {
		t.Fatalf("expected ErrGatewayMountNameRequired, got %v", err)
	}
}

func TestValidateRuntimeFlowGatewayMountPlanServiceRequired(t *testing.T) {
	plan := BuildRuntimeFlowGatewayMountPlan()
	plan.ServiceName = ""

	err := ValidateRuntimeFlowGatewayMountPlan(plan)
	if !errors.Is(err, ErrGatewayMountServiceRequired) {
		t.Fatalf("expected ErrGatewayMountServiceRequired, got %v", err)
	}
}

func TestValidateRuntimeFlowGatewayMountPlanPathRequired(t *testing.T) {
	plan := BuildRuntimeFlowGatewayMountPlan()
	plan.MountPath = ""

	err := ValidateRuntimeFlowGatewayMountPlan(plan)
	if !errors.Is(err, ErrGatewayMountPathRequired) {
		t.Fatalf("expected ErrGatewayMountPathRequired, got %v", err)
	}
}

func TestValidateRuntimeFlowGatewayMountPlanRouteCountInvalid(t *testing.T) {
	plan := BuildRuntimeFlowGatewayMountPlan()
	plan.Routes = nil

	err := ValidateRuntimeFlowGatewayMountPlan(plan)
	if !errors.Is(err, ErrGatewayMountRouteCountInvalid) {
		t.Fatalf("expected ErrGatewayMountRouteCountInvalid, got %v", err)
	}
}

func TestValidateRuntimeFlowGatewayMountPlanRoutePathInvalid(t *testing.T) {
	plan := BuildRuntimeFlowGatewayMountPlan()
	plan.MountPath = "/wrong"

	err := ValidateRuntimeFlowGatewayMountPlan(plan)
	if !errors.Is(err, ErrGatewayMountRoutePathInvalid) {
		t.Fatalf("expected ErrGatewayMountRoutePathInvalid, got %v", err)
	}
}

func TestValidateRuntimeFlowGatewayMountPlanSecurityInvalid(t *testing.T) {
	plan := BuildRuntimeFlowGatewayMountPlan()
	plan.Security.RequiresAuth = false

	err := ValidateRuntimeFlowGatewayMountPlan(plan)
	if !errors.Is(err, ErrGatewayMountSecurityInvalid) {
		t.Fatalf("expected ErrGatewayMountSecurityInvalid, got %v", err)
	}
}
