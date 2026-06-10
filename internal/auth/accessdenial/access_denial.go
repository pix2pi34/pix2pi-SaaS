package accessdenial

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"
)

type DenialCode string
type ScreenType string
type Locale string

const (
	ScreenUnauthorized ScreenType = "unauthorized"
	ScreenForbidden    ScreenType = "forbidden"

	LocaleTR Locale = "tr-TR"
	LocaleEN Locale = "en"

	CodeMissingToken       DenialCode = "AUTH_MISSING_TOKEN"
	CodeInvalidToken       DenialCode = "AUTH_INVALID_TOKEN"
	CodeExpiredSession     DenialCode = "AUTH_EXPIRED_SESSION"
	CodeTenantAccessDenied DenialCode = "AUTH_TENANT_ACCESS_DENIED"
	CodePermissionDenied   DenialCode = "AUTH_PERMISSION_DENIED"
	CodeRoleDenied         DenialCode = "AUTH_ROLE_DENIED"
)

var (
	ErrMissingToken       = errors.New("missing token")
	ErrInvalidToken       = errors.New("invalid token")
	ErrExpiredSession     = errors.New("expired session")
	ErrTenantAccessDenied = errors.New("tenant access denied")
	ErrPermissionDenied   = errors.New("permission denied")
	ErrRoleDenied         = errors.New("role denied")
)

type Definition struct {
	Code       DenialCode
	HTTPStatus int
	Screen     ScreenType
	Messages   map[Locale]string
}

type RequestContext struct {
	TenantID      string
	UserID        string
	RoleCode      string
	RoutePath     string
	ActionCode    string
	CorrelationID string
	IPAddress     string
	UserAgent     string
	Locale        Locale
}

type Decision struct {
	Code          DenialCode `json:"code"`
	HTTPStatus    int        `json:"http_status"`
	Screen        ScreenType `json:"screen"`
	Message       string     `json:"message"`
	RoutePath     string     `json:"route_path"`
	ActionCode    string     `json:"action_code"`
	CorrelationID string     `json:"correlation_id"`
}

type Event struct {
	TenantID      string
	UserID        string
	RoleCode      string
	RoutePath     string
	ActionCode    string
	DenialCode    DenialCode
	HTTPStatus    int
	CorrelationID string
	IPAddress     string
	UserAgent     string
	OccurredAt    time.Time
}

type Store interface {
	RecordAccessDenial(ctx context.Context, event Event) error
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

func Catalog() map[DenialCode]Definition {
	return map[DenialCode]Definition{
		CodeMissingToken: {
			Code:       CodeMissingToken,
			HTTPStatus: http.StatusUnauthorized,
			Screen:     ScreenUnauthorized,
			Messages: map[Locale]string{
				LocaleTR: "Bu sayfayı görmek için giriş yapmalısınız.",
				LocaleEN: "You must sign in to view this page.",
			},
		},
		CodeInvalidToken: {
			Code:       CodeInvalidToken,
			HTTPStatus: http.StatusUnauthorized,
			Screen:     ScreenUnauthorized,
			Messages: map[Locale]string{
				LocaleTR: "Oturum doğrulanamadı. Tekrar giriş yapın.",
				LocaleEN: "The session could not be verified. Sign in again.",
			},
		},
		CodeExpiredSession: {
			Code:       CodeExpiredSession,
			HTTPStatus: http.StatusUnauthorized,
			Screen:     ScreenUnauthorized,
			Messages: map[Locale]string{
				LocaleTR: "Oturum süreniz doldu. Tekrar giriş yapın.",
				LocaleEN: "Your session has expired. Sign in again.",
			},
		},
		CodeTenantAccessDenied: {
			Code:       CodeTenantAccessDenied,
			HTTPStatus: http.StatusForbidden,
			Screen:     ScreenForbidden,
			Messages: map[Locale]string{
				LocaleTR: "Bu işletmeye erişim yetkiniz yok.",
				LocaleEN: "You do not have access to this business.",
			},
		},
		CodePermissionDenied: {
			Code:       CodePermissionDenied,
			HTTPStatus: http.StatusForbidden,
			Screen:     ScreenForbidden,
			Messages: map[Locale]string{
				LocaleTR: "Bu işlem için yetkiniz yok.",
				LocaleEN: "You do not have permission for this action.",
			},
		},
		CodeRoleDenied: {
			Code:       CodeRoleDenied,
			HTTPStatus: http.StatusForbidden,
			Screen:     ScreenForbidden,
			Messages: map[Locale]string{
				LocaleTR: "Rolünüz bu sayfaya erişim için yeterli değil.",
				LocaleEN: "Your role is not allowed to access this page.",
			},
		},
	}
}

func (s *Service) Decide(ctx context.Context, err error, req RequestContext) Decision {
	code := CodeFromError(err)
	definition := MustDefinition(code)
	locale := normalizeLocale(req.Locale)

	routePath := strings.TrimSpace(req.RoutePath)
	if routePath == "" {
		routePath = "/"
	}

	actionCode := strings.TrimSpace(req.ActionCode)
	if actionCode == "" {
		actionCode = "route:access"
	}

	correlationID := strings.TrimSpace(req.CorrelationID)
	if correlationID == "" {
		correlationID = "access-correlation-missing"
	}

	decision := Decision{
		Code:          definition.Code,
		HTTPStatus:    definition.HTTPStatus,
		Screen:        definition.Screen,
		Message:       definition.Messages[locale],
		RoutePath:     routePath,
		ActionCode:    actionCode,
		CorrelationID: correlationID,
	}

	if s.store != nil {
		_ = s.store.RecordAccessDenial(ctx, Event{
			TenantID:      req.TenantID,
			UserID:        req.UserID,
			RoleCode:      req.RoleCode,
			RoutePath:     routePath,
			ActionCode:    actionCode,
			DenialCode:    definition.Code,
			HTTPStatus:    definition.HTTPStatus,
			CorrelationID: correlationID,
			IPAddress:     req.IPAddress,
			UserAgent:     req.UserAgent,
			OccurredAt:    s.now().UTC(),
		})
	}

	return decision
}

func (s *Service) WriteHTTP(ctx context.Context, w http.ResponseWriter, err error, req RequestContext) {
	decision := s.Decide(ctx, err, req)
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Correlation-ID", decision.CorrelationID)
	w.Header().Set("X-Access-Denial-Screen", string(decision.Screen))
	w.WriteHeader(decision.HTTPStatus)
	_ = json.NewEncoder(w).Encode(decision)
}

func CodeFromError(err error) DenialCode {
	switch {
	case errors.Is(err, ErrMissingToken):
		return CodeMissingToken
	case errors.Is(err, ErrInvalidToken):
		return CodeInvalidToken
	case errors.Is(err, ErrExpiredSession):
		return CodeExpiredSession
	case errors.Is(err, ErrTenantAccessDenied):
		return CodeTenantAccessDenied
	case errors.Is(err, ErrPermissionDenied):
		return CodePermissionDenied
	case errors.Is(err, ErrRoleDenied):
		return CodeRoleDenied
	default:
		return CodePermissionDenied
	}
}

func MustDefinition(code DenialCode) Definition {
	definition, ok := Catalog()[code]
	if !ok {
		return Catalog()[CodePermissionDenied]
	}
	return definition
}

func ValidateCatalog() error {
	for code, definition := range Catalog() {
		if definition.Code != code {
			return errors.New("catalog code mismatch")
		}
		if definition.HTTPStatus != http.StatusUnauthorized && definition.HTTPStatus != http.StatusForbidden {
			return errors.New("invalid status")
		}
		if definition.Screen != ScreenUnauthorized && definition.Screen != ScreenForbidden {
			return errors.New("invalid screen")
		}
		if strings.TrimSpace(definition.Messages[LocaleTR]) == "" {
			return errors.New("tr-TR message missing")
		}
		if strings.TrimSpace(definition.Messages[LocaleEN]) == "" {
			return errors.New("en message missing")
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
