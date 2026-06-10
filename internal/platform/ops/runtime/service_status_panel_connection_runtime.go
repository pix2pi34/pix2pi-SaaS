package opsruntime

import (
	"errors"
	"strings"
	"time"
)

const (
	ServiceStatusPanelDecisionAllow = "ALLOW"
	ServiceStatusPanelDecisionDeny  = "DENY"

	ServiceStatusPanelReasonAllowed           = "SERVICE_STATUS_PANEL_ALLOWED"
	ServiceStatusPanelReasonMissingTenant     = "SERVICE_STATUS_PANEL_MISSING_TENANT"
	ServiceStatusPanelReasonMissingRegistry   = "SERVICE_STATUS_PANEL_MISSING_REGISTRY"
	ServiceStatusPanelReasonMissingVisibility = "SERVICE_STATUS_PANEL_MISSING_VISIBILITY"
	ServiceStatusPanelReasonInvalidScope      = "SERVICE_STATUS_PANEL_INVALID_SCOPE"
	ServiceStatusPanelReasonCrossTenant       = "SERVICE_STATUS_PANEL_CROSS_TENANT_DENIED"
	ServiceStatusPanelReasonVisibilityFailed  = "SERVICE_STATUS_PANEL_VISIBILITY_FAILED"
	ServiceStatusPanelReasonStaleBridgeFailed = "SERVICE_STATUS_PANEL_STALE_BRIDGE_FAILED"
)

var (
	ErrServiceStatusPanelMissingTenant     = errors.New("missing service status panel tenant id")
	ErrServiceStatusPanelMissingRegistry   = errors.New("missing service status panel registry")
	ErrServiceStatusPanelMissingVisibility = errors.New("missing service status panel visibility runtime")
	ErrServiceStatusPanelInvalidScope      = errors.New("invalid service status panel scope")
	ErrServiceStatusPanelCrossTenant       = errors.New("cross-tenant service status panel access denied")
	ErrServiceStatusPanelVisibilityFailed  = errors.New("service status panel visibility failed")
	ErrServiceStatusPanelStaleBridgeFailed = errors.New("service status panel stale bridge failed")
)

type ServiceStatusPanelConnectionRuntimeConfig struct {
	RequireTenant             bool   `json:"require_tenant"`
	DefaultScope              string `json:"default_scope"`
	EnableStaleBridge         bool   `json:"enable_stale_bridge"`
	IncludeMetadataSummary    bool   `json:"include_metadata_summary"`
	IncludeMissionControlTags bool   `json:"include_mission_control_tags"`
}

func DefaultServiceStatusPanelConnectionRuntimeConfig() ServiceStatusPanelConnectionRuntimeConfig {
	return ServiceStatusPanelConnectionRuntimeConfig{
		RequireTenant:             true,
		DefaultScope:              RegistryVisibilityScopeInternal,
		EnableStaleBridge:         true,
		IncludeMetadataSummary:    true,
		IncludeMissionControlTags: true,
	}
}

type ServiceStatusPanelRequest struct {
	TenantID       string `json:"tenant_id"`
	ViewerTenantID string `json:"viewer_tenant_id,omitempty"`
	Scope          string `json:"scope,omitempty"`
	CorrelationID  string `json:"correlation_id,omitempty"`
}

type ServiceStatusPanelEntry struct {
	TenantID               string            `json:"tenant_id"`
	ServiceID              string            `json:"service_id"`
	InstanceID             string            `json:"instance_id"`
	ServiceName            string            `json:"service_name"`
	Status                 string            `json:"status"`
	Host                   string            `json:"host,omitempty"`
	Port                   int               `json:"port,omitempty"`
	Zone                   string            `json:"zone,omitempty"`
	NodeID                 string            `json:"node_id,omitempty"`
	Runtime                string            `json:"runtime,omitempty"`
	Version                string            `json:"version,omitempty"`
	LastSeenAt             string            `json:"last_seen_at,omitempty"`
	HealthStatus           string            `json:"health_status,omitempty"`
	MetadataCount          int               `json:"metadata_count"`
	MetadataSummary        map[string]string `json:"metadata_summary,omitempty"`
	RestartActionID        string            `json:"restart_action_id,omitempty"`
	IsolateQuarantineState string            `json:"isolate_quarantine_state,omitempty"`
	MaintenanceModeState   string            `json:"maintenance_mode_state,omitempty"`
	IncidentActionLogID    string            `json:"incident_action_log_id,omitempty"`
	PanelTags              []string          `json:"panel_tags,omitempty"`
}

type ServiceStatusPanelSnapshot struct {
	OK                    bool                      `json:"ok"`
	TenantID              string                    `json:"tenant_id"`
	ViewerTenantID        string                    `json:"viewer_tenant_id"`
	Scope                 string                    `json:"scope"`
	EntryCount            int                       `json:"entry_count"`
	HealthyCount          int                       `json:"healthy_count"`
	UnhealthyCount        int                       `json:"unhealthy_count"`
	StaleCount            int                       `json:"stale_count"`
	RestartRequestedCount int                       `json:"restart_requested_count"`
	QuarantineCount       int                       `json:"quarantine_count"`
	IsolateCount          int                       `json:"isolate_count"`
	MaintenanceCount      int                       `json:"maintenance_count"`
	IncidentTaggedCount   int                       `json:"incident_tagged_count"`
	StaleCandidateCount   int                       `json:"stale_candidate_count"`
	Entries               []ServiceStatusPanelEntry `json:"entries"`
	CorrelationID         string                    `json:"correlation_id,omitempty"`
	GeneratedAt           string                    `json:"generated_at"`
}

type ServiceStatusPanelDecision struct {
	Decision            string `json:"decision"`
	Allowed             bool   `json:"allowed"`
	TenantID            string `json:"tenant_id"`
	ViewerTenantID      string `json:"viewer_tenant_id,omitempty"`
	Scope               string `json:"scope,omitempty"`
	EntryCount          int    `json:"entry_count"`
	StaleCandidateCount int    `json:"stale_candidate_count"`
	CorrelationID       string `json:"correlation_id,omitempty"`
	Reason              string `json:"reason"`
	CheckedAt           string `json:"checked_at"`
}

type ServiceStatusPanelConnectionRuntime struct {
	config     ServiceStatusPanelConnectionRuntimeConfig
	registry   *InstanceMetadataRuntime
	visibility *RegistryVisibilityRuntime
	cleanup    *StaleInstanceCleanupRuntime
}

func NewServiceStatusPanelConnectionRuntime(config ServiceStatusPanelConnectionRuntimeConfig, registry *InstanceMetadataRuntime, visibility *RegistryVisibilityRuntime, cleanup *StaleInstanceCleanupRuntime) *ServiceStatusPanelConnectionRuntime {
	defaults := DefaultServiceStatusPanelConnectionRuntimeConfig()

	if strings.TrimSpace(config.DefaultScope) == "" {
		config.DefaultScope = defaults.DefaultScope
	}

	return &ServiceStatusPanelConnectionRuntime{
		config:     config,
		registry:   registry,
		visibility: visibility,
		cleanup:    cleanup,
	}
}

func (r *ServiceStatusPanelConnectionRuntime) BuildPanelSnapshot(req ServiceStatusPanelRequest) (ServiceStatusPanelSnapshot, ServiceStatusPanelDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	viewerTenantID := strings.TrimSpace(req.ViewerTenantID)
	scope := normalizeRegistryVisibilityScope(req.Scope)
	if strings.TrimSpace(req.Scope) == "" {
		scope = normalizeRegistryVisibilityScope(r.config.DefaultScope)
	}
	if viewerTenantID == "" {
		viewerTenantID = tenantID
	}

	decision := ServiceStatusPanelDecision{
		Decision:       ServiceStatusPanelDecisionDeny,
		Allowed:        false,
		TenantID:       tenantID,
		ViewerTenantID: viewerTenantID,
		Scope:          scope,
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		Reason:         ServiceStatusPanelReasonAllowed,
		CheckedAt:      now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = ServiceStatusPanelReasonMissingTenant
		return ServiceStatusPanelSnapshot{}, decision, ErrServiceStatusPanelMissingTenant
	}

	if r.registry == nil {
		decision.Reason = ServiceStatusPanelReasonMissingRegistry
		return ServiceStatusPanelSnapshot{}, decision, ErrServiceStatusPanelMissingRegistry
	}

	if r.visibility == nil {
		decision.Reason = ServiceStatusPanelReasonMissingVisibility
		return ServiceStatusPanelSnapshot{}, decision, ErrServiceStatusPanelMissingVisibility
	}

	if !isServiceStatusPanelScopeValid(scope) {
		decision.Reason = ServiceStatusPanelReasonInvalidScope
		return ServiceStatusPanelSnapshot{}, decision, ErrServiceStatusPanelInvalidScope
	}

	visibilityResult, visibilityDecision, err := r.visibility.ListVisibleRegistry(RegistryVisibilityRequest{
		TenantID:       tenantID,
		ViewerTenantID: viewerTenantID,
		Scope:          scope,
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
	})
	if err != nil || !visibilityDecision.Allowed {
		if errors.Is(err, ErrRegistryVisibilityCrossTenantDenied) {
			decision.Reason = ServiceStatusPanelReasonCrossTenant
			return ServiceStatusPanelSnapshot{}, decision, ErrServiceStatusPanelCrossTenant
		}
		if errors.Is(err, ErrRegistryVisibilityInvalidScope) {
			decision.Reason = ServiceStatusPanelReasonInvalidScope
			return ServiceStatusPanelSnapshot{}, decision, ErrServiceStatusPanelInvalidScope
		}
		decision.Reason = ServiceStatusPanelReasonVisibilityFailed
		return ServiceStatusPanelSnapshot{}, decision, ErrServiceStatusPanelVisibilityFailed
	}

	staleCandidateCount := 0
	if r.config.EnableStaleBridge && r.cleanup != nil {
		staleResult, staleDecision, err := r.cleanup.DetectStaleInstances(StaleInstanceCleanupRequest{
			TenantID:      tenantID,
			CorrelationID: strings.TrimSpace(req.CorrelationID),
		})
		if err != nil || !staleDecision.Allowed {
			decision.Reason = ServiceStatusPanelReasonStaleBridgeFailed
			return ServiceStatusPanelSnapshot{}, decision, ErrServiceStatusPanelStaleBridgeFailed
		}
		staleCandidateCount = staleResult.StaleCandidateCount
	}

	snapshot := ServiceStatusPanelSnapshot{
		OK:                  true,
		TenantID:            tenantID,
		ViewerTenantID:      viewerTenantID,
		Scope:               scope,
		StaleCandidateCount: staleCandidateCount,
		CorrelationID:       strings.TrimSpace(req.CorrelationID),
		GeneratedAt:         now,
	}

	for _, visible := range visibilityResult.Entries {
		entry := ServiceStatusPanelEntry{
			TenantID:      visible.TenantID,
			ServiceID:     visible.ServiceID,
			InstanceID:    visible.InstanceID,
			ServiceName:   visible.ServiceName,
			Status:        visible.Status,
			Host:          visible.Host,
			Port:          visible.Port,
			Zone:          visible.Zone,
			NodeID:        visible.NodeID,
			Runtime:       visible.Runtime,
			Version:       visible.Version,
			LastSeenAt:    visible.UpdatedAt,
			MetadataCount: visible.MetadataCount,
		}

		if r.config.IncludeMetadataSummary {
			entry.MetadataSummary = map[string]string{}
		}

		for _, metadata := range visible.Metadata {
			if r.config.IncludeMetadataSummary {
				entry.MetadataSummary[metadata.Key] = metadata.Value
			}

			switch metadata.Key {
			case "last_heartbeat_at":
				entry.LastSeenAt = metadata.Value
			case "health_status":
				entry.HealthStatus = metadata.Value
			case "restart_action_id":
				entry.RestartActionID = metadata.Value
			case "isolate_quarantine_action_state":
				entry.IsolateQuarantineState = metadata.Value
			case "maintenance_mode_state":
				entry.MaintenanceModeState = metadata.Value
			case "incident_action_log_id":
				entry.IncidentActionLogID = metadata.Value
			}
		}

		if r.config.IncludeMissionControlTags {
			entry.PanelTags = buildServiceStatusPanelTags(entry)
		}

		snapshot.Entries = append(snapshot.Entries, entry)
		snapshot.EntryCount++

		switch entry.Status {
		case ServiceInstanceStatusHealthy:
			snapshot.HealthyCount++
		case ServiceInstanceStatusUnhealthy:
			snapshot.UnhealthyCount++
		case ServiceInstanceStatusStale:
			snapshot.StaleCount++
		}

		if entry.RestartActionID != "" {
			snapshot.RestartRequestedCount++
		}
		if entry.IsolateQuarantineState == IsolateQuarantineStateQuarantineRequested {
			snapshot.QuarantineCount++
		}
		if entry.IsolateQuarantineState == IsolateQuarantineStateIsolateRequested {
			snapshot.IsolateCount++
		}
		if entry.MaintenanceModeState == MaintenanceModeStateEnabled {
			snapshot.MaintenanceCount++
		}
		if entry.IncidentActionLogID != "" {
			snapshot.IncidentTaggedCount++
		}
	}

	decision.Decision = ServiceStatusPanelDecisionAllow
	decision.Allowed = true
	decision.EntryCount = snapshot.EntryCount
	decision.StaleCandidateCount = snapshot.StaleCandidateCount
	decision.Reason = ServiceStatusPanelReasonAllowed

	return snapshot, decision, nil
}

func buildServiceStatusPanelTags(entry ServiceStatusPanelEntry) []string {
	tags := make([]string, 0)

	if entry.RestartActionID != "" {
		tags = append(tags, "RESTART_REQUESTED")
	}
	if entry.IsolateQuarantineState != "" {
		tags = append(tags, entry.IsolateQuarantineState)
	}
	if entry.MaintenanceModeState != "" {
		tags = append(tags, entry.MaintenanceModeState)
	}
	if entry.IncidentActionLogID != "" {
		tags = append(tags, "INCIDENT_LOGGED")
	}

	return tags
}

func isServiceStatusPanelScopeValid(scope string) bool {
	switch normalizeRegistryVisibilityScope(scope) {
	case RegistryVisibilityScopeTenant, RegistryVisibilityScopePlatform, RegistryVisibilityScopeInternal:
		return true
	default:
		return false
	}
}
