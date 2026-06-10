package integrationruntime

import (
	"fmt"
	"sync"
	"time"
)

type ConnectorAuditEvent struct {
	TenantID      string
	ProviderKey   string
	AppKey        string
	Operation     string
	Status        string
	Decision      AuditDecision
	CorrelationID string
	ErrorCode     string
	Message       string
	CreatedAt     time.Time
}

type ConnectorMetricsSnapshot struct {
	TotalOperations  int
	FailedOperations int
	WebhookEvents    int
	DuplicateEvents  int
	ByProvider       map[string]int
}

type ConnectorObservabilityRuntime struct {
	mu           sync.RWMutex
	auditEvents  []ConnectorAuditEvent
	metrics      ConnectorMetricsSnapshot
	seenWebhooks map[string]struct{}
}

func NewConnectorObservabilityRuntime() *ConnectorObservabilityRuntime {
	return &ConnectorObservabilityRuntime{
		auditEvents:  []ConnectorAuditEvent{},
		metrics:      ConnectorMetricsSnapshot{ByProvider: map[string]int{}},
		seenWebhooks: map[string]struct{}{},
	}
}

func (runtime *ConnectorObservabilityRuntime) RecordOperation(event ConnectorAuditEvent) error {
	if err := validateConnectorAuditEvent(event); err != nil {
		return err
	}

	if event.CreatedAt.IsZero() {
		event.CreatedAt = time.Now().UTC()
	}

	runtime.mu.Lock()
	defer runtime.mu.Unlock()

	runtime.auditEvents = append(runtime.auditEvents, event)
	runtime.metrics.TotalOperations++
	runtime.metrics.ByProvider[event.ProviderKey]++

	if event.Status == "FAILED" {
		runtime.metrics.FailedOperations++
	}

	return nil
}

func (runtime *ConnectorObservabilityRuntime) RecordWebhookEvent(event ExternalEvent) (bool, error) {
	if err := requireNonEmpty(event.TenantID, "tenant_id"); err != nil {
		return false, err
	}
	if err := requireNonEmpty(event.ProviderKey, "provider_key"); err != nil {
		return false, err
	}
	if err := requireNonEmpty(event.ExternalEventID, "external_event_id"); err != nil {
		return false, err
	}

	runtime.mu.Lock()
	defer runtime.mu.Unlock()

	key := fmt.Sprintf("%s:%s:%s", event.TenantID, event.ProviderKey, event.ExternalEventID)
	_, duplicate := runtime.seenWebhooks[key]
	if duplicate {
		runtime.metrics.DuplicateEvents++
		return true, nil
	}

	runtime.seenWebhooks[key] = struct{}{}
	runtime.metrics.WebhookEvents++
	return false, nil
}

func (runtime *ConnectorObservabilityRuntime) Snapshot() ConnectorMetricsSnapshot {
	runtime.mu.RLock()
	defer runtime.mu.RUnlock()

	byProvider := map[string]int{}
	for k, v := range runtime.metrics.ByProvider {
		byProvider[k] = v
	}

	return ConnectorMetricsSnapshot{
		TotalOperations:  runtime.metrics.TotalOperations,
		FailedOperations: runtime.metrics.FailedOperations,
		WebhookEvents:    runtime.metrics.WebhookEvents,
		DuplicateEvents:  runtime.metrics.DuplicateEvents,
		ByProvider:       byProvider,
	}
}

func (runtime *ConnectorObservabilityRuntime) AuditTrailByTenant(tenantID string) []ConnectorAuditEvent {
	runtime.mu.RLock()
	defer runtime.mu.RUnlock()

	out := []ConnectorAuditEvent{}
	for _, event := range runtime.auditEvents {
		if event.TenantID == tenantID {
			out = append(out, event)
		}
	}

	return out
}

func validateConnectorAuditEvent(event ConnectorAuditEvent) error {
	if err := requireNonEmpty(event.TenantID, "tenant_id"); err != nil {
		return err
	}
	if err := requireNonEmpty(event.ProviderKey, "provider_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(event.AppKey, "app_key"); err != nil {
		return err
	}
	if err := requireNonEmpty(event.Operation, "operation"); err != nil {
		return err
	}
	if err := requireNonEmpty(event.Status, "status"); err != nil {
		return err
	}
	if err := requireNonEmpty(event.CorrelationID, "correlation_id"); err != nil {
		return err
	}
	if event.Decision == "" {
		return fmt.Errorf("%w: audit decision required", ErrInvalidIntegrationRequest)
	}
	return nil
}
