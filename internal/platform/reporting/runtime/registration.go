package runtime

import (
	"errors"
	"net/http"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/api"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/repository"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/reporting/service"
)

var ErrNilMux = errors.New("reporting route registration requires mux")

type Route struct {
	Method string
	Path   string
	Auth   string
	Tenant string
}

func Routes() []Route {
	return []Route{
		{Method: http.MethodGet, Path: api.PathOperationalSummary, Auth: "bearer_required", Tenant: "x_tenant_id_required"},
		{Method: http.MethodGet, Path: api.PathDailyMetrics, Auth: "bearer_required", Tenant: "x_tenant_id_required"},
		{Method: http.MethodGet, Path: api.PathInventoryStatus, Auth: "bearer_required", Tenant: "x_tenant_id_required"},
		{Method: http.MethodGet, Path: api.PathDocumentWorkQueue, Auth: "bearer_required", Tenant: "x_tenant_id_required"},
		{Method: http.MethodGet, Path: api.PathReconciliationStatus, Auth: "bearer_required", Tenant: "x_tenant_id_required"},
		{Method: http.MethodGet, Path: api.PathProjectionState, Auth: "bearer_required", Tenant: "x_tenant_id_required"},
	}
}

func NewReportingHandler() api.Handler {
	repo := repository.New()
	svc := service.New(repo)
	return api.NewHandler(svc)
}

func RegisterReportingRoutes(mux *http.ServeMux) error {
	if mux == nil {
		return ErrNilMux
	}

	handler := NewReportingHandler()
	handler.Register(mux)

	return nil
}
