package mikro

import (
	"errors"
	"fmt"
	"strings"
)

const (
	Phase                       = "FAZ_7_8M"
	ProviderID                  = "mikro"
	ProviderName                = "Mikro"
	ProviderCategory            = "ACCOUNTING_EXPORT_PROVIDER"
	ConnectorFamily             = "MIKRO_DRY_RUN_CONNECTOR"
	ModuleName                  = "Mikro Connector Module Foundation"
	ModuleStatusReady           = "READY"
	ConnectorModeDryRunContract = "DRY_RUN_CONTRACT_ONLY"
	ConnectorModeSimulationOnly = "SIMULATION_ONLY"

	MikroConnectorFoundationGate  = "READY"
	MikroProviderLiveHandoffGate  = "CLOSED_UNTIL_MIKRO_CONNECTOR_FINAL_CLOSURE"
	MikroRealProviderAPIStatus    = "CLOSED_UNTIL_PROVIDER_LIVE_MODULE"
	MikroRealFileDeliveryStatus   = "CLOSED_UNTIL_IMPORT_DELIVERY_LIVE_MODULE"
	MikroRealERPWriteStatus       = "CLOSED_UNTIL_SYNC_WORKER_LIVE_MODULE"
	DecisionAllowedDryRunReady    = "MIKRO_DRY_RUN_FOUNDATION_READY"
	DecisionDeniedRealAPICall     = "MIKRO_REAL_PROVIDER_API_CLOSED"
	DecisionDeniedFileDelivery    = "MIKRO_REAL_FILE_DELIVERY_CLOSED"
	DecisionDeniedERPWrite        = "MIKRO_REAL_ERP_WRITE_CLOSED"
	DecisionDeniedUnsupported     = "MIKRO_OPERATION_UNSUPPORTED"
	DecisionDeniedProviderLive    = "MIKRO_PROVIDER_LIVE_MODE_CLOSED"
	DecisionDeniedSecretValueUsed = "MIKRO_SECRET_VALUE_FORBIDDEN"
)

var (
	ErrInvalidFoundation = errors.New("invalid mikro connector foundation")
	ErrInvalidRequest    = errors.New("invalid mikro connector request")
	ErrSecretForbidden   = errors.New("mikro secret value is forbidden in foundation module")
)

type Capability struct {
	Code      string
	Direction string
	Status    string
}

type Foundation struct {
	Phase                      string
	ProviderID                 string
	ProviderName               string
	ProviderCategory           string
	ConnectorFamily            string
	ModuleName                 string
	ModuleStatus               string
	ConnectorMode              string
	FoundationGate             string
	ProviderLiveHandoffGate    string
	RealProviderAPIStatus      string
	RealFileDeliveryStatus     string
	RealERPWriteStatus         string
	SupportedCapabilities      []Capability
	RequiredContextFields      []string
	ForbiddenSecretFieldLabels []string
}

type FoundationRequest struct {
	TenantID                string
	ActorUserID             string
	CorrelationID           string
	Operation               string
	RequestedMode           string
	ClientSecret            string
	AccessToken             string
	RefreshToken            string
	RealPassword            string
	RealProviderEndpoint    string
	RealDeliveryEndpoint    string
	RealProviderAPIEnabled  bool
	RealFileDeliveryEnabled bool
	RealERPWriteEnabled     bool
}

type FoundationDecision struct {
	Allowed                bool
	Phase                  string
	ProviderID             string
	ProviderName           string
	Operation              string
	RequestedMode          string
	Reason                 string
	CapabilityFound        bool
	RealProviderAPIStatus  string
	RealFileDeliveryStatus string
	RealERPWriteStatus     string
	FoundationGate         string
	ProviderLiveGate       string
	AuditFields            map[string]string
}

func NewFoundation() Foundation {
	return Foundation{
		Phase:                   Phase,
		ProviderID:              ProviderID,
		ProviderName:            ProviderName,
		ProviderCategory:        ProviderCategory,
		ConnectorFamily:         ConnectorFamily,
		ModuleName:              ModuleName,
		ModuleStatus:            ModuleStatusReady,
		ConnectorMode:           ConnectorModeDryRunContract,
		FoundationGate:          MikroConnectorFoundationGate,
		ProviderLiveHandoffGate: MikroProviderLiveHandoffGate,
		RealProviderAPIStatus:   MikroRealProviderAPIStatus,
		RealFileDeliveryStatus:  MikroRealFileDeliveryStatus,
		RealERPWriteStatus:      MikroRealERPWriteStatus,
		RequiredContextFields: []string{
			"tenant_id",
			"actor_user_id",
			"correlation_id",
			"operation",
		},
		ForbiddenSecretFieldLabels: []string{
			"client_secret",
			"access_token",
			"refresh_token",
			"real_password",
			"real_provider_endpoint",
			"real_delivery_endpoint",
		},
		SupportedCapabilities: []Capability{
			{Code: "CUSTOMER_EXPORT", Direction: "PIX2PI_TO_MIKRO", Status: "DRY_RUN_DECLARED"},
			{Code: "VENDOR_EXPORT", Direction: "PIX2PI_TO_MIKRO", Status: "DRY_RUN_DECLARED"},
			{Code: "PRODUCT_EXPORT", Direction: "PIX2PI_TO_MIKRO", Status: "DRY_RUN_DECLARED"},
			{Code: "INVOICE_EXPORT", Direction: "PIX2PI_TO_MIKRO", Status: "DRY_RUN_DECLARED"},
			{Code: "ACCOUNTING_VOUCHER_EXPORT", Direction: "PIX2PI_TO_MIKRO", Status: "DRY_RUN_DECLARED"},
			{Code: "STOCK_MOVEMENT_EXPORT", Direction: "PIX2PI_TO_MIKRO", Status: "DRY_RUN_DECLARED"},
			{Code: "IMPORT_PACKAGE_DRY_RUN", Direction: "PIX2PI_TO_MIKRO", Status: "DRY_RUN_DECLARED"},
		},
	}
}

func (f Foundation) Validate() error {
	if strings.TrimSpace(f.Phase) != Phase {
		return fmt.Errorf("%w: phase must be %s", ErrInvalidFoundation, Phase)
	}
	if strings.TrimSpace(f.ProviderID) != ProviderID {
		return fmt.Errorf("%w: provider_id must be %s", ErrInvalidFoundation, ProviderID)
	}
	if strings.TrimSpace(f.ProviderName) != ProviderName {
		return fmt.Errorf("%w: provider_name must be %s", ErrInvalidFoundation, ProviderName)
	}
	if strings.TrimSpace(f.ModuleStatus) != ModuleStatusReady {
		return fmt.Errorf("%w: module_status must be ready", ErrInvalidFoundation)
	}
	if strings.TrimSpace(f.ConnectorMode) != ConnectorModeDryRunContract {
		return fmt.Errorf("%w: connector mode must be dry-run contract only", ErrInvalidFoundation)
	}
	if f.RealProviderAPIStatus != MikroRealProviderAPIStatus {
		return fmt.Errorf("%w: real provider API must stay closed", ErrInvalidFoundation)
	}
	if f.RealFileDeliveryStatus != MikroRealFileDeliveryStatus {
		return fmt.Errorf("%w: real file delivery must stay closed", ErrInvalidFoundation)
	}
	if f.RealERPWriteStatus != MikroRealERPWriteStatus {
		return fmt.Errorf("%w: real ERP write must stay closed", ErrInvalidFoundation)
	}
	if f.ProviderLiveHandoffGate != MikroProviderLiveHandoffGate {
		return fmt.Errorf("%w: provider live handoff gate must stay closed until final closure", ErrInvalidFoundation)
	}
	if len(f.SupportedCapabilities) == 0 {
		return fmt.Errorf("%w: supported capabilities are required", ErrInvalidFoundation)
	}
	if len(f.RequiredContextFields) < 4 {
		return fmt.Errorf("%w: required context fields are incomplete", ErrInvalidFoundation)
	}
	if len(f.ForbiddenSecretFieldLabels) == 0 {
		return fmt.Errorf("%w: forbidden secret fields are required", ErrInvalidFoundation)
	}
	return nil
}

func (f Foundation) Supports(operation string) bool {
	normalized := normalize(operation)
	for _, capability := range f.SupportedCapabilities {
		if capability.Code == normalized {
			return true
		}
	}
	return false
}

func (f Foundation) Evaluate(req FoundationRequest) (FoundationDecision, error) {
	decision := FoundationDecision{
		Allowed:                false,
		Phase:                  f.Phase,
		ProviderID:             f.ProviderID,
		ProviderName:           f.ProviderName,
		Operation:              normalize(req.Operation),
		RequestedMode:          normalize(req.RequestedMode),
		RealProviderAPIStatus:  f.RealProviderAPIStatus,
		RealFileDeliveryStatus: f.RealFileDeliveryStatus,
		RealERPWriteStatus:     f.RealERPWriteStatus,
		FoundationGate:         f.FoundationGate,
		ProviderLiveGate:       f.ProviderLiveHandoffGate,
		AuditFields: map[string]string{
			"tenant_id":      strings.TrimSpace(req.TenantID),
			"actor_user_id":  strings.TrimSpace(req.ActorUserID),
			"correlation_id": strings.TrimSpace(req.CorrelationID),
			"provider_id":    f.ProviderID,
			"phase":          f.Phase,
		},
	}

	if err := f.Validate(); err != nil {
		return decision, err
	}

	if err := validateRequiredContext(req); err != nil {
		return decision, err
	}

	if containsSecretValue(req) {
		decision.Reason = DecisionDeniedSecretValueUsed
		return decision, ErrSecretForbidden
	}

	if normalize(req.RequestedMode) == "PROVIDER_LIVE" {
		decision.Reason = DecisionDeniedProviderLive
		return decision, nil
	}

	if req.RealProviderAPIEnabled {
		decision.Reason = DecisionDeniedRealAPICall
		return decision, nil
	}

	if req.RealFileDeliveryEnabled {
		decision.Reason = DecisionDeniedFileDelivery
		return decision, nil
	}

	if req.RealERPWriteEnabled {
		decision.Reason = DecisionDeniedERPWrite
		return decision, nil
	}

	decision.CapabilityFound = f.Supports(req.Operation)
	if !decision.CapabilityFound {
		decision.Reason = DecisionDeniedUnsupported
		return decision, nil
	}

	mode := normalize(req.RequestedMode)
	if mode == "" {
		mode = ConnectorModeDryRunContract
		decision.RequestedMode = mode
	}

	if mode != ConnectorModeDryRunContract && mode != ConnectorModeSimulationOnly {
		decision.Reason = DecisionDeniedProviderLive
		return decision, nil
	}

	decision.Allowed = true
	decision.Reason = DecisionAllowedDryRunReady
	return decision, nil
}

func validateRequiredContext(req FoundationRequest) error {
	if strings.TrimSpace(req.TenantID) == "" {
		return fmt.Errorf("%w: tenant_id is required", ErrInvalidRequest)
	}
	if strings.TrimSpace(req.ActorUserID) == "" {
		return fmt.Errorf("%w: actor_user_id is required", ErrInvalidRequest)
	}
	if strings.TrimSpace(req.CorrelationID) == "" {
		return fmt.Errorf("%w: correlation_id is required", ErrInvalidRequest)
	}
	if strings.TrimSpace(req.Operation) == "" {
		return fmt.Errorf("%w: operation is required", ErrInvalidRequest)
	}
	return nil
}

func containsSecretValue(req FoundationRequest) bool {
	return strings.TrimSpace(req.ClientSecret) != "" ||
		strings.TrimSpace(req.AccessToken) != "" ||
		strings.TrimSpace(req.RefreshToken) != "" ||
		strings.TrimSpace(req.RealPassword) != "" ||
		strings.TrimSpace(req.RealProviderEndpoint) != "" ||
		strings.TrimSpace(req.RealDeliveryEndpoint) != ""
}

func normalize(value string) string {
	return strings.ToUpper(strings.TrimSpace(value))
}
