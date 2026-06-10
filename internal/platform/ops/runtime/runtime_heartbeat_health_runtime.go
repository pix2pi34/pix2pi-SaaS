package opsruntime

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"
)

const (
	RuntimeHeartbeatEndpointPath = "/ops/registry/heartbeat"
	RuntimeHealthSnapshotPath    = "/ops/registry/health"

	RuntimeHealthDecisionAllow = "ALLOW"
	RuntimeHealthDecisionDeny  = "DENY"

	RuntimeHealthReasonAllowed         = "RUNTIME_HEALTH_ALLOWED"
	RuntimeHealthReasonMissingRegistry = "RUNTIME_HEALTH_MISSING_REGISTRY"
	RuntimeHealthReasonInvalidMethod   = "RUNTIME_HEALTH_INVALID_METHOD"
	RuntimeHealthReasonInvalidPath     = "RUNTIME_HEALTH_INVALID_PATH"
	RuntimeHealthReasonMissingTenant   = "RUNTIME_HEALTH_MISSING_TENANT"
	RuntimeHealthReasonInvalidBody     = "RUNTIME_HEALTH_INVALID_BODY"
	RuntimeHealthReasonCrossTenant     = "RUNTIME_HEALTH_CROSS_TENANT_DENIED"
	RuntimeHealthReasonMissingInstance = "RUNTIME_HEALTH_MISSING_INSTANCE"
	RuntimeHealthReasonMissingService  = "RUNTIME_HEALTH_MISSING_SERVICE"
	RuntimeHealthReasonHeartbeatFailed = "RUNTIME_HEALTH_HEARTBEAT_FAILED"
	RuntimeHealthReasonSnapshotFailed  = "RUNTIME_HEALTH_SNAPSHOT_FAILED"
)

var (
	ErrRuntimeHealthMissingRegistry = errors.New("missing runtime health registry")
	ErrRuntimeHealthInvalidMethod   = errors.New("invalid runtime health method")
	ErrRuntimeHealthInvalidPath     = errors.New("invalid runtime health path")
	ErrRuntimeHealthMissingTenant   = errors.New("missing runtime health tenant")
	ErrRuntimeHealthInvalidBody     = errors.New("invalid runtime health body")
	ErrRuntimeHealthCrossTenant     = errors.New("cross-tenant runtime health access denied")
	ErrRuntimeHealthMissingInstance = errors.New("missing runtime health instance")
	ErrRuntimeHealthMissingService  = errors.New("missing runtime health service")
	ErrRuntimeHealthHeartbeatFailed = errors.New("runtime heartbeat failed")
	ErrRuntimeHealthSnapshotFailed  = errors.New("runtime health snapshot failed")
)

type RuntimeHeartbeatHealthRuntimeConfig struct {
	HeartbeatPath             string `json:"heartbeat_path"`
	HealthSnapshotPath        string `json:"health_snapshot_path"`
	RequireTenantHeader       bool   `json:"require_tenant_header"`
	TenantHeaderName          string `json:"tenant_header_name"`
	AllowBodyTenantFallback   bool   `json:"allow_body_tenant_fallback"`
	DefaultHeartbeatStatus    string `json:"default_heartbeat_status"`
	DefaultMetadataVisibility string `json:"default_metadata_visibility"`
	EnableStaleCleanupBridge  bool   `json:"enable_stale_cleanup_bridge"`
}

func DefaultRuntimeHeartbeatHealthRuntimeConfig() RuntimeHeartbeatHealthRuntimeConfig {
	return RuntimeHeartbeatHealthRuntimeConfig{
		HeartbeatPath:             RuntimeHeartbeatEndpointPath,
		HealthSnapshotPath:        RuntimeHealthSnapshotPath,
		RequireTenantHeader:       true,
		TenantHeaderName:          "X-Tenant-ID",
		AllowBodyTenantFallback:   false,
		DefaultHeartbeatStatus:    ServiceInstanceStatusHealthy,
		DefaultMetadataVisibility: InstanceMetadataVisibilityInternal,
		EnableStaleCleanupBridge:  true,
	}
}

type RuntimeHeartbeatPushRequest struct {
	TenantID      string            `json:"tenant_id,omitempty"`
	ServiceName   string            `json:"service_name"`
	InstanceID    string            `json:"instance_id,omitempty"`
	ServiceID     string            `json:"service_id,omitempty"`
	Host          string            `json:"host,omitempty"`
	Port          int               `json:"port,omitempty"`
	Zone          string            `json:"zone,omitempty"`
	NodeID        string            `json:"node_id,omitempty"`
	Runtime       string            `json:"runtime,omitempty"`
	Version       string            `json:"version,omitempty"`
	Status        string            `json:"status,omitempty"`
	HealthStatus  string            `json:"health_status,omitempty"`
	Metadata      map[string]string `json:"metadata,omitempty"`
	CorrelationID string            `json:"correlation_id,omitempty"`
}

type RuntimeHeartbeatPushResponse struct {
	OK              bool                  `json:"ok"`
	TenantID        string                `json:"tenant_id"`
	ServiceID       string                `json:"service_id"`
	InstanceID      string                `json:"instance_id"`
	ServiceName     string                `json:"service_name"`
	Status          string                `json:"status"`
	HealthStatus    string                `json:"health_status"`
	MetadataCount   int                   `json:"metadata_count"`
	Instance        ServiceInstanceRecord `json:"instance"`
	DecisionReason  string                `json:"decision_reason"`
	CorrelationID   string                `json:"correlation_id,omitempty"`
	LastHeartbeatAt string                `json:"last_heartbeat_at"`
}

type RuntimeHealthSnapshotRequest struct {
	TenantID       string `json:"tenant_id,omitempty"`
	ViewerTenantID string `json:"viewer_tenant_id,omitempty"`
	Scope          string `json:"scope,omitempty"`
	CorrelationID  string `json:"correlation_id,omitempty"`
}

type RuntimeHealthSnapshotEntry struct {
	TenantID      string `json:"tenant_id"`
	ServiceID     string `json:"service_id"`
	InstanceID    string `json:"instance_id"`
	ServiceName   string `json:"service_name"`
	Status        string `json:"status"`
	Host          string `json:"host,omitempty"`
	Port          int    `json:"port,omitempty"`
	Zone          string `json:"zone,omitempty"`
	NodeID        string `json:"node_id,omitempty"`
	Runtime       string `json:"runtime,omitempty"`
	Version       string `json:"version,omitempty"`
	LastSeenAt    string `json:"last_seen_at"`
	HealthStatus  string `json:"health_status,omitempty"`
	MetadataCount int    `json:"metadata_count"`
}

type RuntimeHealthSnapshotResponse struct {
	OK                  bool                         `json:"ok"`
	TenantID            string                       `json:"tenant_id"`
	ViewerTenantID      string                       `json:"viewer_tenant_id"`
	Scope               string                       `json:"scope"`
	InstanceCount       int                          `json:"instance_count"`
	HealthyCount        int                          `json:"healthy_count"`
	UnhealthyCount      int                          `json:"unhealthy_count"`
	StaleCount          int                          `json:"stale_count"`
	StaleCandidateCount int                          `json:"stale_candidate_count"`
	Entries             []RuntimeHealthSnapshotEntry `json:"entries"`
	DecisionReason      string                       `json:"decision_reason"`
	CorrelationID       string                       `json:"correlation_id,omitempty"`
	GeneratedAt         string                       `json:"generated_at"`
}

type RuntimeHealthDecision struct {
	Decision            string `json:"decision"`
	Allowed             bool   `json:"allowed"`
	TenantID            string `json:"tenant_id"`
	ViewerTenantID      string `json:"viewer_tenant_id,omitempty"`
	ServiceID           string `json:"service_id,omitempty"`
	InstanceID          string `json:"instance_id,omitempty"`
	ServiceName         string `json:"service_name,omitempty"`
	Method              string `json:"method,omitempty"`
	Path                string `json:"path,omitempty"`
	HTTPStatus          int    `json:"http_status"`
	MetadataCount       int    `json:"metadata_count"`
	InstanceCount       int    `json:"instance_count"`
	StaleCandidateCount int    `json:"stale_candidate_count"`
	CorrelationID       string `json:"correlation_id,omitempty"`
	Reason              string `json:"reason"`
	CheckedAt           string `json:"checked_at"`
}

type RuntimeHeartbeatHealthRuntime struct {
	config     RuntimeHeartbeatHealthRuntimeConfig
	registry   *InstanceMetadataRuntime
	visibility *RegistryVisibilityRuntime
	cleanup    *StaleInstanceCleanupRuntime
}

func NewRuntimeHeartbeatHealthRuntime(config RuntimeHeartbeatHealthRuntimeConfig, registry *InstanceMetadataRuntime, visibility *RegistryVisibilityRuntime, cleanup *StaleInstanceCleanupRuntime) *RuntimeHeartbeatHealthRuntime {
	defaults := DefaultRuntimeHeartbeatHealthRuntimeConfig()

	if strings.TrimSpace(config.HeartbeatPath) == "" {
		config.HeartbeatPath = defaults.HeartbeatPath
	}
	if strings.TrimSpace(config.HealthSnapshotPath) == "" {
		config.HealthSnapshotPath = defaults.HealthSnapshotPath
	}
	if strings.TrimSpace(config.TenantHeaderName) == "" {
		config.TenantHeaderName = defaults.TenantHeaderName
	}
	if strings.TrimSpace(config.DefaultHeartbeatStatus) == "" {
		config.DefaultHeartbeatStatus = defaults.DefaultHeartbeatStatus
	}
	if strings.TrimSpace(config.DefaultMetadataVisibility) == "" {
		config.DefaultMetadataVisibility = defaults.DefaultMetadataVisibility
	}

	return &RuntimeHeartbeatHealthRuntime{
		config:     config,
		registry:   registry,
		visibility: visibility,
		cleanup:    cleanup,
	}
}

func (r *RuntimeHeartbeatHealthRuntime) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	if req == nil {
		writeRuntimeHealthJSON(w, http.StatusBadRequest, map[string]any{
			"ok":    false,
			"error": ErrRuntimeHealthInvalidBody.Error(),
		})
		return
	}

	switch req.URL.Path {
	case r.config.HeartbeatPath:
		response, decision, err := r.HandleHeartbeatPush(req)
		status := decision.HTTPStatus
		if status == 0 {
			status = http.StatusOK
		}
		if err != nil {
			writeRuntimeHealthJSON(w, status, map[string]any{
				"ok":       false,
				"error":    err.Error(),
				"decision": decision,
			})
			return
		}
		writeRuntimeHealthJSON(w, status, response)
	case r.config.HealthSnapshotPath:
		response, decision, err := r.HandleHealthSnapshot(req)
		status := decision.HTTPStatus
		if status == 0 {
			status = http.StatusOK
		}
		if err != nil {
			writeRuntimeHealthJSON(w, status, map[string]any{
				"ok":       false,
				"error":    err.Error(),
				"decision": decision,
			})
			return
		}
		writeRuntimeHealthJSON(w, status, response)
	default:
		writeRuntimeHealthJSON(w, http.StatusNotFound, map[string]any{
			"ok":    false,
			"error": ErrRuntimeHealthInvalidPath.Error(),
		})
	}
}

func (r *RuntimeHeartbeatHealthRuntime) HandleHeartbeatPush(req *http.Request) (RuntimeHeartbeatPushResponse, RuntimeHealthDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	decision := RuntimeHealthDecision{
		Decision:   RuntimeHealthDecisionDeny,
		Allowed:    false,
		Method:     "",
		Path:       "",
		HTTPStatus: http.StatusInternalServerError,
		Reason:     RuntimeHealthReasonAllowed,
		CheckedAt:  now,
	}

	if req != nil {
		decision.Method = req.Method
		decision.Path = req.URL.Path
	}

	if r.registry == nil {
		decision.Reason = RuntimeHealthReasonMissingRegistry
		decision.HTTPStatus = http.StatusInternalServerError
		return RuntimeHeartbeatPushResponse{}, decision, ErrRuntimeHealthMissingRegistry
	}

	if req == nil {
		decision.Reason = RuntimeHealthReasonInvalidBody
		decision.HTTPStatus = http.StatusBadRequest
		return RuntimeHeartbeatPushResponse{}, decision, ErrRuntimeHealthInvalidBody
	}

	if req.Method != http.MethodPost {
		decision.Reason = RuntimeHealthReasonInvalidMethod
		decision.HTTPStatus = http.StatusMethodNotAllowed
		return RuntimeHeartbeatPushResponse{}, decision, ErrRuntimeHealthInvalidMethod
	}

	if req.URL.Path != r.config.HeartbeatPath {
		decision.Reason = RuntimeHealthReasonInvalidPath
		decision.HTTPStatus = http.StatusNotFound
		return RuntimeHeartbeatPushResponse{}, decision, ErrRuntimeHealthInvalidPath
	}

	var body RuntimeHeartbeatPushRequest
	if err := json.NewDecoder(req.Body).Decode(&body); err != nil {
		decision.Reason = RuntimeHealthReasonInvalidBody
		decision.HTTPStatus = http.StatusBadRequest
		return RuntimeHeartbeatPushResponse{}, decision, ErrRuntimeHealthInvalidBody
	}

	tenantID, err := r.resolveTenant(req, body.TenantID)
	decision.TenantID = tenantID
	decision.InstanceID = strings.TrimSpace(body.InstanceID)
	decision.ServiceID = strings.TrimSpace(body.ServiceID)
	decision.ServiceName = strings.TrimSpace(body.ServiceName)
	decision.CorrelationID = strings.TrimSpace(body.CorrelationID)

	if err != nil {
		decision.Reason = RuntimeHealthReasonMissingTenant
		decision.HTTPStatus = http.StatusBadRequest
		return RuntimeHeartbeatPushResponse{}, decision, err
	}

	bodyTenantID := strings.TrimSpace(body.TenantID)
	if bodyTenantID != "" && bodyTenantID != tenantID {
		decision.Reason = RuntimeHealthReasonCrossTenant
		decision.HTTPStatus = http.StatusForbidden
		return RuntimeHeartbeatPushResponse{}, decision, ErrRuntimeHealthCrossTenant
	}

	if strings.TrimSpace(body.ServiceName) == "" {
		decision.Reason = RuntimeHealthReasonMissingService
		decision.HTTPStatus = http.StatusBadRequest
		return RuntimeHeartbeatPushResponse{}, decision, ErrRuntimeHealthMissingService
	}

	status := normalizeInstanceStatus(body.Status)
	if strings.TrimSpace(body.Status) == "" {
		status = normalizeInstanceStatus(r.config.DefaultHeartbeatStatus)
	}

	instance, registerDecision, err := r.registry.RegisterOrUpdateInstance(ServiceInstanceRegisterRequest{
		TenantID:      tenantID,
		ServiceID:     strings.TrimSpace(body.ServiceID),
		InstanceID:    strings.TrimSpace(body.InstanceID),
		ServiceName:   strings.TrimSpace(body.ServiceName),
		Host:          strings.TrimSpace(body.Host),
		Port:          body.Port,
		Zone:          strings.TrimSpace(body.Zone),
		NodeID:        strings.TrimSpace(body.NodeID),
		Runtime:       strings.TrimSpace(body.Runtime),
		Version:       strings.TrimSpace(body.Version),
		Status:        status,
		CorrelationID: strings.TrimSpace(body.CorrelationID),
	})
	if err != nil || !registerDecision.Allowed {
		decision.Reason = RuntimeHealthReasonHeartbeatFailed
		decision.HTTPStatus = http.StatusBadRequest
		return RuntimeHeartbeatPushResponse{}, decision, ErrRuntimeHealthHeartbeatFailed
	}

	metadataCount := 0
	healthStatus := strings.TrimSpace(body.HealthStatus)
	if healthStatus == "" {
		healthStatus = status
	}

	metadata := map[string]string{
		"last_heartbeat_at": now,
		"health_status":     healthStatus,
	}

	for key, value := range body.Metadata {
		key = strings.TrimSpace(key)
		value = strings.TrimSpace(value)
		if key != "" && value != "" {
			metadata[key] = value
		}
	}

	for key, value := range metadata {
		_, metadataDecision, err := r.registry.UpsertMetadata(InstanceMetadataUpsertRequest{
			TenantID:      tenantID,
			InstanceID:    instance.InstanceID,
			Key:           key,
			Value:         value,
			Visibility:    r.config.DefaultMetadataVisibility,
			Source:        "runtime_heartbeat",
			CorrelationID: strings.TrimSpace(body.CorrelationID),
		})
		if err != nil || !metadataDecision.Allowed {
			decision.Reason = RuntimeHealthReasonHeartbeatFailed
			decision.HTTPStatus = http.StatusBadRequest
			return RuntimeHeartbeatPushResponse{}, decision, ErrRuntimeHealthHeartbeatFailed
		}
		metadataCount++
	}

	decision.Decision = RuntimeHealthDecisionAllow
	decision.Allowed = true
	decision.HTTPStatus = http.StatusOK
	decision.ServiceID = instance.ServiceID
	decision.InstanceID = instance.InstanceID
	decision.ServiceName = instance.ServiceName
	decision.MetadataCount = metadataCount
	decision.Reason = RuntimeHealthReasonAllowed

	return RuntimeHeartbeatPushResponse{
		OK:              true,
		TenantID:        tenantID,
		ServiceID:       instance.ServiceID,
		InstanceID:      instance.InstanceID,
		ServiceName:     instance.ServiceName,
		Status:          instance.Status,
		HealthStatus:    healthStatus,
		MetadataCount:   metadataCount,
		Instance:        instance,
		DecisionReason:  RuntimeHealthReasonAllowed,
		CorrelationID:   strings.TrimSpace(body.CorrelationID),
		LastHeartbeatAt: now,
	}, decision, nil
}

func (r *RuntimeHeartbeatHealthRuntime) HandleHealthSnapshot(req *http.Request) (RuntimeHealthSnapshotResponse, RuntimeHealthDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	decision := RuntimeHealthDecision{
		Decision:   RuntimeHealthDecisionDeny,
		Allowed:    false,
		Method:     "",
		Path:       "",
		HTTPStatus: http.StatusInternalServerError,
		Reason:     RuntimeHealthReasonAllowed,
		CheckedAt:  now,
	}

	if req != nil {
		decision.Method = req.Method
		decision.Path = req.URL.Path
	}

	if r.registry == nil || r.visibility == nil {
		decision.Reason = RuntimeHealthReasonMissingRegistry
		decision.HTTPStatus = http.StatusInternalServerError
		return RuntimeHealthSnapshotResponse{}, decision, ErrRuntimeHealthMissingRegistry
	}

	if req == nil {
		decision.Reason = RuntimeHealthReasonInvalidBody
		decision.HTTPStatus = http.StatusBadRequest
		return RuntimeHealthSnapshotResponse{}, decision, ErrRuntimeHealthInvalidBody
	}

	if req.Method != http.MethodGet {
		decision.Reason = RuntimeHealthReasonInvalidMethod
		decision.HTTPStatus = http.StatusMethodNotAllowed
		return RuntimeHealthSnapshotResponse{}, decision, ErrRuntimeHealthInvalidMethod
	}

	if req.URL.Path != r.config.HealthSnapshotPath {
		decision.Reason = RuntimeHealthReasonInvalidPath
		decision.HTTPStatus = http.StatusNotFound
		return RuntimeHealthSnapshotResponse{}, decision, ErrRuntimeHealthInvalidPath
	}

	tenantID, err := r.resolveTenant(req, "")
	decision.TenantID = tenantID

	if err != nil {
		decision.Reason = RuntimeHealthReasonMissingTenant
		decision.HTTPStatus = http.StatusBadRequest
		return RuntimeHealthSnapshotResponse{}, decision, err
	}

	viewerTenantID := strings.TrimSpace(req.URL.Query().Get("viewer_tenant_id"))
	if viewerTenantID == "" {
		viewerTenantID = tenantID
	}

	scope := normalizeRegistryVisibilityScope(req.URL.Query().Get("scope"))

	visibilityResult, visibilityDecision, err := r.visibility.ListVisibleRegistry(RegistryVisibilityRequest{
		TenantID:       tenantID,
		ViewerTenantID: viewerTenantID,
		Scope:          scope,
		CorrelationID:  req.URL.Query().Get("correlation_id"),
	})
	if err != nil || !visibilityDecision.Allowed {
		decision.Reason = RuntimeHealthReasonSnapshotFailed
		decision.HTTPStatus = http.StatusForbidden
		return RuntimeHealthSnapshotResponse{}, decision, ErrRuntimeHealthSnapshotFailed
	}

	staleCandidateCount := 0
	if r.config.EnableStaleCleanupBridge && r.cleanup != nil {
		cleanupResult, cleanupDecision, err := r.cleanup.DetectStaleInstances(StaleInstanceCleanupRequest{
			TenantID:      tenantID,
			Now:           time.Now().UTC(),
			CorrelationID: req.URL.Query().Get("correlation_id"),
		})
		if err == nil && cleanupDecision.Allowed {
			staleCandidateCount = cleanupResult.StaleCandidateCount
		}
	}

	response := RuntimeHealthSnapshotResponse{
		OK:                  true,
		TenantID:            tenantID,
		ViewerTenantID:      viewerTenantID,
		Scope:               scope,
		StaleCandidateCount: staleCandidateCount,
		DecisionReason:      RuntimeHealthReasonAllowed,
		CorrelationID:       req.URL.Query().Get("correlation_id"),
		GeneratedAt:         now,
	}

	for _, entry := range visibilityResult.Entries {
		lastSeen := entry.UpdatedAt
		healthStatus := ""
		for _, metadata := range entry.Metadata {
			if metadata.Key == "health_status" {
				healthStatus = metadata.Value
			}
			if metadata.Key == "last_heartbeat_at" {
				lastSeen = metadata.Value
			}
		}

		snapshotEntry := RuntimeHealthSnapshotEntry{
			TenantID:      entry.TenantID,
			ServiceID:     entry.ServiceID,
			InstanceID:    entry.InstanceID,
			ServiceName:   entry.ServiceName,
			Status:        entry.Status,
			Host:          entry.Host,
			Port:          entry.Port,
			Zone:          entry.Zone,
			NodeID:        entry.NodeID,
			Runtime:       entry.Runtime,
			Version:       entry.Version,
			LastSeenAt:    lastSeen,
			HealthStatus:  healthStatus,
			MetadataCount: entry.MetadataCount,
		}

		switch entry.Status {
		case ServiceInstanceStatusHealthy:
			response.HealthyCount++
		case ServiceInstanceStatusUnhealthy:
			response.UnhealthyCount++
		case ServiceInstanceStatusStale:
			response.StaleCount++
		}

		response.Entries = append(response.Entries, snapshotEntry)
		response.InstanceCount++
	}

	decision.Decision = RuntimeHealthDecisionAllow
	decision.Allowed = true
	decision.HTTPStatus = http.StatusOK
	decision.ViewerTenantID = viewerTenantID
	decision.InstanceCount = response.InstanceCount
	decision.StaleCandidateCount = staleCandidateCount
	decision.Reason = RuntimeHealthReasonAllowed

	return response, decision, nil
}

func (r *RuntimeHeartbeatHealthRuntime) resolveTenant(req *http.Request, bodyTenantID string) (string, error) {
	if req == nil {
		return "", ErrRuntimeHealthMissingTenant
	}

	headerTenantID := strings.TrimSpace(req.Header.Get(r.config.TenantHeaderName))
	bodyTenantID = strings.TrimSpace(bodyTenantID)

	if r.config.RequireTenantHeader && headerTenantID == "" {
		return "", ErrRuntimeHealthMissingTenant
	}

	if headerTenantID != "" {
		return headerTenantID, nil
	}

	if r.config.AllowBodyTenantFallback && bodyTenantID != "" {
		return bodyTenantID, nil
	}

	return "", ErrRuntimeHealthMissingTenant
}

func writeRuntimeHealthJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}
