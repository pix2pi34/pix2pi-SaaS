package serviceregistry

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"sync"
	"testing"
	"time"
)

type integrationServiceRecord struct {
	ServiceID       string
	TenantID        string
	ServiceKey      string
	DisplayName     string
	ServiceKind     string
	VisibilityScope string
	Protocol        string
	BasePath        string
	HealthPath      string
	DefaultPort     int
	OwnerTeam       string
	Metadata        map[string]any
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type integrationInstanceRecord struct {
	InstanceID                string
	ServiceID                 string
	TenantID                  string
	InstanceKey               string
	NodeName                  string
	Host                      string
	Port                      int
	Version                   string
	Status                    string
	HeartbeatIntervalSeconds  int
	Metadata                  map[string]any
	LastHeartbeatAt           time.Time
	LastHealthAt              time.Time
	CreatedAt                 time.Time
	UpdatedAt                 time.Time
}

type registryRuntimeIntegrationStore struct {
	mu        sync.Mutex
	nowFn     func() time.Time
	serviceNo int
	instanceNo int

	services  map[string]*integrationServiceRecord
	instances map[string]*integrationInstanceRecord
}

func newRegistryRuntimeIntegrationStore() *registryRuntimeIntegrationStore {
	return &registryRuntimeIntegrationStore{
		nowFn: func() time.Time {
			return time.Now().UTC()
		},
		services:  make(map[string]*integrationServiceRecord),
		instances: make(map[string]*integrationInstanceRecord),
	}
}

func (s *registryRuntimeIntegrationStore) UpsertServiceInstance(_ context.Context, cmd UpsertServiceInstanceCommand) (UpsertServiceInstanceResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := s.nowFn()
	tenantID := strings.TrimSpace(cmd.TenantID)
	serviceKey := strings.TrimSpace(cmd.ServiceKey)
	instanceKey := strings.TrimSpace(cmd.InstanceKey)

	serviceCompositeKey := buildServiceCompositeKey(tenantID, serviceKey)
	service, ok := s.services[serviceCompositeKey]
	if !ok {
		s.serviceNo++
		service = &integrationServiceRecord{
			ServiceID: fmt.Sprintf("svc-%03d", s.serviceNo),
			CreatedAt: now,
		}
		s.services[serviceCompositeKey] = service
	}

	service.TenantID = tenantID
	service.ServiceKey = serviceKey
	service.DisplayName = strings.TrimSpace(cmd.DisplayName)
	service.ServiceKind = strings.TrimSpace(cmd.ServiceKind)
	service.VisibilityScope = strings.TrimSpace(cmd.VisibilityScope)
	service.Protocol = strings.TrimSpace(cmd.Protocol)
	service.BasePath = strings.TrimSpace(cmd.BasePath)
	service.HealthPath = strings.TrimSpace(cmd.HealthPath)
	service.DefaultPort = cmd.DefaultPort
	service.OwnerTeam = strings.TrimSpace(cmd.OwnerTeam)
	service.Metadata = cloneMap(cmd.ServiceMetadata)
	service.UpdatedAt = now

	instanceCompositeKey := buildInstanceCompositeKey(service.ServiceID, instanceKey)
	instance, ok := s.instances[instanceCompositeKey]
	if !ok {
		s.instanceNo++
		instance = &integrationInstanceRecord{
			InstanceID: fmt.Sprintf("ins-%03d", s.instanceNo),
			ServiceID:  service.ServiceID,
			CreatedAt:  now,
		}
		s.instances[instanceCompositeKey] = instance
	}

	instance.TenantID = tenantID
	instance.InstanceKey = instanceKey
	instance.NodeName = strings.TrimSpace(cmd.NodeName)
	instance.Host = strings.TrimSpace(cmd.Host)
	instance.Port = cmd.Port
	instance.Version = strings.TrimSpace(cmd.Version)
	instance.Status = strings.TrimSpace(cmd.Status)
	instance.HeartbeatIntervalSeconds = cmd.HeartbeatIntervalSeconds
	instance.Metadata = cloneMap(cmd.InstanceMetadata)
	instance.LastHeartbeatAt = now
	instance.LastHealthAt = now
	instance.UpdatedAt = now

	return UpsertServiceInstanceResult{
		ServiceID:   service.ServiceID,
		InstanceID:  instance.InstanceID,
		ServiceKey:  service.ServiceKey,
		InstanceKey: instance.InstanceKey,
	}, nil
}

func (s *registryRuntimeIntegrationStore) RecordHeartbeat(_ context.Context, cmd RecordHeartbeatCommand) (RecordHeartbeatResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	serviceCompositeKey := buildServiceCompositeKey(strings.TrimSpace(cmd.TenantID), strings.TrimSpace(cmd.ServiceKey))
	service, ok := s.services[serviceCompositeKey]
	if !ok {
		return RecordHeartbeatResult{}, fmt.Errorf("service not found: %s", cmd.ServiceKey)
	}

	instanceCompositeKey := buildInstanceCompositeKey(service.ServiceID, strings.TrimSpace(cmd.InstanceKey))
	instance, ok := s.instances[instanceCompositeKey]
	if !ok {
		return RecordHeartbeatResult{}, fmt.Errorf("instance not found: %s", cmd.InstanceKey)
	}

	now := s.nowFn()
	instance.Status = strings.TrimSpace(cmd.Status)
	instance.HeartbeatIntervalSeconds = cmd.HeartbeatIntervalSeconds
	instance.Metadata = cloneMap(cmd.Metadata)
	instance.LastHeartbeatAt = now
	instance.LastHealthAt = now
	instance.UpdatedAt = now

	healthPullRequested := false
	if cmd.ResponseTimeMS >= 5000 {
		healthPullRequested = true
	}

	return RecordHeartbeatResult{
		NextHeartbeatInSeconds: cmd.HeartbeatIntervalSeconds,
		HealthPullRequested:    healthPullRequested,
	}, nil
}

func (s *registryRuntimeIntegrationStore) CleanupStaleInstances(_ context.Context, cmd CleanupStaleInstancesCommand) (CleanupStaleInstancesResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	cleaned := 0
	targetTenantID := strings.TrimSpace(cmd.TenantID)

	keys := make([]string, 0, len(s.instances))
	for k := range s.instances {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	for _, key := range keys {
		instance := s.instances[key]

		if targetTenantID != "" && instance.TenantID != targetTenantID {
			continue
		}

		if instance.Status == cmd.TargetStatus {
			continue
		}

		if !instance.LastHeartbeatAt.Before(cmd.ThresholdTime) {
			continue
		}

		cleaned++
		if !cmd.DryRun {
			instance.Status = cmd.TargetStatus
			instance.UpdatedAt = s.nowFn()
		}

		if cleaned >= cmd.Limit {
			break
		}
	}

	return CleanupStaleInstancesResult{
		CleanedCount: cleaned,
	}, nil
}

func (s *registryRuntimeIntegrationStore) ListVisibleServiceInstances(_ context.Context, cmd ListVisibleServicesCommand) ([]VisibleServiceInstance, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	items := make([]VisibleServiceInstance, 0)
	tenantID := strings.TrimSpace(cmd.TenantID)
	prefix := strings.TrimSpace(cmd.ServiceKeyPrefix)
	status := strings.TrimSpace(cmd.InstanceStatus)

	for _, service := range s.services {
		for _, instance := range s.instances {
			if instance.ServiceID != service.ServiceID {
				continue
			}

			visible := false
			if tenantID != "" && instance.TenantID == tenantID {
				visible = true
			}
			if cmd.IncludeGlobal && service.VisibilityScope == "global" {
				visible = true
			}
			if !visible {
				continue
			}

			if prefix != "" && !strings.HasPrefix(service.ServiceKey, prefix) {
				continue
			}

			if status != "" && instance.Status != status {
				continue
			}

			items = append(items, VisibleServiceInstance{
				ServiceID:       service.ServiceID,
				InstanceID:      instance.InstanceID,
				TenantID:        instance.TenantID,
				ServiceKey:      service.ServiceKey,
				DisplayName:     service.DisplayName,
				ServiceKind:     service.ServiceKind,
				VisibilityScope: service.VisibilityScope,
				InstanceKey:     instance.InstanceKey,
				InstanceStatus:  instance.Status,
				Host:            instance.Host,
				Port:            instance.Port,
				Version:         instance.Version,
				LastHeartbeatAt: instance.LastHeartbeatAt,
			})
		}
	}

	sort.Slice(items, func(i, j int) bool {
		if items[i].ServiceKey == items[j].ServiceKey {
			return items[i].InstanceKey < items[j].InstanceKey
		}
		return items[i].ServiceKey < items[j].ServiceKey
	})

	if cmd.Limit > 0 && len(items) > cmd.Limit {
		items = items[:cmd.Limit]
	}

	return items, nil
}

func (s *registryRuntimeIntegrationStore) forceLastHeartbeat(tenantID, serviceKey, instanceKey string, at time.Time) {
	s.mu.Lock()
	defer s.mu.Unlock()

	serviceCompositeKey := buildServiceCompositeKey(strings.TrimSpace(tenantID), strings.TrimSpace(serviceKey))
	service, ok := s.services[serviceCompositeKey]
	if !ok {
		return
	}

	instanceCompositeKey := buildInstanceCompositeKey(service.ServiceID, strings.TrimSpace(instanceKey))
	instance, ok := s.instances[instanceCompositeKey]
	if !ok {
		return
	}

	instance.LastHeartbeatAt = at.UTC()
	instance.LastHealthAt = at.UTC()
}

func buildServiceCompositeKey(tenantID, serviceKey string) string {
	return tenantID + "|" + serviceKey
}

func buildInstanceCompositeKey(serviceID, instanceKey string) string {
	return serviceID + "|" + instanceKey
}

func TestRegistryRuntimeIntegration_RegisterHeartbeatVisibilityFlow(t *testing.T) {
	store := newRegistryRuntimeIntegrationStore()
	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 24, 18, 0, 0, 0, time.UTC)
	}

	registerUsecase := NewRegisterServiceUsecase(store)
	heartbeatUsecase := NewHeartbeatUsecase(store)
	visibilityUsecase := NewVisibilityUsecase(store)

	_, err := registerUsecase.Register(context.Background(), RegisterServiceRequest{
		TenantID:                 "tenant-a",
		ServiceKey:               "identity-api",
		DisplayName:              "Identity API",
		ServiceKind:              "api",
		VisibilityScope:          "tenant",
		Protocol:                 "http",
		BasePath:                 "/api/v1",
		HealthPath:               "/health",
		DefaultPort:              9001,
		OwnerTeam:                "identity",
		InstanceKey:              "identity-api-01",
		NodeName:                 "node-a",
		Host:                     "10.10.10.11",
		Port:                     9001,
		Version:                  "1.0.0",
		Status:                   "starting",
		HeartbeatIntervalSeconds: 30,
		Metadata: map[string]any{
			"region": "eu",
		},
		InstanceMetadata: map[string]any{
			"zone": "az-1",
		},
	})
	if err != nil {
		t.Fatalf("register hatasi: %v", err)
	}

	_, err = heartbeatUsecase.Accept(context.Background(), HeartbeatRequest{
		TenantID:                 "tenant-a",
		ServiceKey:               "identity-api",
		InstanceKey:              "identity-api-01",
		Status:                   "healthy",
		Mode:                     "push",
		ResponseTimeMS:           23,
		HeartbeatIntervalSeconds: 30,
		Metadata: map[string]any{
			"cpu": "low",
		},
	})
	if err != nil {
		t.Fatalf("heartbeat hatasi: %v", err)
	}

	resp, err := visibilityUsecase.List(context.Background(), ListVisibleServicesRequest{
		TenantID:       "tenant-a",
		IncludeGlobal:  false,
		InstanceStatus: "healthy",
		Limit:          50,
	})
	if err != nil {
		t.Fatalf("visibility hatasi: %v", err)
	}

	if resp.Count != 1 {
		t.Fatalf("beklenen 1 gorunur servis, alinan: %d", resp.Count)
	}

	item := resp.Items[0]
	if item.ServiceKey != "identity-api" {
		t.Fatalf("beklenen identity-api, alinan: %s", item.ServiceKey)
	}

	if item.InstanceStatus != "healthy" {
		t.Fatalf("beklenen healthy, alinan: %s", item.InstanceStatus)
	}

	if item.Version != "1.0.0" {
		t.Fatalf("beklenen version 1.0.0, alinan: %s", item.Version)
	}
}

func TestRegistryRuntimeIntegration_TenantIsolationWithGlobalVisibility(t *testing.T) {
	store := newRegistryRuntimeIntegrationStore()

	registerUsecase := NewRegisterServiceUsecase(store)
	visibilityUsecase := NewVisibilityUsecase(store)

	registrations := []RegisterServiceRequest{
		{
			ServiceKey:               "gateway-public",
			DisplayName:              "Gateway Public",
			ServiceKind:              "gateway",
			VisibilityScope:          "global",
			Protocol:                 "https",
			BasePath:                 "/",
			HealthPath:               "/health",
			DefaultPort:              9010,
			InstanceKey:              "gateway-public-01",
			NodeName:                 "node-g",
			Host:                     "10.10.10.20",
			Port:                     9010,
			Version:                  "1.0.0",
			Status:                   "healthy",
			HeartbeatIntervalSeconds: 30,
		},
		{
			TenantID:                 "tenant-a",
			ServiceKey:               "identity-api",
			DisplayName:              "Identity API",
			ServiceKind:              "api",
			VisibilityScope:          "tenant",
			Protocol:                 "http",
			BasePath:                 "/api/v1",
			HealthPath:               "/health",
			DefaultPort:              9001,
			InstanceKey:              "identity-api-01",
			NodeName:                 "node-a",
			Host:                     "10.10.10.11",
			Port:                     9001,
			Version:                  "1.0.0",
			Status:                   "healthy",
			HeartbeatIntervalSeconds: 30,
		},
		{
			TenantID:                 "tenant-b",
			ServiceKey:               "erp-core",
			DisplayName:              "ERP Core",
			ServiceKind:              "api",
			VisibilityScope:          "tenant",
			Protocol:                 "http",
			BasePath:                 "/api/v1",
			HealthPath:               "/health",
			DefaultPort:              9030,
			InstanceKey:              "erp-core-01",
			NodeName:                 "node-b",
			Host:                     "10.10.10.12",
			Port:                     9030,
			Version:                  "1.0.0",
			Status:                   "healthy",
			HeartbeatIntervalSeconds: 30,
		},
	}

	for _, req := range registrations {
		if _, err := registerUsecase.Register(context.Background(), req); err != nil {
			t.Fatalf("register hatasi: %v", err)
		}
	}

	tenantAResp, err := visibilityUsecase.List(context.Background(), ListVisibleServicesRequest{
		TenantID:      "tenant-a",
		IncludeGlobal: true,
		Limit:         50,
	})
	if err != nil {
		t.Fatalf("tenant-a visibility hatasi: %v", err)
	}

	if tenantAResp.Count != 2 {
		t.Fatalf("tenant-a icin beklenen 2 kayit, alinan: %d", tenantAResp.Count)
	}

	for _, item := range tenantAResp.Items {
		if item.ServiceKey == "erp-core" {
			t.Fatalf("tenant-a, tenant-b servisini gormemeli")
		}
	}

	tenantBResp, err := visibilityUsecase.List(context.Background(), ListVisibleServicesRequest{
		TenantID:      "tenant-b",
		IncludeGlobal: false,
		Limit:         50,
	})
	if err != nil {
		t.Fatalf("tenant-b visibility hatasi: %v", err)
	}

	if tenantBResp.Count != 1 {
		t.Fatalf("tenant-b icin beklenen 1 kayit, alinan: %d", tenantBResp.Count)
	}

	if tenantBResp.Items[0].ServiceKey != "erp-core" {
		t.Fatalf("tenant-b icin beklenen erp-core, alinan: %s", tenantBResp.Items[0].ServiceKey)
	}
}

func TestRegistryRuntimeIntegration_StaleCleanupFlow(t *testing.T) {
	store := newRegistryRuntimeIntegrationStore()
	registerUsecase := NewRegisterServiceUsecase(store)
	cleanupUsecase := NewStaleInstanceCleanupUsecase(store)
	visibilityUsecase := NewVisibilityUsecase(store)

	if _, err := registerUsecase.Register(context.Background(), RegisterServiceRequest{
		TenantID:                 "tenant-a",
		ServiceKey:               "identity-api",
		DisplayName:              "Identity API",
		ServiceKind:              "api",
		VisibilityScope:          "tenant",
		Protocol:                 "http",
		BasePath:                 "/api/v1",
		HealthPath:               "/health",
		DefaultPort:              9001,
		InstanceKey:              "identity-api-01",
		NodeName:                 "node-a",
		Host:                     "10.10.10.11",
		Port:                     9001,
		Version:                  "1.0.0",
		Status:                   "healthy",
		HeartbeatIntervalSeconds: 30,
	}); err != nil {
		t.Fatalf("register hatasi: %v", err)
	}

	now := time.Date(2026, 4, 24, 19, 0, 0, 0, time.UTC)
	store.nowFn = func() time.Time { return now }
	store.forceLastHeartbeat("tenant-a", "identity-api", "identity-api-01", now.Add(-10*time.Minute))

	cleanupUsecase.nowFn = func() time.Time { return now }

	dryRunResp, err := cleanupUsecase.Run(context.Background(), CleanupStaleInstancesRequest{
		TenantID:           "tenant-a",
		GracePeriodSeconds: 300,
		Limit:              100,
		TargetStatus:       "stopped",
		DryRun:             true,
	})
	if err != nil {
		t.Fatalf("dry-run cleanup hatasi: %v", err)
	}

	if dryRunResp.CleanedCount != 1 {
		t.Fatalf("dry-run icin beklenen cleaned_count 1, alinan: %d", dryRunResp.CleanedCount)
	}

	healthyResp, err := visibilityUsecase.List(context.Background(), ListVisibleServicesRequest{
		TenantID:       "tenant-a",
		IncludeGlobal:  false,
		InstanceStatus: "healthy",
		Limit:          50,
	})
	if err != nil {
		t.Fatalf("dry-run visibility hatasi: %v", err)
	}

	if healthyResp.Count != 1 {
		t.Fatalf("dry-run sonrasi instance hala healthy olmaliydi")
	}

	realResp, err := cleanupUsecase.Run(context.Background(), CleanupStaleInstancesRequest{
		TenantID:           "tenant-a",
		GracePeriodSeconds: 300,
		Limit:              100,
		TargetStatus:       "stopped",
		DryRun:             false,
	})
	if err != nil {
		t.Fatalf("real cleanup hatasi: %v", err)
	}

	if realResp.CleanedCount != 1 {
		t.Fatalf("real cleanup icin beklenen cleaned_count 1, alinan: %d", realResp.CleanedCount)
	}

	stoppedResp, err := visibilityUsecase.List(context.Background(), ListVisibleServicesRequest{
		TenantID:       "tenant-a",
		IncludeGlobal:  false,
		InstanceStatus: "stopped",
		Limit:          50,
	})
	if err != nil {
		t.Fatalf("stopped visibility hatasi: %v", err)
	}

	if stoppedResp.Count != 1 {
		t.Fatalf("cleanup sonrasi instance stopped gorunmeli")
	}

	if stoppedResp.Items[0].InstanceStatus != "stopped" {
		t.Fatalf("beklenen stopped, alinan: %s", stoppedResp.Items[0].InstanceStatus)
	}
}
