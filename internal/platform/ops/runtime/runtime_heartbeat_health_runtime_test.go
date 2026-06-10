package opsruntime

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func heartbeatHealthRuntimeForTest() (*RuntimeHeartbeatHealthRuntime, *InstanceMetadataRuntime) {
	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())
	visibility := NewRegistryVisibilityRuntime(DefaultRegistryVisibilityRuntimeConfig(), registry)
	cleanup := NewStaleInstanceCleanupRuntime(DefaultStaleInstanceCleanupRuntimeConfig(), registry)
	runtime := NewRuntimeHeartbeatHealthRuntime(DefaultRuntimeHeartbeatHealthRuntimeConfig(), registry, visibility, cleanup)
	return runtime, registry
}

func TestRuntimeHeartbeatHealthRuntimePushHeartbeatRegistersInstance(t *testing.T) {
	runtime, registry := heartbeatHealthRuntimeForTest()

	req := httptest.NewRequest(http.MethodPost, RuntimeHeartbeatEndpointPath, bytes.NewReader([]byte(`{
	  "service_name": "identity-api",
	  "host": "10.0.0.7",
	  "port": 9001,
	  "zone": "tr-istanbul-1",
	  "node_id": "node-a",
	  "runtime": "go",
	  "version": "1.0.0",
	  "status": "HEALTHY",
	  "health_status": "ok",
	  "metadata": {
	    "build_sha": "abc123"
	  },
	  "correlation_id": "corr-heartbeat-1"
	}`)))
	req.Header.Set("X-Tenant-ID", "tenant_7")

	rec := httptest.NewRecorder()
	runtime.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d body=%s", rec.Code, rec.Body.String())
	}

	var response RuntimeHeartbeatPushResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode response failed: %v", err)
	}

	if !response.OK {
		t.Fatal("expected heartbeat response ok")
	}
	if response.InstanceID == "" {
		t.Fatal("expected instance id")
	}
	if response.MetadataCount != 3 {
		t.Fatalf("expected metadata count 3, got %d", response.MetadataCount)
	}

	metadata, err := registry.GetMetadata("tenant_7", response.InstanceID, "last_heartbeat_at")
	if err != nil {
		t.Fatalf("expected last heartbeat metadata: %v", err)
	}
	if metadata.Value == "" {
		t.Fatal("expected last heartbeat value")
	}

	healthStatus, err := registry.GetMetadata("tenant_7", response.InstanceID, "health_status")
	if err != nil {
		t.Fatalf("expected health_status metadata: %v", err)
	}
	if healthStatus.Value != "ok" {
		t.Fatalf("expected health status ok, got %s", healthStatus.Value)
	}
}

func TestRuntimeHeartbeatHealthRuntimePullHealthSnapshot(t *testing.T) {
	runtime, _ := heartbeatHealthRuntimeForTest()

	push := httptest.NewRequest(http.MethodPost, RuntimeHeartbeatEndpointPath, bytes.NewReader([]byte(`{
	  "service_name": "identity-api",
	  "status": "HEALTHY",
	  "health_status": "ok"
	}`)))
	push.Header.Set("X-Tenant-ID", "tenant_7")
	pushRec := httptest.NewRecorder()
	runtime.ServeHTTP(pushRec, push)

	if pushRec.Code != http.StatusOK {
		t.Fatalf("expected push status 200, got %d", pushRec.Code)
	}

	pull := httptest.NewRequest(http.MethodGet, RuntimeHealthSnapshotPath+"?scope=INTERNAL&viewer_tenant_id=platform", nil)
	pull.Header.Set("X-Tenant-ID", "tenant_7")
	pullRec := httptest.NewRecorder()
	runtime.ServeHTTP(pullRec, pull)

	if pullRec.Code != http.StatusOK {
		t.Fatalf("expected pull status 200, got %d body=%s", pullRec.Code, pullRec.Body.String())
	}

	var response RuntimeHealthSnapshotResponse
	if err := json.Unmarshal(pullRec.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode snapshot failed: %v", err)
	}

	if !response.OK {
		t.Fatal("expected snapshot ok")
	}
	if response.InstanceCount != 1 {
		t.Fatalf("expected instance count 1, got %d", response.InstanceCount)
	}
	if response.HealthyCount != 1 {
		t.Fatalf("expected healthy count 1, got %d", response.HealthyCount)
	}
	if response.Entries[0].HealthStatus != "ok" {
		t.Fatalf("expected health status ok, got %s", response.Entries[0].HealthStatus)
	}
}

func TestRuntimeHeartbeatHealthRuntimeRejectsMissingTenant(t *testing.T) {
	runtime, _ := heartbeatHealthRuntimeForTest()

	req := httptest.NewRequest(http.MethodPost, RuntimeHeartbeatEndpointPath, bytes.NewReader([]byte(`{
	  "service_name": "identity-api"
	}`)))
	rec := httptest.NewRecorder()

	runtime.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400, got %d", rec.Code)
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(RuntimeHealthReasonMissingTenant)) {
		t.Fatalf("expected missing tenant reason, got %s", rec.Body.String())
	}
}

func TestRuntimeHeartbeatHealthRuntimeRejectsCrossTenantBody(t *testing.T) {
	runtime, _ := heartbeatHealthRuntimeForTest()

	req := httptest.NewRequest(http.MethodPost, RuntimeHeartbeatEndpointPath, bytes.NewReader([]byte(`{
	  "tenant_id": "tenant_8",
	  "service_name": "identity-api"
	}`)))
	req.Header.Set("X-Tenant-ID", "tenant_7")
	rec := httptest.NewRecorder()

	runtime.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("expected status 403, got %d", rec.Code)
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(RuntimeHealthReasonCrossTenant)) {
		t.Fatalf("expected cross tenant reason, got %s", rec.Body.String())
	}
}

func TestRuntimeHeartbeatHealthRuntimeRejectsInvalidMethod(t *testing.T) {
	runtime, _ := heartbeatHealthRuntimeForTest()

	req := httptest.NewRequest(http.MethodGet, RuntimeHeartbeatEndpointPath, nil)
	req.Header.Set("X-Tenant-ID", "tenant_7")
	rec := httptest.NewRecorder()

	runtime.ServeHTTP(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("expected status 405, got %d", rec.Code)
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(RuntimeHealthReasonInvalidMethod)) {
		t.Fatalf("expected invalid method reason, got %s", rec.Body.String())
	}
}

func TestRuntimeHeartbeatHealthRuntimeRejectsInvalidBody(t *testing.T) {
	runtime, _ := heartbeatHealthRuntimeForTest()

	req := httptest.NewRequest(http.MethodPost, RuntimeHeartbeatEndpointPath, bytes.NewReader([]byte(`{bad-json`)))
	req.Header.Set("X-Tenant-ID", "tenant_7")
	rec := httptest.NewRecorder()

	runtime.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400, got %d", rec.Code)
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(RuntimeHealthReasonInvalidBody)) {
		t.Fatalf("expected invalid body reason, got %s", rec.Body.String())
	}
}

func TestRuntimeHeartbeatHealthRuntimeRejectsMissingService(t *testing.T) {
	runtime, _ := heartbeatHealthRuntimeForTest()

	req := httptest.NewRequest(http.MethodPost, RuntimeHeartbeatEndpointPath, bytes.NewReader([]byte(`{
	  "status": "HEALTHY"
	}`)))
	req.Header.Set("X-Tenant-ID", "tenant_7")
	rec := httptest.NewRecorder()

	runtime.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400, got %d", rec.Code)
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(RuntimeHealthReasonMissingService)) {
		t.Fatalf("expected missing service reason, got %s", rec.Body.String())
	}
}

func TestRuntimeHeartbeatHealthRuntimeRejectsMissingRegistry(t *testing.T) {
	runtime := NewRuntimeHeartbeatHealthRuntime(DefaultRuntimeHeartbeatHealthRuntimeConfig(), nil, nil, nil)

	req := httptest.NewRequest(http.MethodPost, RuntimeHeartbeatEndpointPath, bytes.NewReader([]byte(`{
	  "service_name": "identity-api"
	}`)))
	req.Header.Set("X-Tenant-ID", "tenant_7")
	rec := httptest.NewRecorder()

	runtime.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("expected status 500, got %d", rec.Code)
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(RuntimeHealthReasonMissingRegistry)) {
		t.Fatalf("expected missing registry reason, got %s", rec.Body.String())
	}
}

func TestRuntimeHeartbeatHealthRuntimeHealthSnapshotRejectsCrossTenantTenantScope(t *testing.T) {
	runtime, _ := heartbeatHealthRuntimeForTest()

	push := httptest.NewRequest(http.MethodPost, RuntimeHeartbeatEndpointPath, bytes.NewReader([]byte(`{
	  "service_name": "identity-api",
	  "status": "HEALTHY"
	}`)))
	push.Header.Set("X-Tenant-ID", "tenant_7")
	pushRec := httptest.NewRecorder()
	runtime.ServeHTTP(pushRec, push)

	pull := httptest.NewRequest(http.MethodGet, RuntimeHealthSnapshotPath+"?scope=TENANT&viewer_tenant_id=tenant_8", nil)
	pull.Header.Set("X-Tenant-ID", "tenant_7")
	pullRec := httptest.NewRecorder()
	runtime.ServeHTTP(pullRec, pull)

	if pullRec.Code != http.StatusForbidden {
		t.Fatalf("expected status 403, got %d body=%s", pullRec.Code, pullRec.Body.String())
	}
	if !bytes.Contains(pullRec.Body.Bytes(), []byte(RuntimeHealthReasonSnapshotFailed)) {
		t.Fatalf("expected snapshot failed reason, got %s", pullRec.Body.String())
	}
}

func TestRuntimeHeartbeatHealthRuntimeBodyTenantFallback(t *testing.T) {
	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())
	visibility := NewRegistryVisibilityRuntime(DefaultRegistryVisibilityRuntimeConfig(), registry)
	cleanup := NewStaleInstanceCleanupRuntime(DefaultStaleInstanceCleanupRuntimeConfig(), registry)

	config := DefaultRuntimeHeartbeatHealthRuntimeConfig()
	config.RequireTenantHeader = false
	config.AllowBodyTenantFallback = true

	runtime := NewRuntimeHeartbeatHealthRuntime(config, registry, visibility, cleanup)

	req := httptest.NewRequest(http.MethodPost, RuntimeHeartbeatEndpointPath, bytes.NewReader([]byte(`{
	  "tenant_id": "tenant_7",
	  "service_name": "identity-api"
	}`)))
	rec := httptest.NewRecorder()

	runtime.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d body=%s", rec.Code, rec.Body.String())
	}

	var response RuntimeHeartbeatPushResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode response failed: %v", err)
	}
	if response.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", response.TenantID)
	}
}

func TestRuntimeHeartbeatHealthRuntimeInvalidPath(t *testing.T) {
	runtime, _ := heartbeatHealthRuntimeForTest()

	req := httptest.NewRequest(http.MethodPost, "/wrong/path", bytes.NewReader([]byte(`{
	  "service_name": "identity-api"
	}`)))
	req.Header.Set("X-Tenant-ID", "tenant_7")
	rec := httptest.NewRecorder()

	runtime.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected status 404, got %d", rec.Code)
	}
}
