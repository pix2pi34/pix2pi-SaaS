package opsruntime

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"
)

const (
	ServiceRegistrationEndpointPath = "/ops/registry/register"

	ServiceRegistrationEndpointDecisionAllow = "ALLOW"
	ServiceRegistrationEndpointDecisionDeny  = "DENY"

	ServiceRegistrationEndpointReasonAllowed         = "SERVICE_REGISTRATION_ENDPOINT_ALLOWED"
	ServiceRegistrationEndpointReasonMissingRegistry = "SERVICE_REGISTRATION_ENDPOINT_MISSING_REGISTRY"
	ServiceRegistrationEndpointReasonInvalidMethod   = "SERVICE_REGISTRATION_ENDPOINT_INVALID_METHOD"
	ServiceRegistrationEndpointReasonInvalidPath     = "SERVICE_REGISTRATION_ENDPOINT_INVALID_PATH"
	ServiceRegistrationEndpointReasonMissingTenant   = "SERVICE_REGISTRATION_ENDPOINT_MISSING_TENANT"
	ServiceRegistrationEndpointReasonInvalidBody     = "SERVICE_REGISTRATION_ENDPOINT_INVALID_BODY"
	ServiceRegistrationEndpointReasonCrossTenant     = "SERVICE_REGISTRATION_ENDPOINT_CROSS_TENANT_DENIED"
	ServiceRegistrationEndpointReasonRegisterFailed  = "SERVICE_REGISTRATION_ENDPOINT_REGISTER_FAILED"
	ServiceRegistrationEndpointReasonMetadataFailed  = "SERVICE_REGISTRATION_ENDPOINT_METADATA_FAILED"
)

var (
	ErrServiceRegistrationEndpointMissingRegistry = errors.New("missing service registration registry")
	ErrServiceRegistrationEndpointInvalidMethod   = errors.New("invalid service registration endpoint method")
	ErrServiceRegistrationEndpointInvalidPath     = errors.New("invalid service registration endpoint path")
	ErrServiceRegistrationEndpointMissingTenant   = errors.New("missing service registration endpoint tenant")
	ErrServiceRegistrationEndpointInvalidBody     = errors.New("invalid service registration endpoint body")
	ErrServiceRegistrationEndpointCrossTenant     = errors.New("cross-tenant service registration denied")
	ErrServiceRegistrationEndpointRegisterFailed  = errors.New("service registration failed")
	ErrServiceRegistrationEndpointMetadataFailed  = errors.New("service registration metadata failed")
)

type ServiceRegistrationEndpointRuntimeConfig struct {
	Path                      string `json:"path"`
	RequireTenantHeader       bool   `json:"require_tenant_header"`
	TenantHeaderName          string `json:"tenant_header_name"`
	AllowBodyTenantFallback   bool   `json:"allow_body_tenant_fallback"`
	AllowMetadataPersistence  bool   `json:"allow_metadata_persistence"`
	DefaultMetadataVisibility string `json:"default_metadata_visibility"`
}

func DefaultServiceRegistrationEndpointRuntimeConfig() ServiceRegistrationEndpointRuntimeConfig {
	return ServiceRegistrationEndpointRuntimeConfig{
		Path:                      ServiceRegistrationEndpointPath,
		RequireTenantHeader:       true,
		TenantHeaderName:          "X-Tenant-ID",
		AllowBodyTenantFallback:   false,
		AllowMetadataPersistence:  true,
		DefaultMetadataVisibility: InstanceMetadataVisibilityInternal,
	}
}

type ServiceRegistrationEndpointRequest struct {
	TenantID           string            `json:"tenant_id,omitempty"`
	ServiceID          string            `json:"service_id,omitempty"`
	InstanceID         string            `json:"instance_id,omitempty"`
	ServiceName        string            `json:"service_name"`
	Host               string            `json:"host,omitempty"`
	Port               int               `json:"port,omitempty"`
	Zone               string            `json:"zone,omitempty"`
	NodeID             string            `json:"node_id,omitempty"`
	Runtime            string            `json:"runtime,omitempty"`
	Version            string            `json:"version,omitempty"`
	Status             string            `json:"status,omitempty"`
	Metadata           map[string]string `json:"metadata,omitempty"`
	MetadataVisibility string            `json:"metadata_visibility,omitempty"`
	CorrelationID      string            `json:"correlation_id,omitempty"`
}

type ServiceRegistrationEndpointResponse struct {
	OK             bool                     `json:"ok"`
	TenantID       string                   `json:"tenant_id"`
	ServiceID      string                   `json:"service_id"`
	InstanceID     string                   `json:"instance_id"`
	ServiceName    string                   `json:"service_name"`
	Status         string                   `json:"status"`
	MetadataCount  int                      `json:"metadata_count"`
	Instance       ServiceInstanceRecord    `json:"instance"`
	Metadata       []InstanceMetadataRecord `json:"metadata,omitempty"`
	DecisionReason string                   `json:"decision_reason"`
	CorrelationID  string                   `json:"correlation_id,omitempty"`
	RegisteredAt   string                   `json:"registered_at"`
}

type ServiceRegistrationEndpointDecision struct {
	Decision      string `json:"decision"`
	Allowed       bool   `json:"allowed"`
	TenantID      string `json:"tenant_id"`
	ServiceID     string `json:"service_id,omitempty"`
	InstanceID    string `json:"instance_id,omitempty"`
	ServiceName   string `json:"service_name,omitempty"`
	MetadataCount int    `json:"metadata_count"`
	Method        string `json:"method,omitempty"`
	Path          string `json:"path,omitempty"`
	HTTPStatus    int    `json:"http_status"`
	CorrelationID string `json:"correlation_id,omitempty"`
	Reason        string `json:"reason"`
	CheckedAt     string `json:"checked_at"`
}

type ServiceRegistrationEndpointRuntime struct {
	config   ServiceRegistrationEndpointRuntimeConfig
	registry *InstanceMetadataRuntime
}

func NewServiceRegistrationEndpointRuntime(config ServiceRegistrationEndpointRuntimeConfig, registry *InstanceMetadataRuntime) *ServiceRegistrationEndpointRuntime {
	defaults := DefaultServiceRegistrationEndpointRuntimeConfig()

	if strings.TrimSpace(config.Path) == "" {
		config.Path = defaults.Path
	}
	if strings.TrimSpace(config.TenantHeaderName) == "" {
		config.TenantHeaderName = defaults.TenantHeaderName
	}
	if strings.TrimSpace(config.DefaultMetadataVisibility) == "" {
		config.DefaultMetadataVisibility = defaults.DefaultMetadataVisibility
	}

	return &ServiceRegistrationEndpointRuntime{
		config:   config,
		registry: registry,
	}
}

func (r *ServiceRegistrationEndpointRuntime) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	response, decision, err := r.HandleRegistrationRequest(req)
	status := decision.HTTPStatus
	if status == 0 {
		status = http.StatusOK
	}

	if err != nil {
		writeServiceRegistrationEndpointJSON(w, status, map[string]any{
			"ok":       false,
			"error":    err.Error(),
			"decision": decision,
		})
		return
	}

	writeServiceRegistrationEndpointJSON(w, status, response)
}

func (r *ServiceRegistrationEndpointRuntime) HandleRegistrationRequest(req *http.Request) (ServiceRegistrationEndpointResponse, ServiceRegistrationEndpointDecision, error) {
	now := time.Now().UTC().Format(time.RFC3339Nano)

	decision := ServiceRegistrationEndpointDecision{
		Decision:   ServiceRegistrationEndpointDecisionDeny,
		Allowed:    false,
		Method:     "",
		Path:       "",
		HTTPStatus: http.StatusInternalServerError,
		Reason:     ServiceRegistrationEndpointReasonAllowed,
		CheckedAt:  now,
	}

	if req != nil {
		decision.Method = req.Method
		decision.Path = req.URL.Path
	}

	if r.registry == nil {
		decision.Reason = ServiceRegistrationEndpointReasonMissingRegistry
		decision.HTTPStatus = http.StatusInternalServerError
		return ServiceRegistrationEndpointResponse{}, decision, ErrServiceRegistrationEndpointMissingRegistry
	}

	if req == nil {
		decision.Reason = ServiceRegistrationEndpointReasonInvalidBody
		decision.HTTPStatus = http.StatusBadRequest
		return ServiceRegistrationEndpointResponse{}, decision, ErrServiceRegistrationEndpointInvalidBody
	}

	if req.Method != http.MethodPost {
		decision.Reason = ServiceRegistrationEndpointReasonInvalidMethod
		decision.HTTPStatus = http.StatusMethodNotAllowed
		return ServiceRegistrationEndpointResponse{}, decision, ErrServiceRegistrationEndpointInvalidMethod
	}

	if req.URL.Path != r.config.Path {
		decision.Reason = ServiceRegistrationEndpointReasonInvalidPath
		decision.HTTPStatus = http.StatusNotFound
		return ServiceRegistrationEndpointResponse{}, decision, ErrServiceRegistrationEndpointInvalidPath
	}

	var body ServiceRegistrationEndpointRequest
	decoder := json.NewDecoder(req.Body)
	if err := decoder.Decode(&body); err != nil {
		decision.Reason = ServiceRegistrationEndpointReasonInvalidBody
		decision.HTTPStatus = http.StatusBadRequest
		return ServiceRegistrationEndpointResponse{}, decision, ErrServiceRegistrationEndpointInvalidBody
	}

	headerTenantID := strings.TrimSpace(req.Header.Get(r.config.TenantHeaderName))
	bodyTenantID := strings.TrimSpace(body.TenantID)
	tenantID := headerTenantID

	if tenantID == "" && r.config.AllowBodyTenantFallback {
		tenantID = bodyTenantID
	}

	decision.TenantID = tenantID
	decision.ServiceName = strings.TrimSpace(body.ServiceName)
	decision.CorrelationID = strings.TrimSpace(body.CorrelationID)

	if r.config.RequireTenantHeader && headerTenantID == "" {
		decision.Reason = ServiceRegistrationEndpointReasonMissingTenant
		decision.HTTPStatus = http.StatusBadRequest
		return ServiceRegistrationEndpointResponse{}, decision, ErrServiceRegistrationEndpointMissingTenant
	}

	if tenantID == "" {
		decision.Reason = ServiceRegistrationEndpointReasonMissingTenant
		decision.HTTPStatus = http.StatusBadRequest
		return ServiceRegistrationEndpointResponse{}, decision, ErrServiceRegistrationEndpointMissingTenant
	}

	if bodyTenantID != "" && bodyTenantID != tenantID {
		decision.Reason = ServiceRegistrationEndpointReasonCrossTenant
		decision.HTTPStatus = http.StatusForbidden
		return ServiceRegistrationEndpointResponse{}, decision, ErrServiceRegistrationEndpointCrossTenant
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
		Status:        strings.TrimSpace(body.Status),
		CorrelationID: strings.TrimSpace(body.CorrelationID),
	})
	if err != nil || !registerDecision.Allowed {
		decision.Reason = ServiceRegistrationEndpointReasonRegisterFailed
		decision.HTTPStatus = http.StatusBadRequest
		return ServiceRegistrationEndpointResponse{}, decision, ErrServiceRegistrationEndpointRegisterFailed
	}

	decision.ServiceID = instance.ServiceID
	decision.InstanceID = instance.InstanceID
	decision.ServiceName = instance.ServiceName

	visibility := normalizeMetadataVisibility(body.MetadataVisibility)
	if strings.TrimSpace(body.MetadataVisibility) == "" {
		visibility = normalizeMetadataVisibility(r.config.DefaultMetadataVisibility)
	}

	metadataRecords := make([]InstanceMetadataRecord, 0)

	if r.config.AllowMetadataPersistence {
		for key, value := range body.Metadata {
			key = strings.TrimSpace(key)
			value = strings.TrimSpace(value)

			if key == "" || value == "" {
				continue
			}

			metadata, metadataDecision, err := r.registry.UpsertMetadata(InstanceMetadataUpsertRequest{
				TenantID:      tenantID,
				InstanceID:    instance.InstanceID,
				Key:           key,
				Value:         value,
				Visibility:    visibility,
				Source:        "service_registration_endpoint",
				CorrelationID: strings.TrimSpace(body.CorrelationID),
			})
			if err != nil || !metadataDecision.Allowed {
				decision.Reason = ServiceRegistrationEndpointReasonMetadataFailed
				decision.HTTPStatus = http.StatusBadRequest
				return ServiceRegistrationEndpointResponse{}, decision, ErrServiceRegistrationEndpointMetadataFailed
			}
			metadataRecords = append(metadataRecords, metadata)
		}
	}

	decision.Decision = ServiceRegistrationEndpointDecisionAllow
	decision.Allowed = true
	decision.HTTPStatus = http.StatusOK
	decision.MetadataCount = len(metadataRecords)
	decision.Reason = ServiceRegistrationEndpointReasonAllowed

	response := ServiceRegistrationEndpointResponse{
		OK:             true,
		TenantID:       tenantID,
		ServiceID:      instance.ServiceID,
		InstanceID:     instance.InstanceID,
		ServiceName:    instance.ServiceName,
		Status:         instance.Status,
		MetadataCount:  len(metadataRecords),
		Instance:       instance,
		Metadata:       metadataRecords,
		DecisionReason: ServiceRegistrationEndpointReasonAllowed,
		CorrelationID:  strings.TrimSpace(body.CorrelationID),
		RegisteredAt:   instance.RegisteredAt,
	}

	return response, decision, nil
}

func writeServiceRegistrationEndpointJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}
