package service

import (
	"errors"
	"strings"
	"time"
)

var (
	ErrWebhookReplayStoreRequired   = errors.New("security: webhook replay store required")
	ErrWebhookReplaySourceRequired  = errors.New("security: webhook replay source required")
	ErrWebhookReplayEventIDRequired = errors.New("security: webhook replay event id required")
	ErrWebhookReplayTTLInvalid      = errors.New("security: webhook replay ttl invalid")
	ErrWebhookReplayDetected        = errors.New("security: webhook replay detected")
)

type WebhookReplayPolicy struct {
	TTL time.Duration
}

func DefaultWebhookReplayPolicy() WebhookReplayPolicy {
	return WebhookReplayPolicy{
		TTL: 15 * time.Minute,
	}
}

func (p WebhookReplayPolicy) Validate() error {
	if p.TTL <= 0 {
		return ErrWebhookReplayTTLInvalid
	}
	return nil
}

type WebhookReplayInput struct {
	Source  string
	EventID string
}

func (i WebhookReplayInput) Validate() error {
	if strings.TrimSpace(i.Source) == "" {
		return ErrWebhookReplaySourceRequired
	}
	if strings.TrimSpace(i.EventID) == "" {
		return ErrWebhookReplayEventIDRequired
	}
	return nil
}

type WebhookReplayStore interface {
	Exists(key string, now time.Time) bool
	Save(key string, expiresAt time.Time) error
}

type InMemoryWebhookReplayStore struct {
	items map[string]time.Time
}

func NewInMemoryWebhookReplayStore() *InMemoryWebhookReplayStore {
	return &InMemoryWebhookReplayStore{
		items: make(map[string]time.Time),
	}
}

func (s *InMemoryWebhookReplayStore) Exists(key string, now time.Time) bool {
	if s == nil || s.items == nil {
		return false
	}

	expiresAt, ok := s.items[key]
	if !ok {
		return false
	}

	if now.After(expiresAt) {
		delete(s.items, key)
		return false
	}

	return true
}

func (s *InMemoryWebhookReplayStore) Save(key string, expiresAt time.Time) error {
	if s == nil {
		return ErrWebhookReplayStoreRequired
	}
	if s.items == nil {
		s.items = make(map[string]time.Time)
	}

	s.items[key] = expiresAt
	return nil
}

func BuildWebhookReplayKey(input WebhookReplayInput) (string, error) {
	if err := input.Validate(); err != nil {
		return "", err
	}

	return strings.TrimSpace(input.Source) + ":" + strings.TrimSpace(input.EventID), nil
}

func CheckAndStoreWebhookReplay(
	store WebhookReplayStore,
	input WebhookReplayInput,
	policy WebhookReplayPolicy,
	now time.Time,
) error {
	if store == nil {
		return ErrWebhookReplayStoreRequired
	}
	if err := policy.Validate(); err != nil {
		return err
	}
	if err := input.Validate(); err != nil {
		return err
	}

	key, err := BuildWebhookReplayKey(input)
	if err != nil {
		return err
	}

	if store.Exists(key, now) {
		return ErrWebhookReplayDetected
	}

	return store.Save(key, now.Add(policy.TTL))
}
