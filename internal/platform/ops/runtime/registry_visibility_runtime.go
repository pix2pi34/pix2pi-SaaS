package opsruntime

import (
	"errors"
	"strings"
	"time"
)

const (
	RegistryVisibilityScopeTenant   = "TENANT"
	RegistryVisibilityScopePlatform = "PLATFORM"
	RegistryVisibilityScopeInternal = "INTERNAL"

	RegistryVisibilityDecisionAllow = "ALLOW"
	RegistryVisibilityDecisionDeny  = "DENY"

	RegistryVisibilityReasonAllowed           = "REGISTRY_VISIBILITY_ALLOWED"
	RegistryVisibilityReasonMissingTenant     = "REGISTRY_VISIBILITY_MISSING_TENANT"
	RegistryVisibilityReasonMissingViewer     = "REGISTRY_VISIBILITY_MISSING_VIEWER_TENANT"
	RegistryVisibilityReasonMissingRegistry   = "REGISTRY_VISIBILITY_MISSING_REGISTRY"
	RegistryVisibilityReasonInvalidScope      = "REGISTRY_VISIBILITY_INVALID_SCOPE"
	RegistryVisibilityReasonCrossTenantDenied = "REGISTRY_VISIBILITY_CROSS_TENANT_DENIED"
)

var (
	ErrRegistryVisibilityMissingTenant     = errors.New("missing registry visibility tenant id")
	ErrRegistryVisibilityMissingViewer     = errors.New("missing registry visibility viewer tenant id")
	ErrRegistryVisibilityMissingRegistry   = errors.New("missing registry visibility registry")
	ErrRegistryVisibilityInvalidScope      = errors.New("invalid registry visibility scope")
	ErrRegistryVisibilityCrossTenantDenied = errors.New("cross-tenant registry visibility denied")
)

type RegistryVisibilityRuntimeConfig struct {
	RequireTenant             bool     `json:"require_tenant"`
	RequireViewerTenant       bool     `json:"require_viewer_tenant"`
	DenyCrossTenantTenantView bool     `json:"deny_cross_tenant_tenant_view"`
	AllowedScopes             []string `json:"allowed_scopes"`
	TenantScopeMetadata       []string `json:"tenant_scope_metadata"`
	PlatformScopeMetadata     []string `json:"platform_scope_metadata"`
	InternalScopeMetadata     []string `json:"internal_scope_metadata"`
}

func DefaultRegistryVisibilityRuntimeConfig() RegistryVisibilityRuntimeConfig {
	return RegistryVisibilityRuntimeConfig{
		RequireTenant:             true,
		RequireViewerTenant:       true,
		DenyCrossTenantTenantView: true,
		AllowedScopes: []string{
			RegistryVisibilityScopeTenant,
			RegistryVisibilityScopePlatform,
			RegistryVisibilityScopeInternal,
		},
		TenantScopeMetadata: []string{
			InstanceMetadataVisibilityTenant,
		},
		PlatformScopeMetadata: []string{
			InstanceMetadataVisibilityTenant,
			InstanceMetadataVisibilityPlatform,
		},
		InternalScopeMetadata: []string{
			InstanceMetadataVisibilityTenant,
			InstanceMetadataVisibilityPlatform,
			InstanceMetadataVisibilityInternal,
		},
	}
}

type RegistryVisibilityRequest struct {
	TenantID       string `json:"tenant_id"`
	ViewerTenantID string `json:"viewer_tenant_id"`
	Scope          string `json:"scope"`
	ActorRef       string `json:"actor_ref,omitempty"`
	CorrelationID  string `json:"correlation_id,omitempty"`
}

type RegistryVisibilityEntry struct {
	TenantID      string                   `json:"tenant_id"`
	ServiceID     string                   `json:"service_id"`
	InstanceID    string                   `json:"instance_id"`
	ServiceName   string                   `json:"service_name"`
	Host          string                   `json:"host,omitempty"`
	Port          int                      `json:"port,omitempty"`
	Zone          string                   `json:"zone,omitempty"`
	NodeID        string                   `json:"node_id,omitempty"`
	Runtime       string                   `json:"runtime,omitempty"`
	Version       string                   `json:"version,omitempty"`
	Status        string                   `json:"status"`
	Metadata      []InstanceMetadataRecord `json:"metadata,omitempty"`
	MetadataCount int                      `json:"metadata_count"`
	UpdatedAt     string                   `json:"updated_at"`
}

type RegistryVisibilityResult struct {
	TenantID       string                    `json:"tenant_id"`
	ViewerTenantID string                    `json:"viewer_tenant_id"`
	Scope          string                    `json:"scope"`
	EntryCount     int                       `json:"entry_count"`
	MetadataCount  int                       `json:"metadata_count"`
	Entries        []RegistryVisibilityEntry `json:"entries"`
	CorrelationID  string                    `json:"correlation_id,omitempty"`
	GeneratedAt    string                    `json:"generated_at"`
}

type RegistryVisibilityDecision struct {
	Decision       string `json:"decision"`
	Allowed        bool   `json:"allowed"`
	TenantID       string `json:"tenant_id"`
	ViewerTenantID string `json:"viewer_tenant_id,omitempty"`
	Scope          string `json:"scope,omitempty"`
	EntryCount     int    `json:"entry_count"`
	MetadataCount  int    `json:"metadata_count"`
	ActorRef       string `json:"actor_ref,omitempty"`
	CorrelationID  string `json:"correlation_id,omitempty"`
	Reason         string `json:"reason"`
	CheckedAt      string `json:"checked_at"`
}

type RegistryVisibilityRuntime struct {
	config   RegistryVisibilityRuntimeConfig
	registry *InstanceMetadataRuntime
}

func NewRegistryVisibilityRuntime(config RegistryVisibilityRuntimeConfig, registry *InstanceMetadataRuntime) *RegistryVisibilityRuntime {
	defaults := DefaultRegistryVisibilityRuntimeConfig()

	if len(config.AllowedScopes) == 0 {
		config.AllowedScopes = defaults.AllowedScopes
	}
	if len(config.TenantScopeMetadata) == 0 {
		config.TenantScopeMetadata = defaults.TenantScopeMetadata
	}
	if len(config.PlatformScopeMetadata) == 0 {
		config.PlatformScopeMetadata = defaults.PlatformScopeMetadata
	}
	if len(config.InternalScopeMetadata) == 0 {
		config.InternalScopeMetadata = defaults.InternalScopeMetadata
	}

	return &RegistryVisibilityRuntime{
		config:   config,
		registry: registry,
	}
}

func (r *RegistryVisibilityRuntime) ListVisibleRegistry(req RegistryVisibilityRequest) (RegistryVisibilityResult, RegistryVisibilityDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	viewerTenantID := strings.TrimSpace(req.ViewerTenantID)
	scope := normalizeRegistryVisibilityScope(req.Scope)

	decision := RegistryVisibilityDecision{
		Decision:       RegistryVisibilityDecisionDeny,
		Allowed:        false,
		TenantID:       tenantID,
		ViewerTenantID: viewerTenantID,
		Scope:          scope,
		ActorRef:       strings.TrimSpace(req.ActorRef),
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		Reason:         RegistryVisibilityReasonAllowed,
		CheckedAt:      now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = RegistryVisibilityReasonMissingTenant
		return RegistryVisibilityResult{}, decision, ErrRegistryVisibilityMissingTenant
	}

	if r.config.RequireViewerTenant && viewerTenantID == "" {
		decision.Reason = RegistryVisibilityReasonMissingViewer
		return RegistryVisibilityResult{}, decision, ErrRegistryVisibilityMissingViewer
	}

	if r.registry == nil {
		decision.Reason = RegistryVisibilityReasonMissingRegistry
		return RegistryVisibilityResult{}, decision, ErrRegistryVisibilityMissingRegistry
	}

	if !r.scopeAllowed(scope) {
		decision.Reason = RegistryVisibilityReasonInvalidScope
		return RegistryVisibilityResult{}, decision, ErrRegistryVisibilityInvalidScope
	}

	if r.config.DenyCrossTenantTenantView && scope == RegistryVisibilityScopeTenant && tenantID != viewerTenantID {
		decision.Reason = RegistryVisibilityReasonCrossTenantDenied
		return RegistryVisibilityResult{}, decision, ErrRegistryVisibilityCrossTenantDenied
	}

	result := RegistryVisibilityResult{
		TenantID:       tenantID,
		ViewerTenantID: viewerTenantID,
		Scope:          scope,
		CorrelationID:  strings.TrimSpace(req.CorrelationID),
		GeneratedAt:    now,
	}

	metadataVisibility := r.metadataVisibilitiesForScope(scope)

	r.registry.mu.RLock()
	defer r.registry.mu.RUnlock()

	for _, instance := range r.registry.instances {
		if instance.TenantID != tenantID {
			continue
		}

		entry := RegistryVisibilityEntry{
			TenantID:    instance.TenantID,
			ServiceID:   instance.ServiceID,
			InstanceID:  instance.InstanceID,
			ServiceName: instance.ServiceName,
			Host:        instance.Host,
			Port:        instance.Port,
			Zone:        instance.Zone,
			NodeID:      instance.NodeID,
			Runtime:     instance.Runtime,
			Version:     instance.Version,
			Status:      instance.Status,
			UpdatedAt:   instance.UpdatedAt,
		}

		for _, metadata := range r.registry.metadata {
			if metadata.TenantID != tenantID || metadata.InstanceID != instance.InstanceID {
				continue
			}
			if !registryVisibilityMetadataAllowed(metadata.Visibility, metadataVisibility) {
				continue
			}
			entry.Metadata = append(entry.Metadata, metadata)
			entry.MetadataCount++
			result.MetadataCount++
		}

		result.Entries = append(result.Entries, entry)
		result.EntryCount++
	}

	decision.Decision = RegistryVisibilityDecisionAllow
	decision.Allowed = true
	decision.EntryCount = result.EntryCount
	decision.MetadataCount = result.MetadataCount
	decision.Reason = RegistryVisibilityReasonAllowed

	return result, decision, nil
}

func (r *RegistryVisibilityRuntime) CanView(req RegistryVisibilityRequest) bool {
	decision, err := r.CheckVisibility(req)
	return err == nil && decision.Allowed
}

func (r *RegistryVisibilityRuntime) CheckVisibility(req RegistryVisibilityRequest) (RegistryVisibilityDecision, error) {
	_, decision, err := r.ListVisibleRegistry(req)
	return decision, err
}

func (r *RegistryVisibilityRuntime) metadataVisibilitiesForScope(scope string) []string {
	switch normalizeRegistryVisibilityScope(scope) {
	case RegistryVisibilityScopeTenant:
		return r.config.TenantScopeMetadata
	case RegistryVisibilityScopePlatform:
		return r.config.PlatformScopeMetadata
	case RegistryVisibilityScopeInternal:
		return r.config.InternalScopeMetadata
	default:
		return []string{}
	}
}

func (r *RegistryVisibilityRuntime) scopeAllowed(scope string) bool {
	for _, allowed := range r.config.AllowedScopes {
		if strings.EqualFold(strings.TrimSpace(allowed), strings.TrimSpace(scope)) {
			return true
		}
	}
	return false
}

func normalizeRegistryVisibilityScope(scope string) string {
	scope = strings.TrimSpace(scope)
	if scope == "" {
		return RegistryVisibilityScopeTenant
	}
	return strings.ToUpper(scope)
}

func registryVisibilityMetadataAllowed(visibility string, allowed []string) bool {
	for _, item := range allowed {
		if strings.EqualFold(strings.TrimSpace(item), strings.TrimSpace(visibility)) {
			return true
		}
	}
	return false
}
