package readmodel

import (
	"context"
	"errors"
	"fmt"
	"regexp"
	"sort"
	"strings"
	"time"
)

var validPartRegex = regexp.MustCompile(`^[a-zA-Z0-9:_\-\.]+$`)

var (
	ErrEmptyEventID            = errors.New("readmodel: empty event id")
	ErrEmptyEventType          = errors.New("readmodel: empty event type")
	ErrEmptyTenantID           = errors.New("readmodel: empty tenant id")
	ErrInvalidKeyPart          = errors.New("readmodel: invalid key part")
	ErrEmptyProjectionName     = errors.New("readmodel: empty projection name")
	ErrNegativeRecordsAffected = errors.New("readmodel: negative records affected")
	ErrDuplicateHandler        = errors.New("readmodel: duplicate handler")
	ErrUnknownHandler          = errors.New("readmodel: unknown handler")
	ErrNilHandlerRegistry      = errors.New("readmodel: nil handler registry")
	ErrNilProcessedStore       = errors.New("readmodel: nil processed store")
	ErrNilProjectionHandler    = errors.New("readmodel: nil projection handler")
	ErrNilSubscriberPipeline   = errors.New("readmodel: nil subscriber pipeline")
)

type ReadModelEvent struct {
	EventID       string
	EventType     string
	TenantID      string
	AggregateID   string
	CorrelationID string
	OccurredAt    time.Time
	Payload       []byte
}

func (e ReadModelEvent) Validate() error {
	if strings.TrimSpace(e.EventID) == "" {
		return ErrEmptyEventID
	}
	if strings.TrimSpace(e.EventType) == "" {
		return ErrEmptyEventType
	}
	if strings.TrimSpace(e.TenantID) == "" {
		return ErrEmptyTenantID
	}

	if err := validateKeyPart(e.EventID); err != nil {
		return fmt.Errorf("event id: %w", err)
	}
	if err := validateKeyPart(e.EventType); err != nil {
		return fmt.Errorf("event type: %w", err)
	}
	if err := validateKeyPart(e.TenantID); err != nil {
		return fmt.Errorf("tenant id: %w", err)
	}
	if e.AggregateID != "" {
		if err := validateKeyPart(e.AggregateID); err != nil {
			return fmt.Errorf("aggregate id: %w", err)
		}
	}
	if e.CorrelationID != "" {
		if err := validateKeyPart(e.CorrelationID); err != nil {
			return fmt.Errorf("correlation id: %w", err)
		}
	}

	return nil
}

type ProjectionWrite struct {
	Projection      string
	RecordsAffected int
}

func (w ProjectionWrite) Validate() error {
	if strings.TrimSpace(w.Projection) == "" {
		return ErrEmptyProjectionName
	}
	if err := validateKeyPart(w.Projection); err != nil {
		return fmt.Errorf("projection: %w", err)
	}
	if w.RecordsAffected < 0 {
		return ErrNegativeRecordsAffected
	}
	return nil
}

type ProjectionResult struct {
	Writes []ProjectionWrite
}

func (r ProjectionResult) Validate() error {
	for _, write := range r.Writes {
		if err := write.Validate(); err != nil {
			return err
		}
	}
	return nil
}

type ProjectionHandler func(context.Context, ReadModelEvent) (ProjectionResult, error)

type HandlerRegistry struct {
	items map[string]ProjectionHandler
}

func NewHandlerRegistry() *HandlerRegistry {
	return &HandlerRegistry{
		items: make(map[string]ProjectionHandler),
	}
}

func (r *HandlerRegistry) Register(eventType string, handler ProjectionHandler) error {
	if r == nil {
		return ErrNilHandlerRegistry
	}
	if strings.TrimSpace(eventType) == "" {
		return ErrEmptyEventType
	}
	if handler == nil {
		return ErrNilProjectionHandler
	}
	if err := validateKeyPart(eventType); err != nil {
		return fmt.Errorf("event type: %w", err)
	}
	if _, exists := r.items[eventType]; exists {
		return ErrDuplicateHandler
	}

	r.items[eventType] = handler
	return nil
}

func (r *HandlerRegistry) MustRegister(eventType string, handler ProjectionHandler) {
	if err := r.Register(eventType, handler); err != nil {
		panic(err)
	}
}

func (r *HandlerRegistry) Get(eventType string) (ProjectionHandler, bool) {
	if r == nil {
		return nil, false
	}
	handler, ok := r.items[eventType]
	return handler, ok
}

func (r *HandlerRegistry) ListEventTypes() []string {
	if r == nil {
		return nil
	}

	result := make([]string, 0, len(r.items))
	for eventType := range r.items {
		result = append(result, eventType)
	}

	sort.Strings(result)
	return result
}

type ProcessedEventStore interface {
	Exists(ctx context.Context, eventID string) (bool, error)
	Mark(ctx context.Context, eventID string) error
}

type retryableError struct {
	err error
}

func (e retryableError) Error() string {
	return e.err.Error()
}

func (e retryableError) Unwrap() error {
	return e.err
}

func (e retryableError) Retryable() bool {
	return true
}

func NewRetryableError(err error) error {
	if err == nil {
		return nil
	}
	return retryableError{err: err}
}

func IsRetryable(err error) bool {
	type retryable interface {
		Retryable() bool
	}

	var r retryable
	if errors.As(err, &r) {
		return r.Retryable()
	}
	return false
}

type SubscriberHandleResult struct {
	EventID           string
	EventType         string
	TenantID          string
	AlreadyProcessed  bool
	Retryable         bool
	ProjectionWrites  []ProjectionWrite
}

type SubscriberPipeline struct {
	registry *HandlerRegistry
	tracker  ProcessedEventStore
}

func NewSubscriberPipeline(registry *HandlerRegistry, tracker ProcessedEventStore) (*SubscriberPipeline, error) {
	if registry == nil {
		return nil, ErrNilHandlerRegistry
	}
	if tracker == nil {
		return nil, ErrNilProcessedStore
	}

	return &SubscriberPipeline{
		registry: registry,
		tracker:  tracker,
	}, nil
}

func (p *SubscriberPipeline) Handle(ctx context.Context, event ReadModelEvent) (SubscriberHandleResult, error) {
	var zero SubscriberHandleResult

	if p == nil {
		return zero, ErrNilSubscriberPipeline
	}
	if err := event.Validate(); err != nil {
		return zero, err
	}

	result := SubscriberHandleResult{
		EventID:   event.EventID,
		EventType: event.EventType,
		TenantID:  event.TenantID,
	}

	processed, err := p.tracker.Exists(ctx, event.EventID)
	if err != nil {
		return zero, err
	}
	if processed {
		result.AlreadyProcessed = true
		return result, nil
	}

	handler, ok := p.registry.Get(event.EventType)
	if !ok {
		return zero, fmt.Errorf("%w: %s", ErrUnknownHandler, event.EventType)
	}

	projectionResult, err := handler(ctx, event)
	if err != nil {
		result.Retryable = IsRetryable(err)
		return result, err
	}

	if err := projectionResult.Validate(); err != nil {
		return zero, err
	}

	if err := p.tracker.Mark(ctx, event.EventID); err != nil {
		return zero, err
	}

	result.ProjectionWrites = append(result.ProjectionWrites, projectionResult.Writes...)
	return result, nil
}

func validateKeyPart(value string) error {
	if !validPartRegex.MatchString(value) {
		return ErrInvalidKeyPart
	}
	return nil
}
