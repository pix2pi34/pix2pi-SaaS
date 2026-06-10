package apisurface

import (
	"net/http"
	"strings"
)

const RuntimeFlowAPIRouteName = "erp.runtime.flows.create"

type RuntimeFlowRouteSecurity struct {
	RequiresAuth         bool
	RequiresTenantHeader bool
	RequiresRequestID    bool
	RequiresIdempotency  bool
}

type RuntimeFlowRouteManifest struct {
	Name        string
	Method      string
	Path        string
	HandlerName string

	RequestType  string
	ResponseType string
	ErrorType    string

	Security RuntimeFlowRouteSecurity

	Description string
}

func RuntimeFlowRoute() RuntimeFlowRouteManifest {
	return RuntimeFlowRouteManifest{
		Name:        RuntimeFlowAPIRouteName,
		Method:      http.MethodPost,
		Path:        RuntimeFlowAPIPath,
		HandlerName: "RuntimeFlowHTTPHandler",

		RequestType:  "RuntimeFlowAPIRequest",
		ResponseType: "RuntimeFlowAPIResponse",
		ErrorType:    "RuntimeFlowAPIErrorResponse",

		Security: RuntimeFlowRouteSecurity{
			RequiresAuth:         true,
			RequiresTenantHeader: true,
			RequiresRequestID:    true,
			RequiresIdempotency:  true,
		},

		Description: "ERP runtime E2E transaction flow baslatma endpoint'i",
	}
}

func RuntimeFlowRouteManifestList() []RuntimeFlowRouteManifest {
	return []RuntimeFlowRouteManifest{
		RuntimeFlowRoute(),
	}
}

func ValidateRuntimeFlowRouteManifest(route RuntimeFlowRouteManifest) error {
	if strings.TrimSpace(route.Name) == "" {
		return ErrRouteNameRequired
	}

	if strings.TrimSpace(route.Path) == "" {
		return ErrRoutePathRequired
	}

	if route.Method != http.MethodPost {
		return ErrRouteMethodInvalid
	}

	if strings.TrimSpace(route.HandlerName) == "" {
		return ErrRouteHandlerRequired
	}

	if !route.Security.RequiresAuth {
		return ErrRouteAuthRequired
	}

	if !route.Security.RequiresTenantHeader {
		return ErrRouteTenantHeaderMissing
	}

	return nil
}

func ValidateRuntimeFlowRouteManifestList(routes []RuntimeFlowRouteManifest) error {
	for _, route := range routes {
		if err := ValidateRuntimeFlowRouteManifest(route); err != nil {
			return err
		}
	}

	return nil
}
