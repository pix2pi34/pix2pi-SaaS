package opsruntime

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"strings"
	"sync"
	"time"
)

const (
	ServiceInstanceStatusRegistered = "REGISTERED"
	ServiceInstanceStatusHealthy    = "HEALTHY"
	ServiceInstanceStatusUnhealthy  = "UNHEALTHY"
	ServiceInstanceStatusStale      = "STALE"

	InstanceMetadataVisibilityTenant   = "TENANT"
	InstanceMetadataVisibilityPlatform = "PLATFORM"
	InstanceMetadataVisibilityInternal = "INTERNAL"

	InstanceMetadataDecisionAllow = "ALLOW"
	InstanceMetadataDecisionDeny  = "DENY"

	InstanceMetadataReasonAllowed           = "INSTANCE_METADATA_ALLOWED"
	InstanceMetadataReasonMissingTenant     = "INSTANCE_METADATA_MISSING_TENANT"
	InstanceMetadataReasonMissingService    = "INSTANCE_METADATA_MISSING_SERVICE"
	InstanceMetadataReasonMissingInstance   = "INSTANCE_METADATA_MISSING_INSTANCE"
	InstanceMetadataReasonMissingKey        = "INSTANCE_METADATA_MISSING_KEY"
	InstanceMetadataReasonMissingValue      = "INSTANCE_METADATA_MISSING_VALUE"
	InstanceMetadataReasonInvalidVisibility = "INSTANCE_METADATA_INVALID_VISIBILITY"
	InstanceMetadataReasonInvalidStatus     = "INSTANCE_METADATA_INVALID_STATUS"
	InstanceMetadataReasonInstanceNotFound  = "INSTANCE_METADATA_INSTANCE_NOT_FOUND"
	InstanceMetadataReasonCrossTenant       = "INSTANCE_METADATA_CROSS_TENANT_DENIED"
)

var (
	ErrInstanceMetadataMissingTenant     = errors.New("missing instance metadata tenant id")
	ErrInstanceMetadataMissingService    = errors.New("missing service name")
	ErrInstanceMetadataMissingInstance   = errors.New("missing instance id")
	ErrInstanceMetadataMissingKey        = errors.New("missing metadata key")
	ErrInstanceMetadataMissingValue      = errors.New("missing metadata value")
	ErrInstanceMetadataInvalidVisibility = errors.New("invalid metadata visibility")
	ErrInstanceMetadataInvalidStatus     = errors.New("invalid service instance status")
	ErrInstanceMetadataInstanceNotFound  = errors.New("service instance not found")
	ErrInstanceMetadataCrossTenant       = errors.New("cross-tenant instance metadata access denied")
)

type InstanceMetadataRuntimeConfig struct {
	RequireTenant       bool     `json:"require_tenant"`
	AllowedStatuses     []string `json:"allowed_statuses"`
	AllowedVisibilities []string `json:"allowed_visibilities"`
}

func DefaultInstanceMetadataRuntimeConfig() InstanceMetadataRuntimeConfig {
	return InstanceMetadataRuntimeConfig{
		RequireTenant: true,
		AllowedStatuses: []string{
			ServiceInstanceStatusRegistered,
			ServiceInstanceStatusHealthy,
			ServiceInstanceStatusUnhealthy,
			ServiceInstanceStatusStale,
		},
		AllowedVisibilities: []string{
			InstanceMetadataVisibilityTenant,
			InstanceMetadataVisibilityPlatform,
			InstanceMetadataVisibilityInternal,
		},
	}
}

type ServiceInstanceRecord struct {
	TenantID      string `json:"tenant_id"`
	ServiceID     string `json:"service_id"`
	InstanceID    string `json:"instance_id"`
	ServiceName   string `json:"service_name"`
	Host          string `json:"host,omitempty"`
	Port          int    `json:"port,omitempty"`
	Zone          string `json:"zone,omitempty"`
	NodeID        string `json:"node_id,omitempty"`
	Runtime       string `json:"runtime,omitempty"`
	Version       string `json:"version,omitempty"`
	Status        string `json:"status"`
	CorrelationID string `json:"correlation_id,omitempty"`
	RegisteredAt  string `json:"registered_at"`
	UpdatedAt     string `json:"updated_at"`
}

type InstanceMetadataRecord struct {
	TenantID      string `json:"tenant_id"`
	MetadataID    string `json:"metadata_id"`
	ServiceID     string `json:"service_id"`
	InstanceID    string `json:"instance_id"`
	ServiceName   string `json:"service_name"`
	Key           string `json:"key"`
	Value         string `json:"value"`
	Visibility    string `json:"visibility"`
	Source        string `json:"source,omitempty"`
	CorrelationID string `json:"correlation_id,omitempty"`
	CreatedAt     string `json:"created_at"`
	UpdatedAt     string `json:"updated_at"`
}

type ServiceInstanceRegisterRequest struct {
	TenantID      string `json:"tenant_id"`
	ServiceID     string `json:"service_id,omitempty"`
	InstanceID    string `json:"instance_id,omitempty"`
	ServiceName   string `json:"service_name"`
	Host          string `json:"host,omitempty"`
	Port          int    `json:"port,omitempty"`
	Zone          string `json:"zone,omitempty"`
	NodeID        string `json:"node_id,omitempty"`
	Runtime       string `json:"runtime,omitempty"`
	Version       string `json:"version,omitempty"`
	Status        string `json:"status,omitempty"`
	CorrelationID string `json:"correlation_id,omitempty"`
}

type InstanceMetadataUpsertRequest struct {
	TenantID      string `json:"tenant_id"`
	InstanceID    string `json:"instance_id"`
	Key           string `json:"key"`
	Value         string `json:"value"`
	Visibility    string `json:"visibility,omitempty"`
	Source        string `json:"source,omitempty"`
	CorrelationID string `json:"correlation_id,omitempty"`
}

type InstanceMetadataDecision struct {
	Decision    string `json:"decision"`
	Allowed     bool   `json:"allowed"`
	TenantID    string `json:"tenant_id"`
	ServiceID   string `json:"service_id,omitempty"`
	InstanceID  string `json:"instance_id,omitempty"`
	ServiceName string `json:"service_name,omitempty"`
	Key         string `json:"key,omitempty"`
	Visibility  string `json:"visibility,omitempty"`
	Reason      string `json:"reason"`
	CheckedAt   string `json:"checked_at"`
}

type InstanceMetadataRuntime struct {
	config    InstanceMetadataRuntimeConfig
	mu        sync.RWMutex
	instances map[string]ServiceInstanceRecord
	metadata  map[string]InstanceMetadataRecord
}

func NewInstanceMetadataRuntime(config InstanceMetadataRuntimeConfig) *InstanceMetadataRuntime {
	defaults := DefaultInstanceMetadataRuntimeConfig()
	if len(config.AllowedStatuses) == 0 {
		config.AllowedStatuses = defaults.AllowedStatuses
	}
	if len(config.AllowedVisibilities) == 0 {
		config.AllowedVisibilities = defaults.AllowedVisibilities
	}

	return &InstanceMetadataRuntime{
		config:    config,
		instances: make(map[string]ServiceInstanceRecord),
		metadata:  make(map[string]InstanceMetadataRecord),
	}
}

func (r *InstanceMetadataRuntime) RegisterOrUpdateInstance(req ServiceInstanceRegisterRequest) (ServiceInstanceRecord, InstanceMetadataDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	serviceName := strings.TrimSpace(req.ServiceName)
	status := normalizeInstanceStatus(req.Status)

	decision := InstanceMetadataDecision{
		Decision:    InstanceMetadataDecisionDeny,
		Allowed:     false,
		TenantID:    tenantID,
		ServiceName: serviceName,
		Reason:      InstanceMetadataReasonAllowed,
		CheckedAt:   now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = InstanceMetadataReasonMissingTenant
		return ServiceInstanceRecord{}, decision, ErrInstanceMetadataMissingTenant
	}
	if serviceName == "" {
		decision.Reason = InstanceMetadataReasonMissingService
		return ServiceInstanceRecord{}, decision, ErrInstanceMetadataMissingService
	}
	if !r.statusAllowed(status) {
		decision.Reason = InstanceMetadataReasonInvalidStatus
		return ServiceInstanceRecord{}, decision, ErrInstanceMetadataInvalidStatus
	}

	serviceID := strings.TrimSpace(req.ServiceID)
	if serviceID == "" {
		serviceID = NewServiceInstanceServiceID()
	}

	instanceID := strings.TrimSpace(req.InstanceID)
	if instanceID == "" {
		instanceID = NewServiceInstanceID()
	}

	key := serviceInstanceKey(tenantID, instanceID)

	r.mu.Lock()
	defer r.mu.Unlock()

	existing, exists := r.instances[key]

	record := ServiceInstanceRecord{
		TenantID:      tenantID,
		ServiceID:     serviceID,
		InstanceID:    instanceID,
		ServiceName:   serviceName,
		Host:          strings.TrimSpace(req.Host),
		Port:          req.Port,
		Zone:          strings.TrimSpace(req.Zone),
		NodeID:        strings.TrimSpace(req.NodeID),
		Runtime:       strings.TrimSpace(req.Runtime),
		Version:       strings.TrimSpace(req.Version),
		Status:        status,
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		RegisteredAt:  now,
		UpdatedAt:     now,
	}

	if exists {
		record.RegisteredAt = existing.RegisteredAt
		if record.ServiceID == "" {
			record.ServiceID = existing.ServiceID
		}
	}

	r.instances[key] = record

	decision.Decision = InstanceMetadataDecisionAllow
	decision.Allowed = true
	decision.ServiceID = record.ServiceID
	decision.InstanceID = record.InstanceID
	decision.ServiceName = record.ServiceName
	decision.Reason = InstanceMetadataReasonAllowed

	return record, decision, nil
}

func (r *InstanceMetadataRuntime) UpsertMetadata(req InstanceMetadataUpsertRequest) (InstanceMetadataRecord, InstanceMetadataDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	tenantID := strings.TrimSpace(req.TenantID)
	instanceID := strings.TrimSpace(req.InstanceID)
	keyName := normalizeMetadataKey(req.Key)
	value := strings.TrimSpace(req.Value)
	visibility := normalizeMetadataVisibility(req.Visibility)

	decision := InstanceMetadataDecision{
		Decision:   InstanceMetadataDecisionDeny,
		Allowed:    false,
		TenantID:   tenantID,
		InstanceID: instanceID,
		Key:        keyName,
		Visibility: visibility,
		Reason:     InstanceMetadataReasonAllowed,
		CheckedAt:  now,
	}

	if r.config.RequireTenant && tenantID == "" {
		decision.Reason = InstanceMetadataReasonMissingTenant
		return InstanceMetadataRecord{}, decision, ErrInstanceMetadataMissingTenant
	}
	if instanceID == "" {
		decision.Reason = InstanceMetadataReasonMissingInstance
		return InstanceMetadataRecord{}, decision, ErrInstanceMetadataMissingInstance
	}
	if keyName == "" {
		decision.Reason = InstanceMetadataReasonMissingKey
		return InstanceMetadataRecord{}, decision, ErrInstanceMetadataMissingKey
	}
	if value == "" {
		decision.Reason = InstanceMetadataReasonMissingValue
		return InstanceMetadataRecord{}, decision, ErrInstanceMetadataMissingValue
	}
	if !r.visibilityAllowed(visibility) {
		decision.Reason = InstanceMetadataReasonInvalidVisibility
		return InstanceMetadataRecord{}, decision, ErrInstanceMetadataInvalidVisibility
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	instance, ok := r.instances[serviceInstanceKey(tenantID, instanceID)]
	if !ok {
		if r.instanceExistsInAnotherTenantLocked(tenantID, instanceID) {
			decision.Reason = InstanceMetadataReasonCrossTenant
			return InstanceMetadataRecord{}, decision, ErrInstanceMetadataCrossTenant
		}
		decision.Reason = InstanceMetadataReasonInstanceNotFound
		return InstanceMetadataRecord{}, decision, ErrInstanceMetadataInstanceNotFound
	}

	metadataKey := instanceMetadataKey(tenantID, instanceID, keyName)
	existing, exists := r.metadata[metadataKey]

	record := InstanceMetadataRecord{
		TenantID:      tenantID,
		MetadataID:    NewInstanceMetadataID(),
		ServiceID:     instance.ServiceID,
		InstanceID:    instance.InstanceID,
		ServiceName:   instance.ServiceName,
		Key:           keyName,
		Value:         value,
		Visibility:    visibility,
		Source:        strings.TrimSpace(req.Source),
		CorrelationID: strings.TrimSpace(req.CorrelationID),
		CreatedAt:     now,
		UpdatedAt:     now,
	}

	if exists {
		record.MetadataID = existing.MetadataID
		record.CreatedAt = existing.CreatedAt
	}

	r.metadata[metadataKey] = record

	decision.Decision = InstanceMetadataDecisionAllow
	decision.Allowed = true
	decision.ServiceID = record.ServiceID
	decision.ServiceName = record.ServiceName
	decision.Reason = InstanceMetadataReasonAllowed

	return record, decision, nil
}

func (r *InstanceMetadataRuntime) GetMetadata(tenantID string, instanceID string, keyName string) (InstanceMetadataRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	instanceID = strings.TrimSpace(instanceID)
	keyName = normalizeMetadataKey(keyName)

	if tenantID == "" {
		return InstanceMetadataRecord{}, ErrInstanceMetadataMissingTenant
	}
	if instanceID == "" {
		return InstanceMetadataRecord{}, ErrInstanceMetadataMissingInstance
	}
	if keyName == "" {
		return InstanceMetadataRecord{}, ErrInstanceMetadataMissingKey
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	if _, ok := r.instances[serviceInstanceKey(tenantID, instanceID)]; !ok {
		if r.instanceExistsInAnotherTenantLocked(tenantID, instanceID) {
			return InstanceMetadataRecord{}, ErrInstanceMetadataCrossTenant
		}
		return InstanceMetadataRecord{}, ErrInstanceMetadataInstanceNotFound
	}

	record, ok := r.metadata[instanceMetadataKey(tenantID, instanceID, keyName)]
	if !ok {
		return InstanceMetadataRecord{}, ErrInstanceMetadataMissingKey
	}
	if record.TenantID != tenantID {
		return InstanceMetadataRecord{}, ErrInstanceMetadataCrossTenant
	}

	return record, nil
}

func (r *InstanceMetadataRuntime) ListMetadataForInstance(tenantID string, instanceID string) ([]InstanceMetadataRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	instanceID = strings.TrimSpace(instanceID)

	if tenantID == "" {
		return nil, ErrInstanceMetadataMissingTenant
	}
	if instanceID == "" {
		return nil, ErrInstanceMetadataMissingInstance
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	if _, ok := r.instances[serviceInstanceKey(tenantID, instanceID)]; !ok {
		if r.instanceExistsInAnotherTenantLocked(tenantID, instanceID) {
			return nil, ErrInstanceMetadataCrossTenant
		}
		return nil, ErrInstanceMetadataInstanceNotFound
	}

	out := make([]InstanceMetadataRecord, 0)
	for _, record := range r.metadata {
		if record.TenantID == tenantID && record.InstanceID == instanceID {
			out = append(out, record)
		}
	}
	return out, nil
}

func (r *InstanceMetadataRuntime) ListTenantVisibleMetadata(tenantID string) ([]InstanceMetadataRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrInstanceMetadataMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]InstanceMetadataRecord, 0)
	for _, record := range r.metadata {
		if record.TenantID == tenantID && record.Visibility == InstanceMetadataVisibilityTenant {
			out = append(out, record)
		}
	}
	return out, nil
}

func (r *InstanceMetadataRuntime) ListTenantInstances(tenantID string) ([]ServiceInstanceRecord, error) {
	tenantID = strings.TrimSpace(tenantID)
	if tenantID == "" {
		return nil, ErrInstanceMetadataMissingTenant
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	out := make([]ServiceInstanceRecord, 0)
	for _, record := range r.instances {
		if record.TenantID == tenantID {
			out = append(out, record)
		}
	}
	return out, nil
}

func (r *InstanceMetadataRuntime) instanceExistsInAnotherTenantLocked(tenantID string, instanceID string) bool {
	for _, instance := range r.instances {
		if instance.InstanceID == instanceID && instance.TenantID != tenantID {
			return true
		}
	}
	return false
}

func (r *InstanceMetadataRuntime) statusAllowed(status string) bool {
	for _, allowed := range r.config.AllowedStatuses {
		if strings.EqualFold(strings.TrimSpace(allowed), strings.TrimSpace(status)) {
			return true
		}
	}
	return false
}

func (r *InstanceMetadataRuntime) visibilityAllowed(visibility string) bool {
	for _, allowed := range r.config.AllowedVisibilities {
		if strings.EqualFold(strings.TrimSpace(allowed), strings.TrimSpace(visibility)) {
			return true
		}
	}
	return false
}

func normalizeInstanceStatus(status string) string {
	status = strings.TrimSpace(status)
	if status == "" {
		return ServiceInstanceStatusRegistered
	}
	return strings.ToUpper(status)
}

func normalizeMetadataVisibility(visibility string) string {
	visibility = strings.TrimSpace(visibility)
	if visibility == "" {
		return InstanceMetadataVisibilityTenant
	}
	return strings.ToUpper(visibility)
}

func normalizeMetadataKey(key string) string {
	return strings.ToLower(strings.TrimSpace(key))
}

func serviceInstanceKey(tenantID string, instanceID string) string {
	return strings.TrimSpace(tenantID) + ":" + strings.TrimSpace(instanceID)
}

func instanceMetadataKey(tenantID string, instanceID string, keyName string) string {
	return strings.TrimSpace(tenantID) + ":" + strings.TrimSpace(instanceID) + ":" + normalizeMetadataKey(keyName)
}

func NewServiceInstanceServiceID() string {
	return randomOpsRuntimeID("svc_")
}

func NewServiceInstanceID() string {
	return randomOpsRuntimeID("instance_")
}

func NewInstanceMetadataID() string {
	return randomOpsRuntimeID("metadata_")
}

func randomOpsRuntimeID(prefix string) string {
	var raw [16]byte
	if _, err := rand.Read(raw[:]); err != nil {
		return prefix + strings.ReplaceAll(time.Now().UTC().Format("20060102150405.000000000"), ".", "")
	}
	return prefix + hex.EncodeToString(raw[:])
}
