package loginerrors

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"
)

type Code string
type Locale string

const (
	LocaleTR Locale = "tr-TR"
	LocaleEN Locale = "en"

	CodeValidationRequired Code = "AUTH_VALIDATION_REQUIRED"
	CodeInvalidCredentials Code = "AUTH_INVALID_CREDENTIALS"
	CodeAccountInactive    Code = "AUTH_ACCOUNT_INACTIVE"
	CodeTenantAccessDenied Code = "AUTH_TENANT_ACCESS_DENIED"
	CodeTokenInvalid       Code = "AUTH_TOKEN_INVALID"
	CodeTokenExpired       Code = "AUTH_TOKEN_EXPIRED"
	CodeSessionExpired     Code = "AUTH_SESSION_EXPIRED"
	CodeRateLimited        Code = "AUTH_RATE_LIMITED"
	CodeInternal           Code = "AUTH_INTERNAL_ERROR"
)

var (
	ErrValidationRequired = errors.New("validation required")
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrAccountInactive    = errors.New("account inactive")
	ErrTenantAccessDenied = errors.New("tenant access denied")
	ErrTokenInvalid       = errors.New("token invalid")
	ErrTokenExpired       = errors.New("token expired")
	ErrSessionExpired     = errors.New("session expired")
	ErrRateLimited        = errors.New("rate limited")
	ErrInternal           = errors.New("internal auth error")
)

type Definition struct {
	Code       Code
	HTTPStatus int
	Messages   map[Locale]string
	Family     string
	Severity   string
}

type PublicError struct {
	Code          Code   `json:"code"`
	Message       string `json:"message"`
	HTTPStatus    int    `json:"http_status"`
	CorrelationID string `json:"correlation_id"`
}

type Event struct {
	TenantID      string
	UserID        string
	Email         string
	ErrorCode     Code
	HTTPStatus    int
	CorrelationID string
	IPAddress     string
	UserAgent     string
	OccurredAt    time.Time
}

type RequestContext struct {
	TenantID      string
	UserID        string
	Email         string
	CorrelationID string
	IPAddress     string
	UserAgent     string
	Locale        Locale
}

type Store interface {
	RecordLoginError(ctx context.Context, event Event) error
}

type Service struct {
	store Store
	now   func() time.Time
}

func NewService(store Store, now func() time.Time) *Service {
	if now == nil {
		now = time.Now
	}
	return &Service{store: store, now: now}
}

func Catalog() map[Code]Definition {
	return map[Code]Definition{
		CodeValidationRequired: {
			Code:       CodeValidationRequired,
			HTTPStatus: http.StatusBadRequest,
			Family:     "validation",
			Severity:   "low",
			Messages: map[Locale]string{
				LocaleTR: "Gerekli alanları kontrol edin.",
				LocaleEN: "Check the required fields.",
			},
		},
		CodeInvalidCredentials: {
			Code:       CodeInvalidCredentials,
			HTTPStatus: http.StatusUnauthorized,
			Family:     "credential",
			Severity:   "medium",
			Messages: map[Locale]string{
				LocaleTR: "E-posta veya şifre hatalı.",
				LocaleEN: "Email or password is incorrect.",
			},
		},
		CodeAccountInactive: {
			Code:       CodeAccountInactive,
			HTTPStatus: http.StatusForbidden,
			Family:     "credential",
			Severity:   "medium",
			Messages: map[Locale]string{
				LocaleTR: "Bu kullanıcı hesabı aktif değil.",
				LocaleEN: "This user account is not active.",
			},
		},
		CodeTenantAccessDenied: {
			Code:       CodeTenantAccessDenied,
			HTTPStatus: http.StatusForbidden,
			Family:     "tenant",
			Severity:   "high",
			Messages: map[Locale]string{
				LocaleTR: "Bu işletmeye erişim yetkiniz yok.",
				LocaleEN: "You do not have access to this business.",
			},
		},
		CodeTokenInvalid: {
			Code:       CodeTokenInvalid,
			HTTPStatus: http.StatusUnauthorized,
			Family:     "token",
			Severity:   "medium",
			Messages: map[Locale]string{
				LocaleTR: "Giriş oturumu doğrulanamadı.",
				LocaleEN: "The login session could not be verified.",
			},
		},
		CodeTokenExpired: {
			Code:       CodeTokenExpired,
			HTTPStatus: http.StatusUnauthorized,
			Family:     "token",
			Severity:   "medium",
			Messages: map[Locale]string{
				LocaleTR: "Oturum süreniz doldu. Tekrar giriş yapın.",
				LocaleEN: "Your session has expired. Sign in again.",
			},
		},
		CodeSessionExpired: {
			Code:       CodeSessionExpired,
			HTTPStatus: http.StatusUnauthorized,
			Family:     "session",
			Severity:   "medium",
			Messages: map[Locale]string{
				LocaleTR: "Oturum zaman aşımına uğradı. Tekrar giriş yapın.",
				LocaleEN: "The session timed out. Sign in again.",
			},
		},
		CodeRateLimited: {
			Code:       CodeRateLimited,
			HTTPStatus: http.StatusTooManyRequests,
			Family:     "rate_limit",
			Severity:   "high",
			Messages: map[Locale]string{
				LocaleTR: "Çok fazla deneme yapıldı. Biraz bekleyip tekrar deneyin.",
				LocaleEN: "Too many attempts. Wait a moment and try again.",
			},
		},
		CodeInternal: {
			Code:       CodeInternal,
			HTTPStatus: http.StatusInternalServerError,
			Family:     "internal",
			Severity:   "critical",
			Messages: map[Locale]string{
				LocaleTR: "Giriş işlemi şu anda tamamlanamadı.",
				LocaleEN: "The sign-in process could not be completed right now.",
			},
		},
	}
}

func (s *Service) Build(ctx context.Context, err error, req RequestContext) PublicError {
	code := CodeFromError(err)
	definition := MustDefinition(code)
	locale := normalizeLocale(req.Locale)

	correlationID := strings.TrimSpace(req.CorrelationID)
	if correlationID == "" {
		correlationID = "auth-correlation-missing"
	}

	public := PublicError{
		Code:          definition.Code,
		Message:       definition.Messages[locale],
		HTTPStatus:    definition.HTTPStatus,
		CorrelationID: correlationID,
	}

	if s.store != nil {
		_ = s.store.RecordLoginError(ctx, Event{
			TenantID:      req.TenantID,
			UserID:        req.UserID,
			Email:         strings.TrimSpace(strings.ToLower(req.Email)),
			ErrorCode:     definition.Code,
			HTTPStatus:    definition.HTTPStatus,
			CorrelationID: correlationID,
			IPAddress:     req.IPAddress,
			UserAgent:     req.UserAgent,
			OccurredAt:    s.now().UTC(),
		})
	}

	return public
}

func (s *Service) WriteHTTP(ctx context.Context, w http.ResponseWriter, err error, req RequestContext) {
	public := s.Build(ctx, err, req)
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Correlation-ID", public.CorrelationID)
	w.WriteHeader(public.HTTPStatus)
	_ = json.NewEncoder(w).Encode(public)
}

func CodeFromError(err error) Code {
	switch {
	case errors.Is(err, ErrValidationRequired):
		return CodeValidationRequired
	case errors.Is(err, ErrInvalidCredentials):
		return CodeInvalidCredentials
	case errors.Is(err, ErrAccountInactive):
		return CodeAccountInactive
	case errors.Is(err, ErrTenantAccessDenied):
		return CodeTenantAccessDenied
	case errors.Is(err, ErrTokenInvalid):
		return CodeTokenInvalid
	case errors.Is(err, ErrTokenExpired):
		return CodeTokenExpired
	case errors.Is(err, ErrSessionExpired):
		return CodeSessionExpired
	case errors.Is(err, ErrRateLimited):
		return CodeRateLimited
	default:
		return CodeInternal
	}
}

func MustDefinition(code Code) Definition {
	definition, ok := Catalog()[code]
	if !ok {
		return Catalog()[CodeInternal]
	}
	return definition
}

func ValidateCatalog() error {
	for code, definition := range Catalog() {
		if definition.Code != code {
			return errors.New("catalog code mismatch")
		}
		if definition.HTTPStatus < 400 || definition.HTTPStatus > 599 {
			return errors.New("catalog status out of range")
		}
		if strings.TrimSpace(definition.Messages[LocaleTR]) == "" {
			return errors.New("tr-TR message missing")
		}
		if strings.TrimSpace(definition.Messages[LocaleEN]) == "" {
			return errors.New("en message missing")
		}
		if strings.TrimSpace(definition.Family) == "" {
			return errors.New("family missing")
		}
		if strings.TrimSpace(definition.Severity) == "" {
			return errors.New("severity missing")
		}
	}
	return nil
}

func normalizeLocale(locale Locale) Locale {
	switch locale {
	case LocaleTR, LocaleEN:
		return locale
	default:
		return LocaleTR
	}
}
