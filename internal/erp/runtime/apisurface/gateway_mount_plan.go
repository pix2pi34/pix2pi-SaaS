package apisurface

import "strings"

const (
	RuntimeFlowGatewayMountName    = "erp.runtime.api.mount"
	RuntimeFlowGatewayServiceName  = "erp-runtime-api"
	RuntimeFlowGatewayMountPath    = "/api/v1/erp/runtime"
	RuntimeFlowGatewayUpstreamMode = "in_process_handler"
)

type RuntimeFlowGatewayMountSecurity struct {
	RequiresAuth         bool
	RequiresTenantHeader bool
	RequiresRequestID    bool
	RequiresIdempotency  bool
}

type RuntimeFlowGatewayMountPlan struct {
	Name         string
	ServiceName  string
	MountPath    string
	UpstreamMode string

	Routes []RuntimeFlowRouteManifest

	Security RuntimeFlowGatewayMountSecurity

	Description string
}

func BuildRuntimeFlowGatewayMountPlan() RuntimeFlowGatewayMountPlan {
	return RuntimeFlowGatewayMountPlan{
		Name:         RuntimeFlowGatewayMountName,
		ServiceName:  RuntimeFlowGatewayServiceName,
		MountPath:    RuntimeFlowGatewayMountPath,
		UpstreamMode: RuntimeFlowGatewayUpstreamMode,

		Routes: RuntimeFlowRouteManifestList(),

		Security: RuntimeFlowGatewayMountSecurity{
			RequiresAuth:         true,
			RequiresTenantHeader: true,
			RequiresRequestID:    true,
			RequiresIdempotency:  true,
		},

		Description: "ERP Runtime API route'larini gateway uzerine mount etme plani",
	}
}

func ValidateRuntimeFlowGatewayMountPlan(plan RuntimeFlowGatewayMountPlan) error {
	if strings.TrimSpace(plan.Name) == "" {
		return ErrGatewayMountNameRequired
	}

	if strings.TrimSpace(plan.ServiceName) == "" {
		return ErrGatewayMountServiceRequired
	}

	if strings.TrimSpace(plan.MountPath) == "" {
		return ErrGatewayMountPathRequired
	}

	if len(plan.Routes) < 1 {
		return ErrGatewayMountRouteCountInvalid
	}

	if !plan.Security.RequiresAuth ||
		!plan.Security.RequiresTenantHeader ||
		!plan.Security.RequiresRequestID ||
		!plan.Security.RequiresIdempotency {
		return ErrGatewayMountSecurityInvalid
	}

	for _, route := range plan.Routes {
		if err := ValidateRuntimeFlowRouteManifest(route); err != nil {
			return err
		}

		if !strings.HasPrefix(route.Path, plan.MountPath) {
			return ErrGatewayMountRoutePathInvalid
		}
	}

	return nil
}

func RuntimeFlowGatewayMountRoutes(plan RuntimeFlowGatewayMountPlan) ([]RuntimeFlowRouteManifest, error) {
	if err := ValidateRuntimeFlowGatewayMountPlan(plan); err != nil {
		return nil, err
	}

	return plan.Routes, nil
}
