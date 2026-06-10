package integrationruntime

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"
)

var ErrInvalidIntegrationRequest = errors.New("invalid integration request")

type IntegrationInstallStatus string

const (
	IntegrationInstallStatusEnabled  IntegrationInstallStatus = "ENABLED"
	IntegrationInstallStatusDisabled IntegrationInstallStatus = "DISABLED"
)

type AuthMode string

const (
	AuthModeAPIKey AuthMode = "API_KEY"
	AuthModeOAuth2 AuthMode = "OAUTH2"
	AuthModeNone   AuthMode = "NONE"
)

type AuditDecision string

const (
	AuditDecisionAllowed AuditDecision = "ALLOWED"
	AuditDecisionDenied  AuditDecision = "DENIED"
)

type EnableTenantIntegrationRequest struct {
	TenantID          string
	ProviderKey       string
	AppKey            string
	AuthMode          AuthMode
	Capabilities      []string
	Config            map[string]string
	RequestedBy       string
	CorrelationID     string
	ProductionEnabled bool
	RequestedAt       time.Time
}

type TenantIntegrationInstallation struct {
	TenantID      string
	ProviderKey   string
	AppKey        string
	Status        IntegrationInstallStatus
	AuthMode      AuthMode
	Capabilities  []string
	Config        map[string]string
	RequestedBy   string
	CorrelationID string
	AuditDecision AuditDecision
	EnabledAt     time.Time
}

func EnableTenantIntegration(req EnableTenantIntegrationRequest) (TenantIntegrationInstallation, error) {
	if err := validateEnableTenantIntegrationRequest(req); err != nil {
		return TenantIntegrationInstallation{AuditDecision: AuditDecisionDenied}, err
	}

	now := req.RequestedAt
	if now.IsZero() {
		now = time.Now().UTC()
	}

	return TenantIntegrationInstallation{
		TenantID:      normalize(req.TenantID),
		ProviderKey:   normalize(req.ProviderKey),
		AppKey:        normalize(req.AppKey),
		Status:        IntegrationInstallStatusEnabled,
		AuthMode:      req.AuthMode,
		Capabilities:  copySortedStrings(req.Capabilities),
		Config:        copyStringMap(req.Config),
		RequestedBy:   normalize(req.RequestedBy),
		CorrelationID: normalize(req.CorrelationID),
		AuditDecision: AuditDecisionAllowed,
		EnabledAt:     now,
	}, nil
}

func validateEnableTenantIntegrationRequest(req EnableTenantIntegrationRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.ProviderKey, "provider_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.RequestedBy, "requested_by"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if req.AuthMode == "" {
		return fmt.Errorf("%w: auth_mode required", ErrInvalidIntegrationRequest)
	}
	if len(req.Capabilities) == 0 {
		return fmt.Errorf("%w: at least one capability required", ErrInvalidIntegrationRequest)
	}
	if req.ProductionEnabled {
		return fmt.Errorf("%w: production provider enablement is closed in foundation runtime", ErrInvalidIntegrationRequest)
	}
	return nil
}

func requireNonEmpty(value string, field string) error {
	if normalize(value) == "" {
		return fmt.Errorf("%w: %s required", ErrInvalidIntegrationRequest, field)
	}
	return nil
}

func normalize(value string) string {
	return strings.TrimSpace(value)
}

func copyStringMap(in map[string]string) map[string]string {
	out := map[string]string{}
	for k, v := range in {
		out[k] = v
	}
	return out
}

func copySortedStrings(in []string) []string {
	out := append([]string(nil), in...)
	sort.Strings(out)
	return out
}
