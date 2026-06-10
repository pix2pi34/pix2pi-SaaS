package opsconsole

import (
	"testing"
	"time"
)

func newServiceRegistryScreenRuntimeForTest(t *testing.T) *ServiceRegistryScreenConsoleRuntime {
	t.Helper()

	runtime := NewServiceRegistryScreenConsoleRuntime(DefaultServiceRegistryScreenConsoleConfig())
	now := time.Now().UTC().Format(time.RFC3339Nano)

	_, _, err := runtime.UpsertService(ServiceRegistryScreenEntry{
		TenantID:      "tenant_7",
		ServiceID:     "api_gateway",
		InstanceID:    "api_gateway_1",
		Name:          "API Gateway",
		Address:       "https://api.pix2pi.com.tr",
		Status:        ServiceRegistryScreenStatusHealthy,
		Visibility:    ServiceRegistryScreenVisibilityPlatform,
		Version:       "v1",
		Region:        "tr-istanbul",
		Port:          "9010",
		HealthPath:    "/health",
		LastHeartbeat: now,
		CorrelationID: "corr-service-1",
		Metadata:      map[string]string{"kind": "gateway"},
	})
	if err != nil {
		t.Fatalf("upsert api gateway failed: %v", err)
	}

	_, _, err = runtime.UpsertService(ServiceRegistryScreenEntry{
		TenantID:      "tenant_7",
		ServiceID:     "identity_api",
		InstanceID:    "identity_api_1",
		Name:          "Identity API",
		Address:       "http://127.0.0.1:9001",
		Status:        ServiceRegistryScreenStatusHealthy,
		Visibility:    ServiceRegistryScreenVisibilityTenant,
		Version:       "v1",
		Region:        "tr-istanbul",
		Port:          "9001",
		HealthPath:    "/health",
		LastHeartbeat: now,
		Metadata:      map[string]string{"kind": "service"},
	})
	if err != nil {
		t.Fatalf("upsert identity api failed: %v", err)
	}

	_, _, err = runtime.UpsertService(ServiceRegistryScreenEntry{
		TenantID:      "tenant_7",
		ServiceID:     "internal_registry",
		InstanceID:    "internal_registry_1",
		Name:          "Internal Registry",
		Address:       "http://127.0.0.1:9020",
		Status:        ServiceRegistryScreenStatusMaintenance,
		Visibility:    ServiceRegistryScreenVisibilityInternal,
		Version:       "v1",
		Region:        "tr-istanbul",
		Port:          "9020",
		HealthPath:    "/health",
		LastHeartbeat: now,
	})
	if err != nil {
		t.Fatalf("upsert internal registry failed: %v", err)
	}

	return runtime
}

func TestServiceRegistryScreenConsoleRuntimeBuildsSnapshot(t *testing.T) {
	runtime := newServiceRegistryScreenRuntimeForTest(t)

	snapshot, decision, err := runtime.BuildSnapshot(ServiceRegistryScreenRequest{
		TenantID:        "tenant_7",
		ViewerTenantID:  "platform",
		IncludeInternal: true,
		CorrelationID:   "corr-snapshot-1",
	})
	if err != nil {
		t.Fatalf("build snapshot failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected snapshot allowed, got reason=%s", decision.Reason)
	}
	if !snapshot.OK {
		t.Fatal("expected snapshot OK")
	}
	if snapshot.ServiceCount != 3 {
		t.Fatalf("expected service count 3, got %d", snapshot.ServiceCount)
	}
	if snapshot.HealthyCount != 2 {
		t.Fatalf("expected healthy count 2, got %d", snapshot.HealthyCount)
	}
	if snapshot.MaintenanceCount != 1 {
		t.Fatalf("expected maintenance count 1, got %d", snapshot.MaintenanceCount)
	}
	if snapshot.PlatformVisibleCount != 1 {
		t.Fatalf("expected platform visible count 1, got %d", snapshot.PlatformVisibleCount)
	}
	if snapshot.InternalVisibleCount != 1 {
		t.Fatalf("expected internal visible count 1, got %d", snapshot.InternalVisibleCount)
	}
}

func TestServiceRegistryScreenConsoleRuntimeTenantViewerHidesInternal(t *testing.T) {
	runtime := newServiceRegistryScreenRuntimeForTest(t)

	snapshot, _, err := runtime.BuildSnapshot(ServiceRegistryScreenRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_7",
	})
	if err != nil {
		t.Fatalf("build tenant snapshot failed: %v", err)
	}
	if snapshot.ServiceCount != 2 {
		t.Fatalf("expected tenant viewer to see 2 services, got %d", snapshot.ServiceCount)
	}
	if snapshot.InternalVisibleCount != 0 {
		t.Fatalf("expected internal visible count 0 for tenant viewer, got %d", snapshot.InternalVisibleCount)
	}
}

func TestServiceRegistryScreenConsoleRuntimeStatusFilter(t *testing.T) {
	runtime := newServiceRegistryScreenRuntimeForTest(t)

	snapshot, _, err := runtime.BuildSnapshot(ServiceRegistryScreenRequest{
		TenantID:        "tenant_7",
		ViewerTenantID:  "platform",
		IncludeInternal: true,
		StatusFilter:    ServiceRegistryScreenStatusMaintenance,
	})
	if err != nil {
		t.Fatalf("build status filtered snapshot failed: %v", err)
	}
	if snapshot.ServiceCount != 1 {
		t.Fatalf("expected one maintenance service, got %d", snapshot.ServiceCount)
	}
	if snapshot.Services[0].Status != ServiceRegistryScreenStatusMaintenance {
		t.Fatalf("expected maintenance service, got %s", snapshot.Services[0].Status)
	}
}

func TestServiceRegistryScreenConsoleRuntimeVisibilityFilter(t *testing.T) {
	runtime := newServiceRegistryScreenRuntimeForTest(t)

	snapshot, _, err := runtime.BuildSnapshot(ServiceRegistryScreenRequest{
		TenantID:         "tenant_7",
		ViewerTenantID:   "platform",
		IncludeInternal:  true,
		VisibilityFilter: ServiceRegistryScreenVisibilityInternal,
	})
	if err != nil {
		t.Fatalf("build visibility filtered snapshot failed: %v", err)
	}
	if snapshot.ServiceCount != 1 {
		t.Fatalf("expected one internal service, got %d", snapshot.ServiceCount)
	}
	if snapshot.Services[0].Visibility != ServiceRegistryScreenVisibilityInternal {
		t.Fatalf("expected internal visibility, got %s", snapshot.Services[0].Visibility)
	}
}

func TestServiceRegistryScreenConsoleRuntimeDetectsStaleHeartbeat(t *testing.T) {
	config := DefaultServiceRegistryScreenConsoleConfig()
	config.StaleAfterSeconds = 1
	runtime := NewServiceRegistryScreenConsoleRuntime(config)

	_, _, err := runtime.UpsertService(ServiceRegistryScreenEntry{
		TenantID:      "tenant_7",
		ServiceID:     "stale_service",
		InstanceID:    "stale_service_1",
		Name:          "Stale Service",
		Address:       "http://127.0.0.1:9999",
		Status:        ServiceRegistryScreenStatusHealthy,
		Visibility:    ServiceRegistryScreenVisibilityTenant,
		LastHeartbeat: time.Now().UTC().Add(-5 * time.Minute).Format(time.RFC3339Nano),
	})
	if err != nil {
		t.Fatalf("upsert stale service failed: %v", err)
	}

	snapshot, _, err := runtime.BuildSnapshot(ServiceRegistryScreenRequest{
		TenantID: "tenant_7",
	})
	if err != nil {
		t.Fatalf("build snapshot failed: %v", err)
	}
	if snapshot.DegradedCount != 1 {
		t.Fatalf("expected stale service degraded count 1, got %d", snapshot.DegradedCount)
	}
	if snapshot.Services[0].Status != ServiceRegistryScreenStatusDegraded {
		t.Fatalf("expected stale service status DEGRADED, got %s", snapshot.Services[0].Status)
	}
}

func TestServiceRegistryScreenConsoleRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewServiceRegistryScreenConsoleRuntime(DefaultServiceRegistryScreenConsoleConfig())

	_, decision, err := runtime.BuildSnapshot(ServiceRegistryScreenRequest{})
	if err != ErrServiceRegistryScreenMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != ServiceRegistryScreenReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestServiceRegistryScreenConsoleRuntimeRejectsCrossTenantViewer(t *testing.T) {
	runtime := newServiceRegistryScreenRuntimeForTest(t)

	_, decision, err := runtime.BuildSnapshot(ServiceRegistryScreenRequest{
		TenantID:       "tenant_7",
		ViewerTenantID: "tenant_8",
	})
	if err != ErrServiceRegistryScreenCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != ServiceRegistryScreenReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestServiceRegistryScreenConsoleRuntimeRejectsInvalidStatus(t *testing.T) {
	runtime := NewServiceRegistryScreenConsoleRuntime(DefaultServiceRegistryScreenConsoleConfig())

	_, decision, err := runtime.UpsertService(ServiceRegistryScreenEntry{
		TenantID:   "tenant_7",
		ServiceID:  "bad_service",
		InstanceID: "bad_service_1",
		Name:       "Bad Service",
		Address:    "http://127.0.0.1:9999",
		Status:     "BROKEN",
		Visibility: ServiceRegistryScreenVisibilityTenant,
	})
	if err != ErrServiceRegistryScreenInvalidStatus {
		t.Fatalf("expected invalid status error, got %v", err)
	}
	if decision.Reason != ServiceRegistryScreenReasonInvalidStatus {
		t.Fatalf("expected invalid status reason, got %s", decision.Reason)
	}
}

func TestServiceRegistryScreenConsoleRuntimeRejectsInvalidVisibility(t *testing.T) {
	runtime := NewServiceRegistryScreenConsoleRuntime(DefaultServiceRegistryScreenConsoleConfig())

	_, decision, err := runtime.UpsertService(ServiceRegistryScreenEntry{
		TenantID:   "tenant_7",
		ServiceID:  "bad_service",
		InstanceID: "bad_service_1",
		Name:       "Bad Service",
		Address:    "http://127.0.0.1:9999",
		Status:     ServiceRegistryScreenStatusHealthy,
		Visibility: "PUBLIC_WORLD",
	})
	if err != ErrServiceRegistryScreenInvalidVisibility {
		t.Fatalf("expected invalid visibility error, got %v", err)
	}
	if decision.Reason != ServiceRegistryScreenReasonInvalidVisibility {
		t.Fatalf("expected invalid visibility reason, got %s", decision.Reason)
	}
}

func TestServiceRegistryScreenConsoleRuntimeRejectsMissingRequiredFields(t *testing.T) {
	runtime := NewServiceRegistryScreenConsoleRuntime(DefaultServiceRegistryScreenConsoleConfig())

	_, decision, err := runtime.UpsertService(ServiceRegistryScreenEntry{
		TenantID:   "tenant_7",
		InstanceID: "instance_1",
		Name:       "Missing Service ID",
		Address:    "http://127.0.0.1:9999",
		Status:     ServiceRegistryScreenStatusHealthy,
		Visibility: ServiceRegistryScreenVisibilityTenant,
	})
	if err != ErrServiceRegistryScreenMissingServiceID {
		t.Fatalf("expected missing service id error, got %v", err)
	}
	if decision.Reason != ServiceRegistryScreenReasonMissingServiceID {
		t.Fatalf("expected missing service id reason, got %s", decision.Reason)
	}
}
