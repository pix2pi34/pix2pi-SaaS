package passwordflow

import (
	"context"
	"errors"
	"sync"
	"time"
)

var ErrNotFound = errors.New("not found")

type MemoryRepo struct {
	mu          sync.RWMutex
	credentials map[string]Credential
	resets      map[string]ResetToken
	sessions    map[string]Session
	audits      []AuditEvent
}

func NewMemoryRepo() *MemoryRepo {
	return &MemoryRepo{
		credentials: map[string]Credential{},
		resets:      map[string]ResetToken{},
		sessions:    map[string]Session{},
		audits:      []AuditEvent{},
	}
}

func key(userID, tenantID string) string {
	return tenantID + ":" + userID
}

func (r *MemoryRepo) SaveCredential(ctx context.Context, credential Credential) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.credentials[key(credential.UserID, credential.TenantID)] = credential
	return nil
}

func (r *MemoryRepo) GetCredential(ctx context.Context, userID, tenantID string) (Credential, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	v, ok := r.credentials[key(userID, tenantID)]
	if !ok {
		return Credential{}, ErrNotFound
	}
	return v, nil
}

func (r *MemoryRepo) SaveResetToken(ctx context.Context, token ResetToken) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.resets[token.TokenHash] = token
	return nil
}

func (r *MemoryRepo) GetResetTokenByHash(ctx context.Context, tokenHash string) (ResetToken, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	v, ok := r.resets[tokenHash]
	if !ok {
		return ResetToken{}, ErrNotFound
	}
	return v, nil
}

func (r *MemoryRepo) ConsumeResetToken(ctx context.Context, tokenHash string, consumedAt time.Time) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	v, ok := r.resets[tokenHash]
	if !ok {
		return ErrNotFound
	}
	v.ConsumedAt = &consumedAt
	r.resets[tokenHash] = v
	return nil
}

func (r *MemoryRepo) SaveSession(ctx context.Context, session Session) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.sessions[session.SessionID] = session
	return nil
}

func (r *MemoryRepo) GetSession(ctx context.Context, sessionID string) (Session, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	v, ok := r.sessions[sessionID]
	if !ok {
		return Session{}, ErrNotFound
	}
	return v, nil
}

func (r *MemoryRepo) TouchSession(ctx context.Context, sessionID string, at time.Time) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	v, ok := r.sessions[sessionID]
	if !ok {
		return ErrNotFound
	}
	v.LastSeenAt = at
	r.sessions[sessionID] = v
	return nil
}

func (r *MemoryRepo) RevokeSession(ctx context.Context, sessionID string, at time.Time) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	v, ok := r.sessions[sessionID]
	if !ok {
		return ErrNotFound
	}
	v.RevokedAt = &at
	r.sessions[sessionID] = v
	return nil
}

func (r *MemoryRepo) RecordAudit(ctx context.Context, event AuditEvent) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.audits = append(r.audits, event)
	return nil
}

func (r *MemoryRepo) AuditEvents() []AuditEvent {
	r.mu.RLock()
	defer r.mu.RUnlock()
	out := make([]AuditEvent, len(r.audits))
	copy(out, r.audits)
	return out
}

type StaticMembership struct {
	Allowed map[string]bool
}

func (s StaticMembership) CanAccessTenant(ctx context.Context, userID, tenantID string) bool {
	return s.Allowed[key(userID, tenantID)]
}
