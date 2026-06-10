package passwordflow

import (
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"
)

var (
	ErrWeakPassword       = errors.New("weak password")
	ErrPasswordMismatch   = errors.New("password confirmation mismatch")
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrResetTokenExpired  = errors.New("password reset token expired")
	ErrResetTokenConsumed = errors.New("password reset token consumed")
	ErrSessionExpired     = errors.New("session expired")
	ErrSessionRevoked     = errors.New("session revoked")
	ErrTenantForbidden    = errors.New("tenant forbidden")
)

type PasswordPolicy struct {
	MinLength     int
	RequireUpper  bool
	RequireLower  bool
	RequireDigit  bool
	RequireSymbol bool
}

func DefaultPasswordPolicy() PasswordPolicy {
	return PasswordPolicy{
		MinLength:     10,
		RequireUpper:  true,
		RequireLower:  true,
		RequireDigit:  true,
		RequireSymbol: true,
	}
}

type Credential struct {
	UserID             string
	TenantID           string
	PasswordHash       string
	PasswordSalt       string
	PasswordVersion    int
	PasswordChangedAt  time.Time
	MustChangePassword bool
}

type ResetToken struct {
	TokenID     string
	UserID      string
	TenantID    string
	TokenHash   string
	ExpiresAt   time.Time
	ConsumedAt  *time.Time
	RequestedIP string
	CreatedAt   time.Time
}

type Session struct {
	SessionID        string
	UserID           string
	TenantID         string
	AccessTokenHash  string
	RefreshTokenHash string
	IssuedAt         time.Time
	LastSeenAt       time.Time
	ExpiresAt        time.Time
	RevokedAt        *time.Time
}

type AuditEvent struct {
	EventID       string
	TenantID      string
	UserID        string
	EventType     string
	CorrelationID string
	Metadata      map[string]string
	CreatedAt     time.Time
}

type Repository interface {
	SaveCredential(ctx context.Context, credential Credential) error
	GetCredential(ctx context.Context, userID, tenantID string) (Credential, error)
	SaveResetToken(ctx context.Context, token ResetToken) error
	GetResetTokenByHash(ctx context.Context, tokenHash string) (ResetToken, error)
	ConsumeResetToken(ctx context.Context, tokenHash string, consumedAt time.Time) error
	SaveSession(ctx context.Context, session Session) error
	GetSession(ctx context.Context, sessionID string) (Session, error)
	TouchSession(ctx context.Context, sessionID string, at time.Time) error
	RevokeSession(ctx context.Context, sessionID string, at time.Time) error
	RecordAudit(ctx context.Context, event AuditEvent) error
}

type TenantMembership interface {
	CanAccessTenant(ctx context.Context, userID, tenantID string) bool
}

type Service struct {
	repo               Repository
	membership         TenantMembership
	policy             PasswordPolicy
	accessTokenTTL     time.Duration
	sessionAbsoluteTTL time.Duration
	now                func() time.Time
}

func NewService(repo Repository, membership TenantMembership, policy PasswordPolicy) *Service {
	if policy.MinLength == 0 {
		policy = DefaultPasswordPolicy()
	}
	return &Service{
		repo:               repo,
		membership:         membership,
		policy:             policy,
		accessTokenTTL:     15 * time.Minute,
		sessionAbsoluteTTL: 12 * time.Hour,
		now:                time.Now,
	}
}

func (s *Service) SetClock(now func() time.Time) {
	s.now = now
}

func (s *Service) ValidatePassword(password, confirm string) error {
	if password != confirm {
		return ErrPasswordMismatch
	}
	return CheckPasswordPolicy(password, s.policy)
}

func CheckPasswordPolicy(password string, policy PasswordPolicy) error {
	if len([]rune(password)) < policy.MinLength {
		return fmt.Errorf("%w: min length", ErrWeakPassword)
	}

	var upper, lower, digit, symbol bool
	for _, r := range password {
		switch {
		case r >= 'A' && r <= 'Z':
			upper = true
		case r >= 'a' && r <= 'z':
			lower = true
		case r >= '0' && r <= '9':
			digit = true
		default:
			symbol = true
		}
	}

	if policy.RequireUpper && !upper {
		return fmt.Errorf("%w: upper required", ErrWeakPassword)
	}
	if policy.RequireLower && !lower {
		return fmt.Errorf("%w: lower required", ErrWeakPassword)
	}
	if policy.RequireDigit && !digit {
		return fmt.Errorf("%w: digit required", ErrWeakPassword)
	}
	if policy.RequireSymbol && !symbol {
		return fmt.Errorf("%w: symbol required", ErrWeakPassword)
	}
	return nil
}

func (s *Service) SetupPassword(ctx context.Context, tenantID, userID, password, confirm, correlationID string) error {
	if !s.membership.CanAccessTenant(ctx, userID, tenantID) {
		return ErrTenantForbidden
	}
	if err := s.ValidatePassword(password, confirm); err != nil {
		return err
	}

	hash, salt, err := HashPassword(password)
	if err != nil {
		return err
	}

	now := s.now().UTC()
	credential := Credential{
		UserID:             userID,
		TenantID:           tenantID,
		PasswordHash:       hash,
		PasswordSalt:       salt,
		PasswordVersion:    1,
		PasswordChangedAt:  now,
		MustChangePassword: false,
	}

	if err := s.repo.SaveCredential(ctx, credential); err != nil {
		return err
	}

	return s.repo.RecordAudit(ctx, AuditEvent{
		EventID:       newID("audit"),
		TenantID:      tenantID,
		UserID:        userID,
		EventType:     "password_setup_completed",
		CorrelationID: correlationID,
		Metadata: map[string]string{
			"password_version": "1",
		},
		CreatedAt: now,
	})
}

func (s *Service) Login(ctx context.Context, tenantID, userID, password, correlationID string) (Session, string, error) {
	if !s.membership.CanAccessTenant(ctx, userID, tenantID) {
		return Session{}, "", ErrTenantForbidden
	}

	credential, err := s.repo.GetCredential(ctx, userID, tenantID)
	if err != nil {
		return Session{}, "", ErrInvalidCredentials
	}
	if !VerifyPassword(password, credential.PasswordSalt, credential.PasswordHash) {
		return Session{}, "", ErrInvalidCredentials
	}

	now := s.now().UTC()
	accessRaw, err := secureToken(32)
	if err != nil {
		return Session{}, "", err
	}
	refreshRaw, err := secureToken(32)
	if err != nil {
		return Session{}, "", err
	}

	session := Session{
		SessionID:        newID("sess"),
		UserID:           userID,
		TenantID:         tenantID,
		AccessTokenHash:  HashToken(accessRaw),
		RefreshTokenHash: HashToken(refreshRaw),
		IssuedAt:         now,
		LastSeenAt:       now,
		ExpiresAt:        now.Add(s.sessionAbsoluteTTL),
	}

	if err := s.repo.SaveSession(ctx, session); err != nil {
		return Session{}, "", err
	}

	_ = s.repo.RecordAudit(ctx, AuditEvent{
		EventID:       newID("audit"),
		TenantID:      tenantID,
		UserID:        userID,
		EventType:     "password_login_success",
		CorrelationID: correlationID,
		Metadata: map[string]string{
			"next_route": "/tenant-select/",
		},
		CreatedAt: now,
	})

	return session, "/tenant-select/", nil
}

func (s *Service) RequestPasswordReset(ctx context.Context, tenantID, userID, requestedIP, correlationID string) (string, ResetToken, error) {
	if !s.membership.CanAccessTenant(ctx, userID, tenantID) {
		return "", ResetToken{}, ErrTenantForbidden
	}

	raw, err := secureToken(32)
	if err != nil {
		return "", ResetToken{}, err
	}

	now := s.now().UTC()
	token := ResetToken{
		TokenID:     newID("reset"),
		UserID:      userID,
		TenantID:    tenantID,
		TokenHash:   HashToken(raw),
		ExpiresAt:   now.Add(30 * time.Minute),
		RequestedIP: requestedIP,
		CreatedAt:   now,
	}

	if err := s.repo.SaveResetToken(ctx, token); err != nil {
		return "", ResetToken{}, err
	}

	_ = s.repo.RecordAudit(ctx, AuditEvent{
		EventID:       newID("audit"),
		TenantID:      tenantID,
		UserID:        userID,
		EventType:     "password_reset_requested",
		CorrelationID: correlationID,
		Metadata:      map[string]string{"requested_ip": requestedIP},
		CreatedAt:     now,
	})

	return raw, token, nil
}

func (s *Service) ConsumePasswordReset(ctx context.Context, rawToken, newPassword, confirm, correlationID string) error {
	if err := s.ValidatePassword(newPassword, confirm); err != nil {
		return err
	}

	tokenHash := HashToken(rawToken)
	token, err := s.repo.GetResetTokenByHash(ctx, tokenHash)
	if err != nil {
		return ErrInvalidCredentials
	}
	if token.ConsumedAt != nil {
		return ErrResetTokenConsumed
	}
	if !s.now().UTC().Before(token.ExpiresAt) {
		return ErrResetTokenExpired
	}

	if err := s.SetupPassword(ctx, token.TenantID, token.UserID, newPassword, confirm, correlationID); err != nil {
		return err
	}

	now := s.now().UTC()
	if err := s.repo.ConsumeResetToken(ctx, tokenHash, now); err != nil {
		return err
	}

	return s.repo.RecordAudit(ctx, AuditEvent{
		EventID:       newID("audit"),
		TenantID:      token.TenantID,
		UserID:        token.UserID,
		EventType:     "password_reset_consumed",
		CorrelationID: correlationID,
		Metadata:      map[string]string{"token_id": token.TokenID},
		CreatedAt:     now,
	})
}

func (s *Service) ValidateSession(ctx context.Context, sessionID string) (Session, error) {
	session, err := s.repo.GetSession(ctx, sessionID)
	if err != nil {
		return Session{}, ErrInvalidCredentials
	}
	if session.RevokedAt != nil {
		return Session{}, ErrSessionRevoked
	}
	now := s.now().UTC()
	if !now.Before(session.ExpiresAt) {
		return Session{}, ErrSessionExpired
	}
	if err := s.repo.TouchSession(ctx, sessionID, now); err != nil {
		return Session{}, err
	}
	session.LastSeenAt = now
	return session, nil
}

func (s *Service) Logout(ctx context.Context, sessionID string) error {
	return s.repo.RevokeSession(ctx, sessionID, s.now().UTC())
}

func HashPassword(password string) (hash string, salt string, err error) {
	saltBytes := make([]byte, 16)
	if _, err := rand.Read(saltBytes); err != nil {
		return "", "", err
	}
	salt = base64.RawURLEncoding.EncodeToString(saltBytes)
	hash = derivePasswordHash(password, salt)
	return hash, salt, nil
}

func VerifyPassword(password, salt, expectedHash string) bool {
	actual := derivePasswordHash(password, salt)
	return hmac.Equal([]byte(actual), []byte(expectedHash))
}

func derivePasswordHash(password, salt string) string {
	key := []byte(password)
	data := []byte(salt)

	sum := make([]byte, 32)
	block := data
	for i := 0; i < 120000; i++ {
		h := hmac.New(sha256.New, key)
		h.Write(block)
		block = h.Sum(nil)
		for j := range sum {
			sum[j] ^= block[j]
		}
	}
	return hex.EncodeToString(sum)
}

func HashToken(raw string) string {
	sum := sha256.Sum256([]byte(raw))
	return hex.EncodeToString(sum[:])
}

func secureToken(size int) (string, error) {
	buf := make([]byte, size)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(buf), nil
}

func newID(prefix string) string {
	raw, err := secureToken(12)
	if err != nil {
		return prefix + "_" + strings.ReplaceAll(time.Now().UTC().Format(time.RFC3339Nano), ":", "_")
	}
	return prefix + "_" + raw
}
