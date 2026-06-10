package apisurface

import (
	"net/http"
)

type RuntimeFlowRouteRegistrar interface {
	RegisterRoute(method string, path string, handler http.Handler) error
}

type RuntimeFlowRouteBinding struct {
	Manifest RuntimeFlowRouteManifest
	Handler  http.Handler
}

func BuildRuntimeFlowRouteBinding(service RuntimeFlowAPIService) (RuntimeFlowRouteBinding, error) {
	if service == nil {
		return RuntimeFlowRouteBinding{}, ErrRuntimeFlowAPIServiceRequired
	}

	manifest := RuntimeFlowRoute()

	if err := ValidateRuntimeFlowRouteManifest(manifest); err != nil {
		return RuntimeFlowRouteBinding{}, err
	}

	return RuntimeFlowRouteBinding{
		Manifest: manifest,
		Handler:  NewRuntimeFlowHTTPHandler(service),
	}, nil
}

func BindRuntimeFlowRoutes(registrar RuntimeFlowRouteRegistrar, service RuntimeFlowAPIService) ([]RuntimeFlowRouteBinding, error) {
	if registrar == nil {
		return nil, ErrRouteRegistrarRequired
	}

	binding, err := BuildRuntimeFlowRouteBinding(service)
	if err != nil {
		return nil, err
	}

	if binding.Handler == nil {
		return nil, ErrRouteHandlerRequired
	}

	if err := registrar.RegisterRoute(binding.Manifest.Method, binding.Manifest.Path, binding.Handler); err != nil {
		return nil, err
	}

	return []RuntimeFlowRouteBinding{binding}, nil
}
