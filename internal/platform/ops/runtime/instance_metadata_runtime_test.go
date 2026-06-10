package opsruntime

import (
	"strings"
	"testing"
)

func TestInstanceMetadataRuntimeRegistersInstance(t *testing.T) {
	runtime := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	instance, decision, err := runtime.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_7",
		ServiceName: "identity-api",
		Host:        "10.0.0.7",
		Port:        9001,
		Zone:        "tr-istanbul-1",
		NodeID:      "node-a",
		Runtime:     "go",
		Version:     "1.0.0",
		Status:      ServiceInstanceStatusHealthy,
	})
	if err != nil {
		t.Fatalf("register instance failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected register allowed, got reason=%s", decision.Reason)
	}
	if instance.InstanceID == "" {
		t.Fatal("expected instance id")
	}
	if instance.ServiceID == "" {
		t.Fatal("expected service id")
	}
	if instance.Status != ServiceInstanceStatusHealthy {
		t.Fatalf("expected HEALTHY, got %s", instance.Status)
	}
}

func TestInstanceMetadataRuntimeUpsertsMetadata(t *testing.T) {
	runtime := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	instance, _, err := runtime.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_7",
		ServiceName: "api-gateway",
		Status:      ServiceInstanceStatusRegistered,
	})
	if err != nil {
		t.Fatalf("register instance failed: %v", err)
	}

	metadata, decision, err := runtime.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_7",
		InstanceID: instance.InstanceID,
		Key:        "build_sha",
		Value:      "abc123",
		Visibility: InstanceMetadataVisibilityTenant,
		Source:     "deploy",
	})
	if err != nil {
		t.Fatalf("upsert metadata failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected upsert allowed, got reason=%s", decision.Reason)
	}
	if metadata.MetadataID == "" {
		t.Fatal("expected metadata id")
	}
	if metadata.Key != "build_sha" {
		t.Fatalf("expected normalized key build_sha, got %s", metadata.Key)
	}

	updated, _, err := runtime.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_7",
		InstanceID: instance.InstanceID,
		Key:        "BUILD_SHA",
		Value:      "def456",
		Visibility: InstanceMetadataVisibilityTenant,
	})
	if err != nil {
		t.Fatalf("update metadata failed: %v", err)
	}
	if updated.MetadataID != metadata.MetadataID {
		t.Fatal("expected metadata id to stay same on upsert")
	}
	if updated.Value != "def456" {
		t.Fatalf("expected updated value def456, got %s", updated.Value)
	}
}

func TestInstanceMetadataRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	_, decision, err := runtime.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		ServiceName: "identity-api",
	})
	if err != ErrInstanceMetadataMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != InstanceMetadataReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestInstanceMetadataRuntimeRejectsMissingService(t *testing.T) {
	runtime := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	_, decision, err := runtime.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID: "tenant_7",
	})
	if err != ErrInstanceMetadataMissingService {
		t.Fatalf("expected missing service error, got %v", err)
	}
	if decision.Reason != InstanceMetadataReasonMissingService {
		t.Fatalf("expected missing service reason, got %s", decision.Reason)
	}
}

func TestInstanceMetadataRuntimeRejectsInvalidVisibility(t *testing.T) {
	runtime := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	instance, _, err := runtime.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_7",
		ServiceName: "identity-api",
	})
	if err != nil {
		t.Fatalf("register instance failed: %v", err)
	}

	_, decision, err := runtime.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_7",
		InstanceID: instance.InstanceID,
		Key:        "build_sha",
		Value:      "abc123",
		Visibility: "PUBLIC",
	})
	if err != ErrInstanceMetadataInvalidVisibility {
		t.Fatalf("expected invalid visibility error, got %v", err)
	}
	if decision.Reason != InstanceMetadataReasonInvalidVisibility {
		t.Fatalf("expected invalid visibility reason, got %s", decision.Reason)
	}
}

func TestInstanceMetadataRuntimeRejectsUnregisteredInstance(t *testing.T) {
	runtime := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	_, decision, err := runtime.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_7",
		InstanceID: "instance_missing",
		Key:        "build_sha",
		Value:      "abc123",
	})
	if err != ErrInstanceMetadataInstanceNotFound {
		t.Fatalf("expected instance not found error, got %v", err)
	}
	if decision.Reason != InstanceMetadataReasonInstanceNotFound {
		t.Fatalf("expected instance not found reason, got %s", decision.Reason)
	}
}

func TestInstanceMetadataRuntimeRejectsCrossTenantMetadataAccess(t *testing.T) {
	runtime := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	instance, _, err := runtime.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_7",
		ServiceName: "identity-api",
	})
	if err != nil {
		t.Fatalf("register instance failed: %v", err)
	}

	_, decision, err := runtime.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_8",
		InstanceID: instance.InstanceID,
		Key:        "build_sha",
		Value:      "abc123",
	})
	if err != ErrInstanceMetadataCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != InstanceMetadataReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}

	_, err = runtime.GetMetadata("tenant_8", instance.InstanceID, "build_sha")
	if err != ErrInstanceMetadataCrossTenant {
		t.Fatalf("expected cross tenant get error, got %v", err)
	}
}

func TestInstanceMetadataRuntimeListsTenantScopedMetadata(t *testing.T) {
	runtime := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	instance7, _, err := runtime.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_7",
		ServiceName: "identity-api",
	})
	if err != nil {
		t.Fatalf("register tenant_7 instance failed: %v", err)
	}

	instance8, _, err := runtime.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_8",
		ServiceName: "identity-api",
	})
	if err != nil {
		t.Fatalf("register tenant_8 instance failed: %v", err)
	}

	_, _, _ = runtime.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_7",
		InstanceID: instance7.InstanceID,
		Key:        "build_sha",
		Value:      "abc123",
		Visibility: InstanceMetadataVisibilityTenant,
	})
	_, _, _ = runtime.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_7",
		InstanceID: instance7.InstanceID,
		Key:        "internal_note",
		Value:      "secret",
		Visibility: InstanceMetadataVisibilityInternal,
	})
	_, _, _ = runtime.UpsertMetadata(InstanceMetadataUpsertRequest{
		TenantID:   "tenant_8",
		InstanceID: instance8.InstanceID,
		Key:        "build_sha",
		Value:      "def456",
		Visibility: InstanceMetadataVisibilityTenant,
	})

	tenantVisible, err := runtime.ListTenantVisibleMetadata("tenant_7")
	if err != nil {
		t.Fatalf("tenant visible list failed: %v", err)
	}
	if len(tenantVisible) != 1 {
		t.Fatalf("expected tenant visible count 1, got %d", len(tenantVisible))
	}
	if tenantVisible[0].TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7 metadata, got %s", tenantVisible[0].TenantID)
	}

	allForInstance, err := runtime.ListMetadataForInstance("tenant_7", instance7.InstanceID)
	if err != nil {
		t.Fatalf("list metadata for instance failed: %v", err)
	}
	if len(allForInstance) != 2 {
		t.Fatalf("expected all metadata count 2, got %d", len(allForInstance))
	}
}

func TestInstanceMetadataRuntimeListsTenantInstances(t *testing.T) {
	runtime := NewInstanceMetadataRuntime(DefaultInstanceMetadataRuntimeConfig())

	_, _, _ = runtime.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_7",
		ServiceName: "identity-api",
	})
	_, _, _ = runtime.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_7",
		ServiceName: "api-gateway",
	})
	_, _, _ = runtime.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:    "tenant_8",
		ServiceName: "identity-api",
	})

	tenant7, err := runtime.ListTenantInstances("tenant_7")
	if err != nil {
		t.Fatalf("list tenant_7 instances failed: %v", err)
	}
	if len(tenant7) != 2 {
		t.Fatalf("expected tenant_7 instance count 2, got %d", len(tenant7))
	}

	tenant8, err := runtime.ListTenantInstances("tenant_8")
	if err != nil {
		t.Fatalf("list tenant_8 instances failed: %v", err)
	}
	if len(tenant8) != 1 {
		t.Fatalf("expected tenant_8 instance count 1, got %d", len(tenant8))
	}
}

func TestInstanceMetadataRuntimeIDGenerators(t *testing.T) {
	serviceID := NewServiceInstanceServiceID()
	instanceID := NewServiceInstanceID()
	metadataID := NewInstanceMetadataID()

	if !strings.HasPrefix(serviceID, "svc_") {
		t.Fatalf("unexpected service id %s", serviceID)
	}
	if !strings.HasPrefix(instanceID, "instance_") {
		t.Fatalf("unexpected instance id %s", instanceID)
	}
	if !strings.HasPrefix(metadataID, "metadata_") {
		t.Fatalf("unexpected metadata id %s", metadataID)
	}
}
