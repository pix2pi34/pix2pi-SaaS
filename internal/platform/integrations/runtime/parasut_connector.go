package integrationruntime

import (
	"context"
	"fmt"
	"strings"
	"time"
)

const ParasutProviderKey = "parasut"

type ParasutEnvironment string

const (
	ParasutEnvironmentSimulation ParasutEnvironment = "SIMULATION"
	ParasutEnvironmentSandbox    ParasutEnvironment = "SANDBOX"
	ParasutEnvironmentProduction ParasutEnvironment = "PRODUCTION"
)

type ParasutConnectorConfig struct {
	TenantID          string
	AppKey            string
	Environment       ParasutEnvironment
	ClientID          string
	ClientSecret      string
	RedirectURI       string
	WebhookSecret     string
	Capabilities      []string
	ProductionEnabled bool
}

func DefaultParasutConnectorConfig(tenantID string) ParasutConnectorConfig {
	return ParasutConnectorConfig{
		TenantID:      normalize(tenantID),
		AppKey:        "parasut_accounting",
		Environment:   ParasutEnvironmentSimulation,
		WebhookSecret: "parasut-simulation-webhook-secret",
		Capabilities: []string{
			"invoice.pull",
			"invoice.push",
			"customer.sync",
			"product.sync",
			"webhook.verify",
		},
		ProductionEnabled: false,
	}
}

func ValidateParasutConnectorConfig(cfg ParasutConnectorConfig) error {
	if err := requireNonEmpty(cfg.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(cfg.AppKey, "app_key"); err != nil {
		return err
	}
	if cfg.Environment == "" {
		return fmt.Errorf("%w: parasut environment required", ErrInvalidIntegrationRequest)
	}
	if err := requireNonEmpty(cfg.WebhookSecret, "webhook_secret"); err != nil {
		return err
	}
	if len(cfg.Capabilities) == 0 {
		return fmt.Errorf("%w: parasut capabilities required", ErrInvalidIntegrationRequest)
	}
	if cfg.ProductionEnabled {
		return fmt.Errorf("%w: parasut production provider gate is closed", ErrInvalidIntegrationRequest)
	}
	if cfg.Environment == ParasutEnvironmentProduction {
		return fmt.Errorf("%w: parasut production environment is closed in foundation module", ErrInvalidIntegrationRequest)
	}
	if cfg.Environment == ParasutEnvironmentSandbox {
		if err := requireNonEmpty(cfg.ClientID, "client_id"); err != nil {
			return err
		}
		if err := requireNonEmpty(cfg.ClientSecret, "client_secret"); err != nil {
			return err
		}
	}
	return nil
}

type ParasutConnectorAdapter struct {
	config ParasutConnectorConfig
}

func NewParasutConnectorAdapter(cfg ParasutConnectorConfig) (*ParasutConnectorAdapter, error) {
	if err := ValidateParasutConnectorConfig(cfg); err != nil {
		return nil, err
	}
	return &ParasutConnectorAdapter{config: cfg}, nil
}

func (adapter *ParasutConnectorAdapter) ProviderKey() string {
	return ParasutProviderKey
}

func (adapter *ParasutConnectorAdapter) Capabilities() []string {
	return copySortedStrings(adapter.config.Capabilities)
}

func (adapter *ParasutConnectorAdapter) Execute(ctx context.Context, req OperationRequest) (OperationResult, error) {
	select {
	case <-ctx.Done():
		return OperationResult{}, ctx.Err()
	default:
	}

	if err := ValidateOperationRequest(req); err != nil {
		return OperationResult{}, err
	}
	if !strings.EqualFold(normalize(req.ProviderKey), ParasutProviderKey) {
		return OperationResult{}, fmt.Errorf("%w: provider_key must be parasut", ErrInvalidIntegrationRequest)
	}
	if normalize(req.TenantID) != adapter.config.TenantID {
		return OperationResult{}, fmt.Errorf("%w: tenant mismatch for parasut connector", ErrInvalidIntegrationRequest)
	}
	if normalize(req.AppKey) != adapter.config.AppKey {
		return OperationResult{}, fmt.Errorf("%w: app_key mismatch for parasut connector", ErrInvalidIntegrationRequest)
	}
	if !adapter.supportsOperation(req.Operation) {
		return OperationResult{}, fmt.Errorf("%w: unsupported parasut operation %s", ErrInvalidIntegrationRequest, req.Operation)
	}

	return OperationResult{
		TenantID:              normalize(req.TenantID),
		ProviderKey:           ParasutProviderKey,
		AppKey:                normalize(req.AppKey),
		Operation:             req.Operation,
		IdempotencyKey:        normalize(req.IdempotencyKey),
		CorrelationID:         normalize(req.CorrelationID),
		Succeeded:             true,
		ProviderTransactionID: adapter.simulatedProviderTransactionID(req),
		Message:               "parasut connector operation simulated successfully",
	}, nil
}

func (adapter *ParasutConnectorAdapter) supportsOperation(operation ConnectorOperation) bool {
	switch operation {
	case ConnectorOperationPullInvoice,
		ConnectorOperationPushInvoice,
		ConnectorOperationSyncCustomer,
		ConnectorOperationSyncProduct,
		ConnectorOperationVerifyWebhook:
		return true
	default:
		return false
	}
}

func (adapter *ParasutConnectorAdapter) simulatedProviderTransactionID(req OperationRequest) string {
	return fmt.Sprintf("parasut-sim-%s-%s", strings.ToLower(string(req.Operation)), normalize(req.IdempotencyKey))
}

type ParasutInvoiceDraftRequest struct {
	TenantID      string
	CustomerTaxNo string
	InvoiceNo     string
	AmountMinor   int64
	Currency      string
	CorrelationID string
}

type ParasutInvoiceDraft struct {
	TenantID      string
	ProviderKey   string
	CustomerTaxNo string
	InvoiceNo     string
	AmountMinor   int64
	Currency      string
	CorrelationID string
	ProviderReady bool
}

func BuildParasutInvoiceDraft(req ParasutInvoiceDraftRequest) (ParasutInvoiceDraft, error) {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return ParasutInvoiceDraft{}, err
	}
	if err := requireNonEmpty(req.CustomerTaxNo, "customer_tax_no"); err != nil {
		return ParasutInvoiceDraft{}, err
	}
	if err := requireNonEmpty(req.InvoiceNo, "invoice_no"); err != nil {
		return ParasutInvoiceDraft{}, err
	}
	if err := requireNonEmpty(req.Currency, "currency"); err != nil {
		return ParasutInvoiceDraft{}, err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return ParasutInvoiceDraft{}, err
	}
	if req.AmountMinor <= 0 {
		return ParasutInvoiceDraft{}, fmt.Errorf("%w: amount_minor must be positive", ErrInvalidIntegrationRequest)
	}

	return ParasutInvoiceDraft{
		TenantID:      normalize(req.TenantID),
		ProviderKey:   ParasutProviderKey,
		CustomerTaxNo: normalize(req.CustomerTaxNo),
		InvoiceNo:     normalize(req.InvoiceNo),
		AmountMinor:   req.AmountMinor,
		Currency:      strings.ToUpper(normalize(req.Currency)),
		CorrelationID: normalize(req.CorrelationID),
		ProviderReady: true,
	}, nil
}

type ParasutWebhookBridge struct {
	WebhookSecret string
	IntakeRuntime WebhookIntakeRuntime
}

func NewParasutWebhookBridge(webhookSecret string) (ParasutWebhookBridge, error) {
	if err := requireNonEmpty(webhookSecret, "webhook_secret"); err != nil {
		return ParasutWebhookBridge{}, err
	}
	return ParasutWebhookBridge{
		WebhookSecret: webhookSecret,
		IntakeRuntime: DefaultWebhookIntakeRuntime(),
	}, nil
}

func BuildParasutWebhookSignature(secret string, timestamp time.Time, rawPayload string) string {
	return BuildWebhookSignature(secret, timestamp, rawPayload)
}

func (bridge ParasutWebhookBridge) Verify(req ExternalEventIntakeRequest) (ExternalEvent, error) {
	if !strings.EqualFold(normalize(req.ProviderKey), ParasutProviderKey) {
		return ExternalEvent{}, fmt.Errorf("%w: provider_key must be parasut", ErrInvalidIntegrationRequest)
	}

	if normalize(req.Secret) == "" {
		req.Secret = bridge.WebhookSecret
	}
	if normalize(req.Signature) == "" {
		return ExternalEvent{}, fmt.Errorf("%w: parasut webhook signature required", ErrInvalidIntegrationRequest)
	}

	return bridge.IntakeRuntime.VerifyAndBuildEvent(req)
}

type ParasutConnectorModuleGateInput struct {
	ConfigReady                  bool
	AdapterReady                 bool
	MappingReady                 bool
	WebhookBridgeReady           bool
	RetryDLQBridgeReady          bool
	TestsReady                   bool
	RealImplementationAuditReady bool
	ProductionEnabled            bool
}

type ParasutConnectorModuleGateResult struct {
	Ready    bool
	Decision string
	Blockers []string
}

func EvaluateParasutConnectorModuleGate(input ParasutConnectorModuleGateInput) ParasutConnectorModuleGateResult {
	blockers := []string{}

	if !input.ConfigReady {
		blockers = append(blockers, "parasut_config_not_ready")
	}
	if !input.AdapterReady {
		blockers = append(blockers, "parasut_adapter_not_ready")
	}
	if !input.MappingReady {
		blockers = append(blockers, "parasut_mapping_not_ready")
	}
	if !input.WebhookBridgeReady {
		blockers = append(blockers, "parasut_webhook_bridge_not_ready")
	}
	if !input.RetryDLQBridgeReady {
		blockers = append(blockers, "parasut_retry_dlq_bridge_not_ready")
	}
	if !input.TestsReady {
		blockers = append(blockers, "parasut_tests_not_ready")
	}
	if !input.RealImplementationAuditReady {
		blockers = append(blockers, "parasut_real_implementation_audit_not_ready")
	}
	if input.ProductionEnabled {
		blockers = append(blockers, "parasut_production_gate_must_remain_closed")
	}

	if len(blockers) > 0 {
		return ParasutConnectorModuleGateResult{
			Ready:    false,
			Decision: "BLOCKED",
			Blockers: blockers,
		}
	}

	return ParasutConnectorModuleGateResult{
		Ready:    true,
		Decision: "PARASUT_CONNECTOR_FOUNDATION_READY",
		Blockers: []string{},
	}
}
