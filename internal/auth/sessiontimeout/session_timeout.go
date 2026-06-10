package sessiontimeout

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"
)

var (
	ErrSessionIDRequired    = errors.New("session id required")
	ErrAccessTokenRequired  = errors.New("access token id required")
	ErrSessionMissing       = errors.New("session missing")
	ErrSessionRevoked       = errors.New("session revoked")
	ErrAccessExpired        = errors.New("access token expired")
	ErrRefreshExpired       = errors.New("refresh token expired")
	ErrIdleTimeoutExceeded  = errors.New("idle timeout exceeded")
	ErrAbsoluteTimeoutEnded = errors.New("absolute timeout ended")
	ErrMethodNotAllowed     = errors.New("method not allowed")
)

type TimeoutPolicy struct {
	IdleTimeout     time.Duration
	AbsoluteTimeout time.Duration
}

type SessionRecord struct {
	TenantID              string
	UserID                string
	SessionID             string
	AccessTokenID         string
	RefreshTokenID        string
	IssuedAt              time.Time
	AccessTokenExpiresAt  time.Time
	RefreshTokenExpiresAt time.Time
	LastSeenAt            time.Time
	RevokedAt             *time.Time
	IPAddress             string
	UserAgent             string
}

type SessionEvent struct {
	TenantID       string
	UserID         string
	SessionID      string
	EventType      string
	ReasonCode     string
	OccurredAt     time.Time
	AccessTokenID  string
	RefreshTokenID string
	IPAddress      string
	UserAgent      string
}

type ValidationInput struct {
	SessionID     string
	AccessTokenID string
	IPAddress     string
	UserAgent     string
}

type ValidationResult struct {
	TenantID      string    `json:"tenant_id"`
	UserID        string    `json:"user_id"`
	SessionID     string    `json:"session_id"`
	AccessTokenID string    `json:"access_token_id"`
	ValidUntil    time.Time `json:"valid_until"`
	LastSeenAt    time.Time `json:"last_seen_at"`
}

type Store interface {
	GetSessionByID(ctx context.Context, sessionID string) (SessionRecord, error)
	TouchSession(ctx context.Context, sessionID string, lastSeenAt time.Time) error
	RevokeSession(ctx context.Context, sessionID string, revokedAt time.Time) error
	RecordSessionEvent(ctx context.Context, event SessionEvent) error
}

type Service struct {
	store  Store
	policy TimeoutPolicy
	now    func() time.Time
}

func NewService(store Store, policy TimeoutPolicy, now func() time.Time) *Service {
	if policy.IdleTimeout <= 0 {
		policy.IdleTimeout = 30 * time.Minute
	}
	if policy.AbsoluteTimeout <= 0 {
		policy.AbsoluteTimeout = 12 * time.Hour
	}
	if now == nil {
		now = time.Now
	}
	return &Service{store: store, policy: policy, now: now}
}

func (s *Service) ValidateSession(ctx context.Context, input ValidationInput) (ValidationResult, error) {
	input.SessionID = strings.TrimSpace(input.SessionID)
	input.AccessTokenID = strings.TrimSpace(input.AccessTokenID)

	if input.SessionID == "" {
		return ValidationResult{}, ErrSessionIDRequired
	}
	if input.AccessTokenID == "" {
		return ValidationResult{}, ErrAccessTokenRequired
	}

	session, err := s.store.GetSessionByID(ctx, input.SessionID)
	if err != nil {
		return ValidationResult{}, ErrSessionMissing
	}

	if session.AccessTokenID != input.AccessTokenID {
		s.recordEvent(ctx, session, "session_rejected", "access_token_mismatch", input)
		return ValidationResult{}, ErrAccessExpired
	}

	if err := s.checkSession(session, input); err != nil {
		s.recordEvent(ctx, session, "session_rejected", reasonCode(err), input)
		return ValidationResult{}, err
	}

	now := s.now().UTC()
	if err := s.store.TouchSession(ctx, session.SessionID, now); err != nil {
		return ValidationResult{}, err
	}

	s.recordEvent(ctx, session, "session_validated", "active", input)

	return ValidationResult{
		TenantID:      session.TenantID,
		UserID:        session.UserID,
		SessionID:     session.SessionID,
		AccessTokenID: session.AccessTokenID,
		ValidUntil:    session.AccessTokenExpiresAt,
		LastSeenAt:    now,
	}, nil
}

func (s *Service) Logout(ctx context.Context, sessionID string) error {
	sessionID = strings.TrimSpace(sessionID)
	if sessionID == "" {
		return ErrSessionIDRequired
	}

	session, err := s.store.GetSessionByID(ctx, sessionID)
	if err != nil {
		return ErrSessionMissing
	}

	now := s.now().UTC()
	if err := s.store.RevokeSession(ctx, sessionID, now); err != nil {
		return err
	}

	s.recordEvent(ctx, session, "session_revoked", "logout", ValidationInput{})
	return nil
}

func (s *Service) ValidateHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, ErrMethodNotAllowed)
		return
	}

	result, err := s.ValidateSession(r.Context(), ValidationInput{
		SessionID:     r.Header.Get("X-Session-ID"),
		AccessTokenID: r.Header.Get("X-Access-Token-ID"),
		IPAddress:     r.RemoteAddr,
		UserAgent:     r.UserAgent(),
	})
	if err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, result)
}

func (s *Service) LogoutHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, ErrMethodNotAllowed)
		return
	}

	sessionID := r.Header.Get("X-Session-ID")
	if sessionID == "" {
		var body struct {
			SessionID string `json:"session_id"`
		}
		_ = json.NewDecoder(r.Body).Decode(&body)
		sessionID = body.SessionID
	}

	if err := s.Logout(r.Context(), sessionID); err != nil {
		writeServiceError(w, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]string{"status": "revoked"})
}

func (s *Service) checkSession(session SessionRecord, input ValidationInput) error {
	now := s.now().UTC()

	if session.RevokedAt != nil {
		return ErrSessionRevoked
	}
	if !session.AccessTokenExpiresAt.After(now) {
		return ErrAccessExpired
	}
	if !session.RefreshTokenExpiresAt.After(now) {
		return ErrRefreshExpired
	}

	lastSeen := session.LastSeenAt
	if lastSeen.IsZero() {
		lastSeen = session.IssuedAt
	}

	if now.Sub(lastSeen) > s.policy.IdleTimeout {
		return ErrIdleTimeoutExceeded
	}
	if now.Sub(session.IssuedAt) > s.policy.AbsoluteTimeout {
		return ErrAbsoluteTimeoutEnded
	}

	return nil
}

func (s *Service) recordEvent(ctx context.Context, session SessionRecord, eventType string, code string, input ValidationInput) {
	_ = s.store.RecordSessionEvent(ctx, SessionEvent{
		TenantID:       session.TenantID,
		UserID:         session.UserID,
		SessionID:      session.SessionID,
		EventType:      eventType,
		ReasonCode:     code,
		OccurredAt:     s.now().UTC(),
		AccessTokenID:  session.AccessTokenID,
		RefreshTokenID: session.RefreshTokenID,
		IPAddress:      input.IPAddress,
		UserAgent:      input.UserAgent,
	})
}

func reasonCode(err error) string {
	switch {
	case errors.Is(err, ErrSessionRevoked):
		return "revoked"
	case errors.Is(err, ErrAccessExpired):
		return "access_expired"
	case errors.Is(err, ErrRefreshExpired):
		return "refresh_expired"
	case errors.Is(err, ErrIdleTimeoutExceeded):
		return "idle_timeout"
	case errors.Is(err, ErrAbsoluteTimeoutEnded):
		return "absolute_timeout"
	default:
		return "unknown"
	}
}

func writeServiceError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrSessionIDRequired), errors.Is(err, ErrAccessTokenRequired):
		writeError(w, http.StatusBadRequest, err)
	case errors.Is(err, ErrSessionMissing):
		writeError(w, http.StatusUnauthorized, err)
	case errors.Is(err, ErrSessionRevoked), errors.Is(err, ErrAccessExpired), errors.Is(err, ErrRefreshExpired), errors.Is(err, ErrIdleTimeoutExceeded), errors.Is(err, ErrAbsoluteTimeoutEnded):
		writeError(w, http.StatusUnauthorized, err)
	default:
		writeError(w, http.StatusInternalServerError, err)
	}
}

func writeError(w http.ResponseWriter, status int, err error) {
	writeJSON(w, status, map[string]string{"error": err.Error()})
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}
