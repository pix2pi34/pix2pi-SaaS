package passwordflow

import (
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"
	"unicode"
)

var (
	ErrInviteTokenRequired = errors.New("invite token required")
	ErrInviteTokenInvalid  = errors.New("invite token invalid")
	ErrUserIDRequired      = errors.New("user id required")
	ErrEmailRequired       = errors.New("email required")
	ErrPasswordRequired    = errors.New("password required")
	ErrPasswordWeak        = errors.New("password policy failed")
	ErrPasswordMismatch    = errors.New("password confirmation mismatch")
	ErrResetTokenRequired  = errors.New("reset token required")
	ErrResetTokenInvalid   = errors.New("reset token invalid")
	ErrResetTokenExpired   = errors.New("reset token expired")
	ErrInvalidCredentials  = errors.New("invalid credentials")
	ErrAccountInactive     = errors.New("account inactive")
	ErrTenantRequired      = errors.New("tenant required")
	ErrTenantAccessDenied  = errors.New("tenant access denied")
	ErrSessionIDRequired   = errors.New("session id required")
	ErrAccessTokenRequired = errors.New("access token id required")
	ErrSessionInvalid      = errors.New("session invalid")
	ErrMethodNotAllowed    = errors.New("method not allowed")
)

type PasswordPolicy struct {
	MinLength    int
	RequireUpper bool
	RequireLower bool
	RequireDigit bool
}

type Credential struct {
	UserID            string
	Email             string
	PasswordHash      string
	Status            string
	PasswordSetAt     time.Time
	PasswordChangedAt time.Time
}

type Invite struct {
	Token     string
	UserID    string
	Email     string
	Status    string
	ExpiresAt time.Time
}

type ResetToken struct {
	TokenHash  string
	UserID     string
	Email      string
	IssuedAt   time.Time
	ExpiresAt  time.Time
	ConsumedAt *time.Time
}

type Session struct {
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

type Event struct {
	UserID        string
	TenantID      string
	Email         string
	EventType     string
	Result        string
	ReasonCode    string
	CorrelationID string
	IPAddress     string
	UserAgent     string
	OccurredAt    time.Time
}

type InitialPasswordInput struct {
	InviteToken   string `json:"invite_token"`
	Password      string `json:"password"`
	Confirm       string `json:"confirm"`
	CorrelationID string `json:"correlation_id"`
	IPAddress     string `json:"ip_address"`
	UserAgent     string `json:"user_agent"`
}

type PasswordResetRequestInput struct {
	Email         string `json:"email"`
	CorrelationID string `json:"correlation_id"`
	IPAddress     string `json:"ip_address"`
	UserAgent     string `json:"user_agent"`
}

type PasswordResetCompleteInput struct {
	ResetToken    string `json:"reset_token"`
	Password      string `json:"password"`
	Confirm       string `json:"confirm"`
	CorrelationID string `json:"correlation_id"`
	IPAddress     string `json:"ip_address"`
	UserAgent     string `json:"user_agent"`
}

type LoginInput struct {
	Email         string `json:"email"`
	Password      string `json:"password"`
	TenantID      string `json:"tenant_id"`
	CorrelationID string `json:"correlation_id"`
	IPAddress     string `json:"ip_address"`
	UserAgent     string `json:"user_agent"`
}

type SessionValidationInput struct {
	SessionID     string
	AccessTokenID string
	CorrelationID string
	IPAddress     string
	UserAgent     string
}

type PasswordSetupResult struct {
	UserID        string    `json:"user_id"`
	Email         string    `json:"email"`
	PasswordSetAt time.Time `json:"password_set_at"`
}

type ResetTokenResult struct {
	UserID    string    `json:"user_id"`
	Email     string    `json:"email"`
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expires_at"`
}

type LoginResult struct {
	UserID                string    `json:"user_id"`
	TenantID              string    `json:"tenant_id"`
	SessionID             string    `json:"session_id"`
	AccessTokenID         string    `json:"access_token_id"`
	RefreshTokenID        string    `json:"refresh_token_id"`
	IssuedAt              time.Time `json:"issued_at"`
	AccessTokenExpiresAt  time.Time `json:"access_expires_at"`
	RefreshTokenExpiresAt time.Time `json:"refresh_expires_at"`
	NextPath              string    `json:"next_path"`
}

type Store interface {
	GetInviteByToken(ctx context.Context, token string) (Invite, error)
	MarkInviteAccepted(ctx context.Context, token string, acceptedAt time.Time) error
	SaveCredential(ctx context.Context, credential Credential) error
	GetCredentialByEmail(ctx context.Context, email string) (Credential, error)
	UserHasTenant(ctx context.Context, userID string, tenantID string) (bool, error)
	SaveResetToken(ctx context.Context, token ResetToken) error
	GetResetToken(ctx context.Context, tokenHash string) (ResetToken, error)
	ConsumeResetToken(ctx context.Context, tokenHash string, consumedAt time.Time) error
	SaveLoginSession(ctx context.Context, session Session) error
	GetLoginSession(ctx context.Context, sessionID string) (Session, error)
	TouchLoginSession(ctx context.Context, sessionID string, lastSeenAt time.Time) error
	RecordEvent(ctx context.Context, event Event) error
}

type Service struct {
	store           Store
	hasher          PasswordHasher
	policy          PasswordPolicy
	accessTokenTTL  time.Duration
	refreshTokenTTL time.Duration
	now             func() time.Time
}

type PasswordHasher interface {
	Hash(value string) string
	Verify(value string, hash string) bool
}

type HMACPasswordHasher struct {
	Secret []byte
}

func (h HMACPasswordHasher) Hash(value string) string {
	mac := hmac.New(sha256.New, h.Secret)
	mac.Write([]byte(value))
	return base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
}

func (h HMACPasswordHasher) Verify(value string, hash string) bool {
	expected := h.Hash(value)
	return hmac.Equal([]byte(expected), []byte(hash))
}

func NewService(store Store, hasher PasswordHasher, policy PasswordPolicy, now func() time.Time) *Service {
	if policy.MinLength <= 0 {
		policy.MinLength = 12
	}
	if now == nil {
		now = time.Now
	}

	return &Service{
		store:           store,
		hasher:          hasher,
		policy:          policy,
		accessTokenTTL:  time.Hour,
		refreshTokenTTL: 30 * 24 * time.Hour,
		now:             now,
	}
}

func (s *Service) SetInitialPassword(ctx context.Context, input InitialPasswordInput) (PasswordSetupResult, error) {
	token := strings.TrimSpace(input.InviteToken)
	if token == "" {
		return PasswordSetupResult{}, ErrInviteTokenRequired
	}

	if err := s.validatePassword(input.Password, input.Confirm); err != nil {
		s.record(ctx, "", "", "initial_password", "rejected", err.Error(), input.CorrelationID, input.IPAddress, input.UserAgent)
		return PasswordSetupResult{}, err
	}

	invite, err := s.store.GetInviteByToken(ctx, token)
	if err != nil || invite.Status != "pending" || !invite.ExpiresAt.After(s.now().UTC()) {
		s.record(ctx, "", "", "initial_password", "rejected", ErrInviteTokenInvalid.Error(), input.CorrelationID, input.IPAddress, input.UserAgent)
		return PasswordSetupResult{}, ErrInviteTokenInvalid
	}

	now := s.now().UTC()
	credential := Credential{
		UserID:            invite.UserID,
		Email:             normalizeEmail(invite.Email),
		PasswordHash:      s.hasher.Hash(input.Password),
		Status:            "active",
		PasswordSetAt:     now,
		PasswordChangedAt: now,
	}

	if err := s.store.SaveCredential(ctx, credential); err != nil {
		return PasswordSetupResult{}, err
	}
	if err := s.store.MarkInviteAccepted(ctx, token, now); err != nil {
		return PasswordSetupResult{}, err
	}

	s.record(ctx, invite.UserID, "", "initial_password", "accepted", "password_set", input.CorrelationID, input.IPAddress, input.UserAgent)

	return PasswordSetupResult{
		UserID:        invite.UserID,
		Email:         normalizeEmail(invite.Email),
		PasswordSetAt: now,
	}, nil
}

func (s *Service) RequestPasswordReset(ctx context.Context, input PasswordResetRequestInput) (ResetTokenResult, error) {
	email := normalizeEmail(input.Email)
	if email == "" {
		return ResetTokenResult{}, ErrEmailRequired
	}

	credential, err := s.store.GetCredentialByEmail(ctx, email)
	if err != nil || credential.Status != "active" {
		s.record(ctx, "", "", "password_reset_request", "rejected", ErrInvalidCredentials.Error(), input.CorrelationID, input.IPAddress, input.UserAgent)
		return ResetTokenResult{}, ErrInvalidCredentials
	}

	rawToken := secureID("rst")
	now := s.now().UTC()
	reset := ResetToken{
		TokenHash: s.hasher.Hash(rawToken),
		UserID:    credential.UserID,
		Email:     credential.Email,
		IssuedAt:  now,
		ExpiresAt: now.Add(time.Hour),
	}

	if err := s.store.SaveResetToken(ctx, reset); err != nil {
		return ResetTokenResult{}, err
	}

	s.record(ctx, credential.UserID, "", "password_reset_request", "accepted", "reset_token_issued", input.CorrelationID, input.IPAddress, input.UserAgent)

	return ResetTokenResult{
		UserID:    credential.UserID,
		Email:     credential.Email,
		Token:     rawToken,
		ExpiresAt: reset.ExpiresAt,
	}, nil
}

func (s *Service) CompletePasswordReset(ctx context.Context, input PasswordResetCompleteInput) (PasswordSetupResult, error) {
	rawToken := strings.TrimSpace(input.ResetToken)
	if rawToken == "" {
		return PasswordSetupResult{}, ErrResetTokenRequired
	}
	if err := s.validatePassword(input.Password, input.Confirm); err != nil {
		return PasswordSetupResult{}, err
	}

	tokenHash := s.hasher.Hash(rawToken)
	reset, err := s.store.GetResetToken(ctx, tokenHash)
	if err != nil {
		return PasswordSetupResult{}, ErrResetTokenInvalid
	}
	if reset.ConsumedAt != nil {
		return PasswordSetupResult{}, ErrResetTokenInvalid
	}
	if !reset.ExpiresAt.After(s.now().UTC()) {
		return PasswordSetupResult{}, ErrResetTokenExpired
	}

	now := s.now().UTC()
	credential := Credential{
		UserID:            reset.UserID,
		Email:             normalizeEmail(reset.Email),
		PasswordHash:      s.hasher.Hash(input.Password),
		Status:            "active",
		PasswordSetAt:     now,
		PasswordChangedAt: now,
	}

	if err := s.store.SaveCredential(ctx, credential); err != nil {
		return PasswordSetupResult{}, err
	}
	if err := s.store.ConsumeResetToken(ctx, tokenHash, now); err != nil {
		return PasswordSetupResult{}, err
	}

	s.record(ctx, reset.UserID, "", "password_reset_complete", "accepted", "password_changed", input.CorrelationID, input.IPAddress, input.UserAgent)

	return PasswordSetupResult{
		UserID:        reset.UserID,
		Email:         reset.Email,
		PasswordSetAt: now,
	}, nil
}

func (s *Service) Login(ctx context.Context, input LoginInput) (LoginResult, error) {
	email := normalizeEmail(input.Email)
	tenantID := strings.TrimSpace(input.TenantID)

	if email == "" || input.Password == "" {
		return LoginResult{}, ErrInvalidCredentials
	}
	if tenantID == "" {
		return LoginResult{}, ErrTenantRequired
	}

	credential, err := s.store.GetCredentialByEmail(ctx, email)
	if err != nil {
		s.record(ctx, "", tenantID, "login", "rejected", ErrInvalidCredentials.Error(), input.CorrelationID, input.IPAddress, input.UserAgent)
		return LoginResult{}, ErrInvalidCredentials
	}
	if credential.Status != "active" {
		return LoginResult{}, ErrAccountInactive
	}
	if !s.hasher.Verify(input.Password, credential.PasswordHash) {
		s.record(ctx, credential.UserID, tenantID, "login", "rejected", ErrInvalidCredentials.Error(), input.CorrelationID, input.IPAddress, input.UserAgent)
		return LoginResult{}, ErrInvalidCredentials
	}

	hasTenant, err := s.store.UserHasTenant(ctx, credential.UserID, tenantID)
	if err != nil || !hasTenant {
		s.record(ctx, credential.UserID, tenantID, "login", "rejected", ErrTenantAccessDenied.Error(), input.CorrelationID, input.IPAddress, input.UserAgent)
		return LoginResult{}, ErrTenantAccessDenied
	}

	now := s.now().UTC()
	session := Session{
		TenantID:              tenantID,
		UserID:                credential.UserID,
		SessionID:             secureID("sess"),
		AccessTokenID:         secureID("atk"),
		RefreshTokenID:        secureID("rtk"),
		IssuedAt:              now,
		AccessTokenExpiresAt:  now.Add(s.accessTokenTTL),
		RefreshTokenExpiresAt: now.Add(s.refreshTokenTTL),
		LastSeenAt:            now,
		IPAddress:             input.IPAddress,
		UserAgent:             input.UserAgent,
	}

	if err := s.store.SaveLoginSession(ctx, session); err != nil {
		return LoginResult{}, err
	}

	s.record(ctx, credential.UserID, tenantID, "login", "accepted", "session_created", input.CorrelationID, input.IPAddress, input.UserAgent)

	return LoginResult{
		UserID:                credential.UserID,
		TenantID:              tenantID,
		SessionID:             session.SessionID,
		AccessTokenID:         session.AccessTokenID,
		RefreshTokenID:        session.RefreshTokenID,
		IssuedAt:              session.IssuedAt,
		AccessTokenExpiresAt:  session.AccessTokenExpiresAt,
		RefreshTokenExpiresAt: session.RefreshTokenExpiresAt,
		NextPath:              "/tenant-select/",
	}, nil
}

func (s *Service) ValidateSession(ctx context.Context, input SessionValidationInput) (LoginResult, error) {
	sessionID := strings.TrimSpace(input.SessionID)
	accessTokenID := strings.TrimSpace(input.AccessTokenID)

	if sessionID == "" {
		return LoginResult{}, ErrSessionIDRequired
	}
	if accessTokenID == "" {
		return LoginResult{}, ErrAccessTokenRequired
	}

	session, err := s.store.GetLoginSession(ctx, sessionID)
	if err != nil {
		return LoginResult{}, ErrSessionInvalid
	}
	if session.RevokedAt != nil {
		return LoginResult{}, ErrSessionInvalid
	}
	if session.AccessTokenID != accessTokenID {
		return LoginResult{}, ErrSessionInvalid
	}
	if !session.AccessTokenExpiresAt.After(s.now().UTC()) {
		return LoginResult{}, ErrSessionInvalid
	}

	now := s.now().UTC()
	if err := s.store.TouchLoginSession(ctx, sessionID, now); err != nil {
		return LoginResult{}, err
	}

	return LoginResult{
		UserID:                session.UserID,
		TenantID:              session.TenantID,
		SessionID:             session.SessionID,
		AccessTokenID:         session.AccessTokenID,
		RefreshTokenID:        session.RefreshTokenID,
		IssuedAt:              session.IssuedAt,
		AccessTokenExpiresAt:  session.AccessTokenExpiresAt,
		RefreshTokenExpiresAt: session.RefreshTokenExpiresAt,
		NextPath:              "/tenant-select/",
	}, nil
}

func (s *Service) InitialPasswordHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, ErrMethodNotAllowed)
		return
	}
	var input InitialPasswordInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		writeError(w, http.StatusBadRequest, ErrPasswordRequired)
		return
	}
	result, err := s.SetInitialPassword(r.Context(), input)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (s *Service) LoginHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, ErrMethodNotAllowed)
		return
	}
	var input LoginInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		writeError(w, http.StatusBadRequest, ErrInvalidCredentials)
		return
	}
	result, err := s.Login(r.Context(), input)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (s *Service) RequestResetHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, ErrMethodNotAllowed)
		return
	}
	var input PasswordResetRequestInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		writeError(w, http.StatusBadRequest, ErrEmailRequired)
		return
	}
	result, err := s.RequestPasswordReset(r.Context(), input)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (s *Service) CompleteResetHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, ErrMethodNotAllowed)
		return
	}
	var input PasswordResetCompleteInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		writeError(w, http.StatusBadRequest, ErrResetTokenRequired)
		return
	}
	result, err := s.CompletePasswordReset(r.Context(), input)
	if err != nil {
		writeServiceError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (s *Service) ValidateSessionHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, ErrMethodNotAllowed)
		return
	}
	result, err := s.ValidateSession(r.Context(), SessionValidationInput{
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

func (s *Service) validatePassword(password string, confirm string) error {
	if password == "" {
		return ErrPasswordRequired
	}
	if password != confirm {
		return ErrPasswordMismatch
	}
	if len([]rune(password)) < s.policy.MinLength {
		return ErrPasswordWeak
	}

	hasUpper := false
	hasLower := false
	hasDigit := false

	for _, r := range password {
		if unicode.IsUpper(r) {
			hasUpper = true
		}
		if unicode.IsLower(r) {
			hasLower = true
		}
		if unicode.IsDigit(r) {
			hasDigit = true
		}
	}

	if s.policy.RequireUpper && !hasUpper {
		return ErrPasswordWeak
	}
	if s.policy.RequireLower && !hasLower {
		return ErrPasswordWeak
	}
	if s.policy.RequireDigit && !hasDigit {
		return ErrPasswordWeak
	}

	return nil
}

func (s *Service) record(ctx context.Context, userID string, tenantID string, eventType string, result string, reasonCode string, correlationID string, ipAddress string, userAgent string) {
	if strings.TrimSpace(correlationID) == "" {
		correlationID = "password-flow-correlation-missing"
	}
	_ = s.store.RecordEvent(ctx, Event{
		UserID:        userID,
		TenantID:      tenantID,
		EventType:     eventType,
		Result:        result,
		ReasonCode:    reasonCode,
		CorrelationID: correlationID,
		IPAddress:     ipAddress,
		UserAgent:     userAgent,
		OccurredAt:    s.now().UTC(),
	})
}

func writeServiceError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrInviteTokenRequired), errors.Is(err, ErrPasswordRequired), errors.Is(err, ErrPasswordWeak), errors.Is(err, ErrPasswordMismatch), errors.Is(err, ErrResetTokenRequired), errors.Is(err, ErrTenantRequired), errors.Is(err, ErrSessionIDRequired), errors.Is(err, ErrAccessTokenRequired):
		writeError(w, http.StatusBadRequest, err)
	case errors.Is(err, ErrInvalidCredentials), errors.Is(err, ErrSessionInvalid), errors.Is(err, ErrInviteTokenInvalid), errors.Is(err, ErrResetTokenInvalid), errors.Is(err, ErrResetTokenExpired):
		writeError(w, http.StatusUnauthorized, err)
	case errors.Is(err, ErrAccountInactive), errors.Is(err, ErrTenantAccessDenied):
		writeError(w, http.StatusForbidden, err)
	default:
		writeError(w, http.StatusInternalServerError, err)
	}
}

func writeError(w http.ResponseWriter, status int, err error) {
	writeJSON(w, status, map[string]string{"error": err.Error()})
}

func writeJSON(w http.ResponseWriter, status int, value interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}

func normalizeEmail(email string) string {
	return strings.TrimSpace(strings.ToLower(email))
}

func secureID(prefix string) string {
	buf := make([]byte, 18)
	if _, err := rand.Read(buf); err != nil {
		panic(err)
	}
	return prefix + "_" + base64.RawURLEncoding.EncodeToString(buf)
}
