package opsconsole

import (
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	ServiceRegistryScreenStatusHealthy     = "HEALTHY"
	ServiceRegistryScreenStatusDegraded    = "DEGRADED"
	ServiceRegistryScreenStatusDown        = "DOWN"
	ServiceRegistryScreenStatusMaintenance = "MAINTENANCE"

	ServiceRegistryScreenVisibilityTenant   = "TENANT"
	ServiceRegistryScreenVisibilityPlatform = "PLATFORM"
	ServiceRegistryScreenVisibilityInternal = "INTERNAL"

	ServiceRegistryScreenDecisionAllow = "ALLOW"
	ServiceRegistryScreenDecisionDeny  = "DENY"

	ServiceRegistryScreenReasonAllowed           = "SERVICE_REGISTRY_SCREEN_ALLOWED"
	ServiceRegistryScreenReasonMissingTenant     = "SERVICE_REGISTRY_SCREEN_MISSING_TENANT"
	ServiceRegistryScreenReasonCrossTenant       = "SERVICE_REGISTRY_SCREEN_CROSS_TENANT_DENIED"
	ServiceRegistryScreenReasonMissingServiceID  = "SERVICE_REGISTRY_SCREEN_MISSING_SERVICE_ID"
	ServiceRegistryScreenReasonMissingName       = "SERVICE_REGISTRY_SCREEN_MISSING_NAME"
	ServiceRegistryScreenReasonMissingInstanceID = "SERVICE_REGISTRY_SCREEN_MISSING_INSTANCE_ID"
	ServiceRegistryScreenReasonMissingAddress    = "SERVICE_REGISTRY_SCREEN_MISSING_ADDRESS"
	ServiceRegistryScreenReasonInvalidStatus     = "SERVICE_REGISTRY_SCREEN_INVALID_STATUS"
	ServiceRegistryScreenReasonInvalidVisibility = "SERVICE_REGISTRY_SCREEN_INVALID_VISIBILITY"
)

var (
	ErrServiceRegistryScreenMissingTenant     = errors.New("missing service registry screen tenant id")
	ErrServiceRegistryScreenCrossTenant       = errors.New("cross-tenant service registry screen access denied")
	ErrServiceRegistryScreenMissingServiceID  = errors.New("missing service id")
	ErrServiceRegistryScreenMissingName       = errors.New("missing service name")
	ErrServiceRegistryScreenMissingInstanceID = errors.New("missing instance id")
	ErrServiceRegistryScreenMissingAddress    = errors.New("missing service address")
	ErrServiceRegistryScreenInvalidStatus     = errors.New("invalid service registry screen status")
	ErrServiceRegistryScreenInvalidVisibility = errors.New("invalid service registry screen visibility")
)

type ServiceRegistryScreenConsoleConfig struct {
	RequireTenant       bool     `json:"require_tenant"`
	AllowPlatformViewer bool     `json:"allow_platform_viewer"`
	MaxVisibleServices  int      `json:"max_visible_services"`
	StaleAfterSeconds   int      `json:"stale_after_seconds"`
	AllowedStatuses     []string `json:"allowed_statuses"`
	AllowedVisibilities []string `json:"allowed_visibilities"`
}

func DefaultServiceRegistryScreenConsoleConfig() ServiceRegistryScreenConsoleConfig {
	return ServiceRegistryScreenConsoleConfig{
		RequireTenant:       true,
		AllowPlatformViewer: true,
		MaxVisibleServices:  100,
		StaleAfterSeconds:   120,
		AllowedStatuses: []string{
			ServiceRegistryScreenStatusHealthy,
			ServiceRegistryScreenStatusDegraded,
			ServiceRegistryScreenStatusDown,
			ServiceRegistryScreenStatusMaintenance,
		},
		AllowedVisibilities: []string{
			ServiceRegistryScreenVisibilityTenant,
			ServiceRegistryScreenVisibilityPlatform,
			ServiceRegistryScreenVisibilityInternal,
		},
	}
}

type ServiceRegistryScreenEntry struct {
	TenantID      string            `json:"tenant_id"`
	ServiceID     string            `json:"service_id"`
	InstanceID    string            `json:"instance_id"`
	Name          string            `json:"name"`
	Address       string            `json:"address"`
	Status        string            `json:"status"`
	Visibility    string            `json:"visibility"`
	Version       string            `json:"version,omitempty"`
	Region        string            `json:"region,omitempty"`
	Port          string            `json:"port,omitempty"`
	HealthPath    string            `json:"health_path,omitempty"`
	LastHeartbeat string            `json:"last_heartbeat"`
	CorrelationID string            `json:"correlation_id,omitempty"`
	Metadata      map[string]string `json:"metadata,omitempty"`
	RegisteredAt  string            `json:"registered_at"`
	UpdatedAt     string            `json:"updated_at"`
}

type ServiceRegistryScreenRequest struct {
	TenantID         string `json:"tenant_id"`
	ViewerTenantID   string `json:"viewer_tenant_id,omitempty"`
	StatusFilter     string `json:"status_filter,omitempty"`
	VisibilityFilter string `json:"visibility_filter,omitempty"`
	IncludeInternal  bool   `json:"include_internal"`
	CorrelationID    string `json:"correlation_id,omitempty"`
}

type ServiceRegistryScreenDecision struct {
	Decision         string `json:"decision"`
	Allowed          bool   `json:"allowed"`
	TenantID         string `json:"tenant_id"`
	ViewerTenantID   string `json:"viewer_tenant_id,omitempty"`
	StatusFilter     string `json:"status_filter,omitempty"`
	VisibilityFilter string `json:"visibility_filter,omitempty"`
	Reason           string `json:"reason"`
	CheckedAt        string `json:"checked_at"`
}

type ServiceRegistryScreenSnapshot struct {
	OK                   bool                         `json:"ok"`
	TenantID             string                       `json:"tenant_id"`
	ViewerTenantID       string                       `json:"viewer_tenant_id"`
	StatusFilter         string                       `json:"status_filter,omitempty"`
	VisibilityFilter     string                       `json:"visibility_filter,omitempty"`
	ServiceCount         int                          `json:"service_count"`
	HealthyCount         int                          `json:"healthy_count"`
	DegradedCount        int                          `json:"degraded_count"`
	DownCount            int                          `json:"down_count"`
	MaintenanceCount     int                          `json:"maintenance_count"`
	TenantVisibleCount   int                          `json:"tenant_visible_count"`
	PlatformVisibleCount int                          `json:"platform_visible_count"`
	InternalVisibleCount int                          `json:"internal_visible_count"`
	Services             []ServiceRegistryScreenEntry `json:"services"`
	CorrelationID        string                       `json:"correlation_id,omitempty"`
	GeneratedAt          string                       `json:"generated_at"`
}

type ServiceRegistryScreenConsoleRuntime struct {
	config   ServiceRegistryScreenConsoleConfig
	mu       sync.RWMutex
	services map[string]ServiceRegistryScreenEntry
}

func NewServiceRegistryScreenConsoleRuntime(config ServiceRegistryScreenConsoleConfig) *ServiceRegistryScreenConsoleRuntime {
	defaults := DefaultServiceRegistryScreenConsoleConfig()

	if config.MaxVisibleServices <= 0 {
		config.MaxVisibleServices = defaults.MaxVisibleServices
	}
	if config.StaleAfterSeconds <= 0 {
		config.StaleAfterSeconds = defaults.StaleAfterSeconds
	}
	if len(config.AllowedStatuses) == 0 {
		config.AllowedStatuses = defaults.AllowedStatuses
	}
	if len(config.AllowedVisibilities) == 0 {
		config.AllowedVisibilities = defaults.AllowedVisibilities
	}

	return &ServiceRegistryScreenConsoleRuntime{
		config:   config,
		services: make(map[string]ServiceRegistryScreenEntry),
	}
}

func (r *ServiceRegistryScreenConsoleRuntime) UpsertService(entry ServiceRegistryScreenEntry) (ServiceRegistryScreenEntry, ServiceRegistryScreenDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	entry.TenantID = strings.TrimSpace(entry.TenantID)
	entry.ServiceID = strings.TrimSpace(entry.ServiceID)
	entry.InstanceID = strings.TrimSpace(entry.InstanceID)
	entry.Name = strings.TrimSpace(entry.Name)
	entry.Address = strings.TrimSpace(entry.Address)
	entry.Status = normalizeOpsConsoleValue(entry.Status)
	entry.Visibility = normalizeOpsConsoleValue(entry.Visibility)

	decision := ServiceRegistryScreenDecision{
		Decision:  ServiceRegistryScreenDecisionDeny,
		Allowed:   false,
		TenantID:  entry.TenantID,
		Reason:    ServiceRegistryScreenReasonAllowed,
		CheckedAt: now,
	}

	if r.config.RequireTenant && entry.TenantID == "" {
		decision.Reason = ServiceRegistryScreenReasonMissingTenant
		return ServiceRegistryScreenEntry{}, decision, ErrServiceRegistryScreenMissingTenant
	}
	if entry.ServiceID == "" {
		decision.Reason = ServiceRegistryScreenReasonMissingServiceID
		return ServiceRegistryScreenEntry{}, decision, ErrServiceRegistryScreenMissingServiceID
	}
	if entry.InstanceID == "" {
		decision.Reason = ServiceRegistryScreenReasonMissingInstanceID
		return ServiceRegistryScreenEntry{}, decision, ErrServiceRegistryScreenMissingInstanceID
	}
	if entry.Name == "" {
		decision.Reason = ServiceRegistryScreenReasonMissingName
		return ServiceRegistryScreenEntry{}, decision, ErrServiceRegistryScreenMissingName
	}
	if entry.Address == "" {
		decision.Reason = ServiceRegistryScreenReasonMissingAddress
		return ServiceRegistryScreenEntry{}, decision, ErrServiceRegistryScreenMissingAddress
	}
	if entry.Status == "" || !r.statusAllowed(entry.Status) {
		decision.Reason = ServiceRegistryScreenReasonInvalidStatus
		return ServiceRegistryScreenEntry{}, decision, ErrServiceRegistryScreenInvalidStatus
	}
	if entry.Visibility == "" || !r.visibilityAllowed(entry.Visibility) {
		decision.Reason = ServiceRegistryScreenReasonInvalidVisibility
		return ServiceRegistryScreenEntry{}, decision, ErrServiceRegistryScreenInvalidVisibility
	}

	if entry.LastHeartbeat == "" {
		entry.LastHeartbeat = now
	}
	if entry.RegisteredAt == "" {
		entry.RegisteredAt = now
	}
	entry.UpdatedAt = now
	entry.Metadata = cloneOpsConsoleMap(entry.Metadata)

	r.mu.Lock()
	r.services[serviceRegistryScreenKey(entry.TenantID, entry.ServiceID, entry.InstanceID)] = entry
	r.mu.Unlock()

	decision.Decision = ServiceRegistryScreenDecisionAllow
	decision.Allowed = true
	decision.Reason = ServiceRegistryScreenReasonAllowed

	return entry, decision, nil
}

func (r *ServiceRegistryScreenConsoleRuntime) BuildSnapshot(req ServiceRegistryScreenRequest) (ServiceRegistryScreenSnapshot, ServiceRegistryScreenDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	viewerTenantID := strings.TrimSpace(req.ViewerTenantID)
	statusFilter := normalizeOpsConsoleValue(req.StatusFilter)
	visibilityFilter := normalizeOpsConsoleValue(req.VisibilityFilter)

	if viewerTenantID == "" {
		viewerTenantID = tenantID
	}

	decision := ServiceRegistryScreenDecision{
		Decision:         ServiceRegistryScreenDecisionDeny,
		Allowed:          false,
		TenantID:         tenantID,
		ViewerTenantID:   viewerTenantID,
		StatusFilter:     statusFilter,
		VisibilityFilter: visibilityFilter,
		Reason:           ServiceRegistryScreenReasonAllowed,
		CheckedAt:        now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = ServiceRegistryScreenReasonMissingTenant
		return ServiceRegistryScreenSnapshot{}, decision, ErrServiceRegistryScreenMissingTenant
	}
	if viewerTenantID != tenantID && !(r.config.AllowPlatformViewer && viewerTenantID == "platform") {
		decision.Reason = ServiceRegistryScreenReasonCrossTenant
		return ServiceRegistryScreenSnapshot{}, decision, ErrServiceRegistryScreenCrossTenant
	}
	if statusFilter != "" && !r.statusAllowed(statusFilter) {
		decision.Reason = ServiceRegistryScreenReasonInvalidStatus
		return ServiceRegistryScreenSnapshot{}, decision, ErrServiceRegistryScreenInvalidStatus
	}
	if visibilityFilter != "" && !r.visibilityAllowed(visibilityFilter) {
		decision.Reason = ServiceRegistryScreenReasonInvalidVisibility
		return ServiceRegistryScreenSnapshot{}, decision, ErrServiceRegistryScreenInvalidVisibility
	}

	snapshot := ServiceRegistryScreenSnapshot{
		OK:               true,
		TenantID:         tenantID,
		ViewerTenantID:   viewerTenantID,
		StatusFilter:     statusFilter,
		VisibilityFilter: visibilityFilter,
		CorrelationID:    strings.TrimSpace(req.CorrelationID),
		GeneratedAt:      now,
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	for _, service := range r.services {
		if service.TenantID != tenantID {
			continue
		}

		serviceForSnapshot := service
		serviceForSnapshot.Status = r.effectiveStatus(service)

		if !r.visibleToViewer(serviceForSnapshot, tenantID, viewerTenantID, req.IncludeInternal) {
			continue
		}
		if statusFilter != "" && serviceForSnapshot.Status != statusFilter {
			continue
		}
		if visibilityFilter != "" && serviceForSnapshot.Visibility != visibilityFilter {
			continue
		}
		if snapshot.ServiceCount >= r.config.MaxVisibleServices {
			continue
		}

		snapshot.Services = append(snapshot.Services, serviceForSnapshot)
		snapshot.ServiceCount++

		switch serviceForSnapshot.Status {
		case ServiceRegistryScreenStatusHealthy:
			snapshot.HealthyCount++
		case ServiceRegistryScreenStatusDegraded:
			snapshot.DegradedCount++
		case ServiceRegistryScreenStatusDown:
			snapshot.DownCount++
		case ServiceRegistryScreenStatusMaintenance:
			snapshot.MaintenanceCount++
		}

		switch serviceForSnapshot.Visibility {
		case ServiceRegistryScreenVisibilityTenant:
			snapshot.TenantVisibleCount++
		case ServiceRegistryScreenVisibilityPlatform:
			snapshot.PlatformVisibleCount++
		case ServiceRegistryScreenVisibilityInternal:
			snapshot.InternalVisibleCount++
		}
	}

	decision.Decision = ServiceRegistryScreenDecisionAllow
	decision.Allowed = true
	decision.Reason = ServiceRegistryScreenReasonAllowed

	return snapshot, decision, nil
}

func (r *ServiceRegistryScreenConsoleRuntime) effectiveStatus(service ServiceRegistryScreenEntry) string {
	if service.Status == ServiceRegistryScreenStatusDown || service.Status == ServiceRegistryScreenStatusMaintenance {
		return service.Status
	}
	if isServiceRegistryHeartbeatStale(service.LastHeartbeat, r.config.StaleAfterSeconds) {
		return ServiceRegistryScreenStatusDegraded
	}
	return service.Status
}

func (r *ServiceRegistryScreenConsoleRuntime) visibleToViewer(service ServiceRegistryScreenEntry, tenantID string, viewerTenantID string, includeInternal bool) bool {
	if viewerTenantID == "platform" {
		if service.Visibility == ServiceRegistryScreenVisibilityInternal {
			return includeInternal
		}
		return true
	}
	if viewerTenantID != tenantID {
		return false
	}
	if service.Visibility == ServiceRegistryScreenVisibilityInternal {
		return false
	}
	return true
}

func (r *ServiceRegistryScreenConsoleRuntime) statusAllowed(status string) bool {
	status = normalizeOpsConsoleValue(status)
	for _, allowed := range r.config.AllowedStatuses {
		if normalizeOpsConsoleValue(allowed) == status {
			return true
		}
	}
	return false
}

func (r *ServiceRegistryScreenConsoleRuntime) visibilityAllowed(visibility string) bool {
	visibility = normalizeOpsConsoleValue(visibility)
	for _, allowed := range r.config.AllowedVisibilities {
		if normalizeOpsConsoleValue(allowed) == visibility {
			return true
		}
	}
	return false
}

func isServiceRegistryHeartbeatStale(lastHeartbeat string, staleAfterSeconds int) bool {
	if strings.TrimSpace(lastHeartbeat) == "" {
		return true
	}
	parsed, err := time.Parse(time.RFC3339Nano, strings.TrimSpace(lastHeartbeat))
	if err != nil {
		return true
	}
	if staleAfterSeconds <= 0 {
		staleAfterSeconds = 120
	}
	return time.Since(parsed.UTC()) > time.Duration(staleAfterSeconds)*time.Second
}

func serviceRegistryScreenKey(tenantID string, serviceID string, instanceID string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(serviceID) + "::" + strings.TrimSpace(instanceID)
}
