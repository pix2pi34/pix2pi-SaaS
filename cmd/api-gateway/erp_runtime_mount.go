package main

import (
	"net/http"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/apisurface"
)

type erpRuntimeGatewayMuxRegistrar struct {
	mux *http.ServeMux
}

func newERPRuntimeGatewayMuxRegistrar(mux *http.ServeMux) *erpRuntimeGatewayMuxRegistrar {
	return &erpRuntimeGatewayMuxRegistrar{
		mux: mux,
	}
}

func (r *erpRuntimeGatewayMuxRegistrar) RegisterRoute(method string, path string, handler http.Handler) error {
	if r == nil || r.mux == nil {
		return apisurface.ErrRouteRegistrarRequired
	}

	if handler == nil {
		return apisurface.ErrRouteHandlerRequired
	}

	r.mux.Handle(path, handler)
	return nil
}

func mountERPRuntimeGatewayRoutes(mux *http.ServeMux, service apisurface.RuntimeFlowAPIService) (apisurface.RuntimeFlowGatewayMountBinding, error) {
	if mux == nil {
		return apisurface.RuntimeFlowGatewayMountBinding{}, apisurface.ErrRouteRegistrarRequired
	}

	registrar := newERPRuntimeGatewayMuxRegistrar(mux)

	return apisurface.MountRuntimeFlowGatewayRoutes(registrar, service)
}
