package integrationruntime

import (
	"context"
	"fmt"
	"sync"
)

type ConnectorOperation string

const (
	ConnectorOperationPullInvoice   ConnectorOperation = "PULL_INVOICE"
	ConnectorOperationPushInvoice   ConnectorOperation = "PUSH_INVOICE"
	ConnectorOperationSyncCustomer  ConnectorOperation = "SYNC_CUSTOMER"
	ConnectorOperationSyncProduct   ConnectorOperation = "SYNC_PRODUCT"
	ConnectorOperationVerifyWebhook ConnectorOperation = "VERIFY_WEBHOOK"
)

type OperationRequest struct {
	TenantID       string
	ProviderKey    string
	AppKey         string
	Operation      ConnectorOperation
	IdempotencyKey string
	CorrelationID  string
	Payload        map[string]string
}

type OperationResult struct {
	TenantID              string
	ProviderKey           string
	AppKey                string
	Operation             ConnectorOperation
	IdempotencyKey        string
	CorrelationID         string
	Succeeded             bool
	ProviderTransactionID string
	Message               string
}

type ConnectorAdapter interface {
	ProviderKey() string
	Capabilities() []string
	Execute(ctx context.Context, req OperationRequest) (OperationResult, error)
}

type AdapterSDK struct {
	mu       sync.RWMutex
	adapters map[string]ConnectorAdapter
}

func NewAdapterSDK() *AdapterSDK {
	return &AdapterSDK{
		adapters: map[string]ConnectorAdapter{},
	}
}

func (sdk *AdapterSDK) RegisterAdapter(adapter ConnectorAdapter) error {
	if adapter == nil {
		return fmt.Errorf("%w: connector adapter is nil", ErrInvalidIntegrationRequest)
	}

	providerKey := normalize(adapter.ProviderKey())
	if providerKey == "" {
		return fmt.Errorf("%w: adapter provider_key required", ErrInvalidIntegrationRequest)
	}

	sdk.mu.Lock()
	defer sdk.mu.Unlock()

	if _, exists := sdk.adapters[providerKey]; exists {
		return fmt.Errorf("%w: adapter already registered for provider %s", ErrInvalidIntegrationRequest, providerKey)
	}

	sdk.adapters[providerKey] = adapter
	return nil
}

func (sdk *AdapterSDK) Execute(ctx context.Context, req OperationRequest) (OperationResult, error) {
	if err := ValidateOperationRequest(req); err != nil {
		return OperationResult{}, err
	}

	sdk.mu.RLock()
	adapter, exists := sdk.adapters[normalize(req.ProviderKey)]
	sdk.mu.RUnlock()

	if !exists {
		return OperationResult{}, fmt.Errorf("%w: adapter not registered for provider %s", ErrInvalidIntegrationRequest, req.ProviderKey)
	}

	return adapter.Execute(ctx, req)
}

func ValidateOperationRequest(req OperationRequest) error {
	if err := requireNonEmpty(req.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.ProviderKey, "provider_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.IdempotencyKey, "idempotency_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(req.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if req.Operation == "" {
		return fmt.Errorf("%w: operation required", ErrInvalidIntegrationRequest)
	}
	return nil
}
