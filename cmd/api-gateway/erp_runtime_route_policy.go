package main

import (
	"net/http"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/apisurface"
)

func erpRuntimeGatewayRouteRule() routeRule {
	return routeRule{
		Name:           apisurface.RuntimeFlowAPIRouteName,
		Path:           apisurface.RuntimeFlowAPIPath,
		Scope:          routeScopeProtected,
		Methods:        []string{http.MethodPost},
		Prefix:         false,
		AuthRequired:   true,
		TenantRequired: true,
		Description:    "ERP runtime E2E transaction flow baslatma endpoint'i",
	}
}

func appendERPRuntimeGatewayRouteRule(rules []routeRule) []routeRule {
	erpRule := erpRuntimeGatewayRouteRule()

	for _, rule := range rules {
		if rule.Name == erpRule.Name || rule.Path == erpRule.Path {
			return rules
		}
	}

	return append(rules, erpRule)
}

func registerERPRuntimeProtectedRoutes(
	protectedMux *http.ServeMux,
	service apisurface.RuntimeFlowAPIService,
) (apisurface.RuntimeFlowGatewayMountBinding, error) {
	return mountERPRuntimeGatewayRoutes(protectedMux, service)
}

func registerERPRuntimeUnavailableProtectedRoute(protectedMux *http.ServeMux, cause error) error {
	if protectedMux == nil {
		return apisurface.ErrRouteRegistrarRequired
	}

	message := "erp runtime gateway service kullanilabilir degil"
	details := map[string]any{}

	if cause != nil {
		details["error"] = cause.Error()
	}

	protectedMux.HandleFunc(apisurface.RuntimeFlowAPIPath, func(w http.ResponseWriter, r *http.Request) {
		writeGatewayError(
			w,
			r.Context(),
			http.StatusServiceUnavailable,
			"erp_runtime_service_unavailable",
			message,
			details,
		)
	})

	return nil
}
