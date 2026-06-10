package apisurface

type RuntimeFlowGatewayMountBinding struct {
	Plan          RuntimeFlowGatewayMountPlan
	RouteBindings []RuntimeFlowRouteBinding
}

func BuildRuntimeFlowGatewayMountBinding(service RuntimeFlowAPIService) (RuntimeFlowGatewayMountBinding, error) {
	if service == nil {
		return RuntimeFlowGatewayMountBinding{}, ErrRuntimeFlowAPIServiceRequired
	}

	plan := BuildRuntimeFlowGatewayMountPlan()
	if err := ValidateRuntimeFlowGatewayMountPlan(plan); err != nil {
		return RuntimeFlowGatewayMountBinding{}, err
	}

	routeBinding, err := BuildRuntimeFlowRouteBinding(service)
	if err != nil {
		return RuntimeFlowGatewayMountBinding{}, err
	}

	return RuntimeFlowGatewayMountBinding{
		Plan: plan,
		RouteBindings: []RuntimeFlowRouteBinding{
			routeBinding,
		},
	}, nil
}

func MountRuntimeFlowGatewayRoutes(registrar RuntimeFlowRouteRegistrar, service RuntimeFlowAPIService) (RuntimeFlowGatewayMountBinding, error) {
	if registrar == nil {
		return RuntimeFlowGatewayMountBinding{}, ErrRouteRegistrarRequired
	}

	mountBinding, err := BuildRuntimeFlowGatewayMountBinding(service)
	if err != nil {
		return RuntimeFlowGatewayMountBinding{}, err
	}

	for _, routeBinding := range mountBinding.RouteBindings {
		if err := ValidateRuntimeFlowRouteManifest(routeBinding.Manifest); err != nil {
			return RuntimeFlowGatewayMountBinding{}, err
		}

		if routeBinding.Handler == nil {
			return RuntimeFlowGatewayMountBinding{}, ErrRouteHandlerRequired
		}

		if err := registrar.RegisterRoute(routeBinding.Manifest.Method, routeBinding.Manifest.Path, routeBinding.Handler); err != nil {
			return RuntimeFlowGatewayMountBinding{}, err
		}
	}

	return mountBinding, nil
}
