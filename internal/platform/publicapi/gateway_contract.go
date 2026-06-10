package publicapi

import (
	"regexp"
	"strings"
	"time"
)

var (
	publicAPIKeyPattern      = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
	publicAPIPathPattern     = regexp.MustCompile(`^/[A-Za-z0-9._~:/?#\[\]@!$&'()*+,;=%-]*$`)
	publicAPIActorRefPattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._:-]*$`)
)

var allowedPublicAPIMethods = map[string]struct{}{
	"GET":    {},
	"POST":   {},
	"PUT":    {},
	"PATCH":  {},
	"DELETE": {},
}

var allowedPublicAPIGatewayStatuses = map[string]struct{}{
	"accepted": {},
	"rejected": {},
}

type ValidationError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

type ValidationErrors []ValidationError

func (v ValidationErrors) Error() string {
	if len(v) == 0 {
		return "validation failed"
	}

	parts := make([]string, 0, len(v))
	for _, item := range v {
		parts = append(parts, item.Field+": "+item.Message)
	}

	return strings.Join(parts, ", ")
}

func containsValue(values map[string]struct{}, value string) bool {
	_, ok := values[value]
	return ok
}

type ResolvePublicAPIGatewayRequest struct {
	TenantID    string `json:"tenant_id,omitempty"`
	RequestID   string `json:"request_id"`
	AppID       string `json:"app_id"`
	APIKeyID    string `json:"api_key_id"`
	Method      string `json:"method"`
	Path        string `json:"path"`
	Origin      string `json:"origin,omitempty"`
	RequestedBy string `json:"requested_by"`
}

type ResolvePublicAPIGatewayResponse struct {
	RequestID       string    `json:"request_id"`
	AppID           string    `json:"app_id"`
	APIKeyID        string    `json:"api_key_id"`
	Method          string    `json:"method"`
	Path            string    `json:"path"`
	TargetService   string    `json:"target_service,omitempty"`
	TargetPath      string    `json:"target_path,omitempty"`
	GatewayStatus   string    `json:"gateway_status"`
	Accepted        bool      `json:"accepted"`
	RejectionReason string    `json:"rejection_reason,omitempty"`
	ResolvedAt      time.Time `json:"resolved_at"`
}

func (r ResolvePublicAPIGatewayRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.RequestID)) {
		errs = append(errs, ValidationError{Field: "request_id", Message: "gecersiz format"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.AppID)) {
		errs = append(errs, ValidationError{Field: "app_id", Message: "gecersiz format"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.APIKeyID)) {
		errs = append(errs, ValidationError{Field: "api_key_id", Message: "gecersiz format"})
	}

	method := strings.ToUpper(strings.TrimSpace(r.Method))
	if !containsValue(allowedPublicAPIMethods, method) {
		errs = append(errs, ValidationError{Field: "method", Message: "desteklenmeyen deger"})
	}

	if !publicAPIPathPattern.MatchString(strings.TrimSpace(r.Path)) {
		errs = append(errs, ValidationError{Field: "path", Message: "gecersiz format"})
	}

	origin := strings.TrimSpace(r.Origin)
	if origin != "" && !(strings.HasPrefix(origin, "https://") || strings.HasPrefix(origin, "http://")) {
		errs = append(errs, ValidationError{Field: "origin", Message: "http veya https URL olmali"})
	}

	if !publicAPIActorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{Field: "requested_by", Message: "gecersiz format"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r ResolvePublicAPIGatewayResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.RequestID)) {
		errs = append(errs, ValidationError{Field: "request_id", Message: "gecersiz format"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.AppID)) {
		errs = append(errs, ValidationError{Field: "app_id", Message: "gecersiz format"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.APIKeyID)) {
		errs = append(errs, ValidationError{Field: "api_key_id", Message: "gecersiz format"})
	}

	method := strings.ToUpper(strings.TrimSpace(r.Method))
	if !containsValue(allowedPublicAPIMethods, method) {
		errs = append(errs, ValidationError{Field: "method", Message: "desteklenmeyen deger"})
	}

	if !publicAPIPathPattern.MatchString(strings.TrimSpace(r.Path)) {
		errs = append(errs, ValidationError{Field: "path", Message: "gecersiz format"})
	}

	if !containsValue(allowedPublicAPIGatewayStatuses, strings.TrimSpace(r.GatewayStatus)) {
		errs = append(errs, ValidationError{Field: "gateway_status", Message: "desteklenmeyen deger"})
	}

	if r.Accepted {
		if strings.TrimSpace(r.GatewayStatus) != "accepted" {
			errs = append(errs, ValidationError{Field: "gateway_status", Message: "accepted true ise accepted olmali"})
		}

		if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.TargetService)) {
			errs = append(errs, ValidationError{Field: "target_service", Message: "gecersiz format"})
		}

		if !publicAPIPathPattern.MatchString(strings.TrimSpace(r.TargetPath)) {
			errs = append(errs, ValidationError{Field: "target_path", Message: "gecersiz format"})
		}
	}

	if !r.Accepted && strings.TrimSpace(r.RejectionReason) == "" {
		errs = append(errs, ValidationError{Field: "rejection_reason", Message: "rejected durumda zorunlu alan"})
	}

	if r.ResolvedAt.IsZero() {
		errs = append(errs, ValidationError{Field: "resolved_at", Message: "zorunlu alan"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
