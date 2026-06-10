package jwtlogin

import (
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
)

var (
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrTenantForbidden    = errors.New("tenant forbidden")
	ErrTokenExpired       = errors.New("token expired")
	ErrTokenInvalid       = errors.New("token invalid")
	ErrMissingSecret      = errors.New("jwt secret is required")
)

type Config struct {
	Issuer          string
	Audience        string
	Secret          []byte
	AccessTokenTTL  time.Duration
	RefreshTokenTTL time.Duration
	Now             func() time.Time
}

type User struct {
	ID           string
	Email        string
	PasswordHash string
	Status       string
}

type TenantMembership struct {
	TenantID string
	UserID   string
	RoleCode string
	Status   string
}

type LoginInput struct {
	Email     string
	Password  string
	TenantID  string
	IPAddress string
	UserAgent string
}

type LoginResult struct {
	UserID                string
	TenantID              string
	RoleCode              string
	SessionID             string
	AccessToken           string
	RefreshToken          string
	AccessTokenID         string
	RefreshTokenID        string
	IssuedAt              time.Time
	AccessTokenExpiresAt  time.Time
	RefreshTokenExpiresAt time.Time
}

type Claims struct {
	Issuer    string   `json:"iss"`
	Audience  string   `json:"aud"`
	Subject   string   `json:"sub"`
	TenantID  string   `json:"tenant_id"`
	RoleCode  string   `json:"role_code"`
	SessionID string   `json:"sid"`
	TokenID   string   `json:"jti"`
	TokenUse  string   `json:"token_use"`
	IssuedAt  int64    `json:"iat"`
	ExpiresAt int64    `json:"exp"`
	Scopes    []string `json:"scp"`
}

type SessionRecord struct {
	ID                    string
	TenantID              string
	UserID                string
	SessionID             string
	AccessTokenID         string
	RefreshTokenID        string
	IssuedAt              time.Time
	AccessTokenExpiresAt  time.Time
	RefreshTokenExpiresAt time.Time
	IPAddress             string
	UserAgent             string
}

type UserStore interface {
	FindUserByEmail(ctx context.Context, email string) (User, error)
	FindTenantMembership(ctx context.Context, userID string, tenantID string) (TenantMembership, error)
	RecordLoginSession(ctx context.Context, record SessionRecord) error
}

type PasswordVerifier interface {
	VerifyPassword(password string, passwordHash string) bool
}

type HMACPasswordVerifier struct {
	Secret []byte
}

func (v HMACPasswordVerifier) HashPassword(password string) string {
	mac := hmac.New(sha256.New, v.Secret)
	mac.Write([]byte(password))
	return base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
}

func (v HMACPasswordVerifier) VerifyPassword(password string, passwordHash string) bool {
	expected := v.HashPassword(password)
	return hmac.Equal([]byte(expected), []byte(passwordHash))
}

type Service struct {
	config   Config
	store    UserStore
	verifier PasswordVerifier
}

func NewService(config Config, store UserStore, verifier PasswordVerifier) (*Service, error) {
	if len(config.Secret) < 32 {
		return nil, ErrMissingSecret
	}
	if config.Issuer == "" {
		config.Issuer = "pix2pi-auth"
	}
	if config.Audience == "" {
		config.Audience = "pix2pi-panel"
	}
	if config.AccessTokenTTL <= 0 {
		config.AccessTokenTTL = time.Hour
	}
	if config.RefreshTokenTTL <= 0 {
		config.RefreshTokenTTL = 30 * 24 * time.Hour
	}
	if config.Now == nil {
		config.Now = time.Now
	}

	return &Service{
		config:   config,
		store:    store,
		verifier: verifier,
	}, nil
}

func (s *Service) Login(ctx context.Context, input LoginInput) (LoginResult, error) {
	email := strings.TrimSpace(strings.ToLower(input.Email))
	tenantID := strings.TrimSpace(input.TenantID)

	if email == "" || input.Password == "" || tenantID == "" {
		return LoginResult{}, ErrInvalidCredentials
	}

	user, err := s.store.FindUserByEmail(ctx, email)
	if err != nil {
		return LoginResult{}, ErrInvalidCredentials
	}
	if user.Status != "active" {
		return LoginResult{}, ErrInvalidCredentials
	}
	if !s.verifier.VerifyPassword(input.Password, user.PasswordHash) {
		return LoginResult{}, ErrInvalidCredentials
	}

	membership, err := s.store.FindTenantMembership(ctx, user.ID, tenantID)
	if err != nil {
		return LoginResult{}, ErrTenantForbidden
	}
	if membership.Status != "active" {
		return LoginResult{}, ErrTenantForbidden
	}

	now := s.config.Now().UTC()
	sessionID := secureID("sess")
	accessTokenID := secureID("atk")
	refreshTokenID := secureID("rtk")
	accessExpiresAt := now.Add(s.config.AccessTokenTTL)
	refreshExpiresAt := now.Add(s.config.RefreshTokenTTL)

	accessClaims := Claims{
		Issuer:    s.config.Issuer,
		Audience:  s.config.Audience,
		Subject:   user.ID,
		TenantID:  tenantID,
		RoleCode:  membership.RoleCode,
		SessionID: sessionID,
		TokenID:   accessTokenID,
		TokenUse:  "access",
		IssuedAt:  now.Unix(),
		ExpiresAt: accessExpiresAt.Unix(),
		Scopes:    []string{"panel:access", "tenant:" + tenantID, "role:" + membership.RoleCode},
	}

	refreshClaims := Claims{
		Issuer:    s.config.Issuer,
		Audience:  s.config.Audience,
		Subject:   user.ID,
		TenantID:  tenantID,
		RoleCode:  membership.RoleCode,
		SessionID: sessionID,
		TokenID:   refreshTokenID,
		TokenUse:  "refresh",
		IssuedAt:  now.Unix(),
		ExpiresAt: refreshExpiresAt.Unix(),
		Scopes:    []string{"auth:refresh", "tenant:" + tenantID},
	}

	accessToken, err := s.Sign(accessClaims)
	if err != nil {
		return LoginResult{}, err
	}
	refreshToken, err := s.Sign(refreshClaims)
	if err != nil {
		return LoginResult{}, err
	}

	record := SessionRecord{
		ID:                    secureID("dbsess"),
		TenantID:              tenantID,
		UserID:                user.ID,
		SessionID:             sessionID,
		AccessTokenID:         accessTokenID,
		RefreshTokenID:        refreshTokenID,
		IssuedAt:              now,
		AccessTokenExpiresAt:  accessExpiresAt,
		RefreshTokenExpiresAt: refreshExpiresAt,
		IPAddress:             input.IPAddress,
		UserAgent:             input.UserAgent,
	}

	if err := s.store.RecordLoginSession(ctx, record); err != nil {
		return LoginResult{}, err
	}

	return LoginResult{
		UserID:                user.ID,
		TenantID:              tenantID,
		RoleCode:              membership.RoleCode,
		SessionID:             sessionID,
		AccessToken:           accessToken,
		RefreshToken:          refreshToken,
		AccessTokenID:         accessTokenID,
		RefreshTokenID:        refreshTokenID,
		IssuedAt:              now,
		AccessTokenExpiresAt:  accessExpiresAt,
		RefreshTokenExpiresAt: refreshExpiresAt,
	}, nil
}

func (s *Service) Sign(claims Claims) (string, error) {
	header := map[string]string{
		"alg": "HS256",
		"typ": "JWT",
	}

	headerBytes, err := json.Marshal(header)
	if err != nil {
		return "", err
	}
	claimBytes, err := json.Marshal(claims)
	if err != nil {
		return "", err
	}

	unsigned := base64.RawURLEncoding.EncodeToString(headerBytes) + "." + base64.RawURLEncoding.EncodeToString(claimBytes)
	signature := signHS256(unsigned, s.config.Secret)

	return unsigned + "." + signature, nil
}

func (s *Service) Verify(token string) (Claims, error) {
	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		return Claims{}, ErrTokenInvalid
	}

	unsigned := parts[0] + "." + parts[1]
	expectedSignature := signHS256(unsigned, s.config.Secret)
	if !hmac.Equal([]byte(expectedSignature), []byte(parts[2])) {
		return Claims{}, ErrTokenInvalid
	}

	payloadBytes, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil {
		return Claims{}, ErrTokenInvalid
	}

	var claims Claims
	if err := json.Unmarshal(payloadBytes, &claims); err != nil {
		return Claims{}, ErrTokenInvalid
	}

	if claims.Issuer != s.config.Issuer || claims.Audience != s.config.Audience {
		return Claims{}, ErrTokenInvalid
	}

	now := s.config.Now().UTC().Unix()
	if claims.ExpiresAt <= now {
		return Claims{}, ErrTokenExpired
	}

	return claims, nil
}

func signHS256(unsigned string, secret []byte) string {
	mac := hmac.New(sha256.New, secret)
	mac.Write([]byte(unsigned))
	return base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
}

func secureID(prefix string) string {
	buf := make([]byte, 18)
	if _, err := rand.Read(buf); err != nil {
		panic(fmt.Sprintf("secure id generation failed: %v", err))
	}
	return prefix + "_" + base64.RawURLEncoding.EncodeToString(buf)
}
