package opsruntime

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestServiceRegistrationEndpointRegistersInstanceAndMetadata(t *testing.T) {
	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())
	endpoint := NewServiceRegistrationEndpointRuntime(DefaultServiceRegistrationEndpointRuntimeConfig(), registry)

	body := []byte(`{
	  "service_name": "identity-api",
	  "host": "10.0.0.7",
	  "port": 9001,
	  "zone": "tr-istanbul-1",
	  "node_id": "node-a",
	  "runtime": "go",
	  "version": "1.0.0",
	  "status": "HEALTHY",
	  "metadata_visibility": "TENANT",
	  "metadata": {
	    "build_sha": "abc123",
	    "deploy_slot": "blue"
	  },
	  "correlation_id": "corr-register-1"
	}`)

	req := httptest.NewRequest(http.MethodPost, ServiceRegistrationEndpointPath, bytes.NewReader(body))
	req.Header.Set("X-Tenant-ID", "tenant_7")
	rec := httptest.NewRecorder()

	endpoint.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d body=%s", rec.Code, rec.Body.String())
	}

	var response ServiceRegistrationEndpointResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode response failed: %v", err)
	}

	if !response.OK {
		t.Fatal("expected ok response")
	}
	if response.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", response.TenantID)
	}
	if response.InstanceID == "" {
		t.Fatal("expected instance id")
	}
	if response.MetadataCount != 2 {
		t.Fatalf("expected metadata count 2, got %d", response.MetadataCount)
	}

	metadata, err := registry.GetMetadata("tenant_7", response.InstanceID, "build_sha")
	if err != nil {
		t.Fatalf("expected build_sha metadata: %v", err)
	}
	if metadata.Value != "abc123" {
		t.Fatalf("expected metadata value abc123, got %s", metadata.Value)
	}
	if metadata.Visibility != InstanceMetadataVisibilityTenant {
		t.Fatalf("expected TENANT visibility, got %s", metadata.Visibility)
	}
}

func TestServiceRegistrationEndpointRejectsMissingTenantHeader(t *testing.T) {
	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())
	endpoint := NewServiceRegistrationEndpointRuntime(DefaultServiceRegistrationEndpointRuntimeConfig(), registry)

	req := httptest.NewRequest(http.MethodPost, ServiceRegistrationEndpointPath, bytes.NewReader([]byte(`{
	  "service_name": "identity-api"
	}`)))
	rec := httptest.NewRecorder()

	endpoint.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400, got %d", rec.Code)
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(ServiceRegistrationEndpointReasonMissingTenant)) {
		t.Fatalf("expected missing tenant reason in body, got %s", rec.Body.String())
	}
}

func TestServiceRegistrationEndpointRejectsCrossTenantBody(t *testing.T) {
	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())
	endpoint := NewServiceRegistrationEndpointRuntime(DefaultServiceRegistrationEndpointRuntimeConfig(), registry)

	req := httptest.NewRequest(http.MethodPost, ServiceRegistrationEndpointPath, bytes.NewReader([]byte(`{
	  "tenant_id": "tenant_8",
	  "service_name": "identity-api"
	}`)))
	req.Header.Set("X-Tenant-ID", "tenant_7")
	rec := httptest.NewRecorder()

	endpoint.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Fatalf("expected status 403, got %d", rec.Code)
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(ServiceRegistrationEndpointReasonCrossTenant)) {
		t.Fatalf("expected cross tenant reason in body, got %s", rec.Body.String())
	}
}

func TestServiceRegistrationEndpointRejectsInvalidMethod(t *testing.T) {
	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())
	endpoint := NewServiceRegistrationEndpointRuntime(DefaultServiceRegistrationEndpointRuntimeConfig(), registry)

	req := httptest.NewRequest(http.MethodGet, ServiceRegistrationEndpointPath, nil)
	req.Header.Set("X-Tenant-ID", "tenant_7")
	rec := httptest.NewRecorder()

	endpoint.ServeHTTP(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("expected status 405, got %d", rec.Code)
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(ServiceRegistrationEndpointReasonInvalidMethod)) {
		t.Fatalf("expected invalid method reason in body, got %s", rec.Body.String())
	}
}

func TestServiceRegistrationEndpointRejectsInvalidPath(t *testing.T) {
	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())
	endpoint := NewServiceRegistrationEndpointRuntime(DefaultServiceRegistrationEndpointRuntimeConfig(), registry)

	req := httptest.NewRequest(http.MethodPost, "/wrong/path", bytes.NewReader([]byte(`{
	  "service_name": "identity-api"
	}`)))
	req.Header.Set("X-Tenant-ID", "tenant_7")
	rec := httptest.NewRecorder()

	endpoint.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Fatalf("expected status 404, got %d", rec.Code)
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(ServiceRegistrationEndpointReasonInvalidPath)) {
		t.Fatalf("expected invalid path reason in body, got %s", rec.Body.String())
	}
}

func TestServiceRegistrationEndpointRejectsMissingRegistry(t *testing.T) {
	endpoint := NewServiceRegistrationEndpointRuntime(DefaultServiceRegistrationEndpointRuntimeConfig(), nil)

	req := httptest.NewRequest(http.MethodPost, ServiceRegistrationEndpointPath, bytes.NewReader([]byte(`{
	  "service_name": "identity-api"
	}`)))
	req.Header.Set("X-Tenant-ID", "tenant_7")
	rec := httptest.NewRecorder()

	endpoint.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("expected status 500, got %d", rec.Code)
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(ServiceRegistrationEndpointReasonMissingRegistry)) {
		t.Fatalf("expected missing registry reason in body, got %s", rec.Body.String())
	}
}

func TestServiceRegistrationEndpointRejectsInvalidBody(t *testing.T) {
	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())
	endpoint := NewServiceRegistrationEndpointRuntime(DefaultServiceRegistrationEndpointRuntimeConfig(), registry)

	req := httptest.NewRequest(http.MethodPost, ServiceRegistrationEndpointPath, bytes.NewReader([]byte(`{bad-json`)))
	req.Header.Set("X-Tenant-ID", "tenant_7")
	rec := httptest.NewRecorder()

	endpoint.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400, got %d", rec.Code)
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(ServiceRegistrationEndpointReasonInvalidBody)) {
		t.Fatalf("expected invalid body reason in body, got %s", rec.Body.String())
	}
}

func TestServiceRegistrationEndpointRejectsRegisterValidationFailure(t *testing.T) {
	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())
	endpoint := NewServiceRegistrationEndpointRuntime(DefaultServiceRegistrationEndpointRuntimeConfig(), registry)

	req := httptest.NewRequest(http.MethodPost, ServiceRegistrationEndpointPath, bytes.NewReader([]byte(`{
	  "status": "HEALTHY"
	}`)))
	req.Header.Set("X-Tenant-ID", "tenant_7")
	rec := httptest.NewRecorder()

	endpoint.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400, got %d", rec.Code)
	}
	if !bytes.Contains(rec.Body.Bytes(), []byte(ServiceRegistrationEndpointReasonRegisterFailed)) {
		t.Fatalf("expected register failed reason in body, got %s", rec.Body.String())
	}
}

func TestServiceRegistrationEndpointSupportsBodyTenantFallbackWhenConfigured(t *testing.T) {
	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	config := DefaultServiceRegistrationEndpointRuntimeConfig()
	config.RequireTenantHeader = false
	config.AllowBodyTenantFallback = true

	endpoint := NewServiceRegistrationEndpointRuntime(config, registry)

	req := httptest.NewRequest(http.MethodPost, ServiceRegistrationEndpointPath, bytes.NewReader([]byte(`{
	  "tenant_id": "tenant_7",
	  "service_name": "identity-api",
	  "metadata": {
	    "build_sha": "abc123"
	  }
	}`)))
	rec := httptest.NewRecorder()

	endpoint.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d body=%s", rec.Code, rec.Body.String())
	}

	var response ServiceRegistrationEndpointResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode response failed: %v", err)
	}

	if response.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", response.TenantID)
	}
}

func TestServiceRegistrationEndpointUpdatesExistingInstance(t *testing.T) {
	registry := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())
	endpoint := NewServiceRegistrationEndpointRuntime(DefaultServiceRegistrationEndpointRuntimeConfig(), registry)

	first := httptest.NewRequest(http.MethodPost, ServiceRegistrationEndpointPath, bytes.NewReader([]byte(`{
	  "instance_id": "instance-fixed",
	  "service_name": "identity-api",
	  "status": "REGISTERED"
	}`)))
	first.Header.Set("X-Tenant-ID", "tenant_7")
	firstRec := httptest.NewRecorder()

	endpoint.ServeHTTP(firstRec, first)

	if firstRec.Code != http.StatusOK {
		t.Fatalf("expected first status 200, got %d", firstRec.Code)
	}

	second := httptest.NewRequest(http.MethodPost, ServiceRegistrationEndpointPath, bytes.NewReader([]byte(`{
	  "instance_id": "instance-fixed",
	  "service_name": "identity-api",
	  "status": "HEALTHY"
	}`)))
	second.Header.Set("X-Tenant-ID", "tenant_7")
	secondRec := httptest.NewRecorder()

	endpoint.ServeHTTP(secondRec, second)

	if secondRec.Code != http.StatusOK {
		t.Fatalf("expected second status 200, got %d", secondRec.Code)
	}

	instances, err := registry.ListTenantInstances("tenant_7")
	if err != nil {
		t.Fatalf("list tenant instances failed: %v", err)
	}
	if len(instances) != 1 {
		t.Fatalf("expected single updated instance, got %d", len(instances))
	}
	if instances[0].Status != ServiceInstanceStatusHealthy {
		t.Fatalf("expected HEALTHY, got %s", instances[0].Status)
	}
}
