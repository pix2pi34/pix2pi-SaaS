package publicapi

import (
	"strings"
	"time"
)

var allowedPublicAPIAppAuthStatuses = map[string]struct{}{
	"authenticated": {},
	"denied":        {},
}

type AuthenticatePublicAPIAppRequest struct {
	TenantID       string   `json:"tenant_id,omitempty"`
	RequestID      string   `json:"request_id"`
	AppID          string   `json:"app_id"`
	APIKeyID       string   `json:"api_key_id"`
	KeyFingerprint string   `json:"key_fingerprint"`
	Environment    string   `json:"environment"`
	RequiredScopes []string `json:"required_scopes"`
	RequestedBy    string   `json:"requested_by"`
}

type AuthenticatePublicAPIAppResponse struct {
	RequestID      string    `json:"request_id"`
	AppID          string    `json:"app_id"`
	APIKeyID       string    `json:"api_key_id"`
	Environment    string    `json:"environment"`
	GrantedScopes  []string  `json:"granted_scopes"`
	AuthStatus     string    `json:"auth_status"`
	Authenticated  bool      `json:"authenticated"`
	DenialReason   string    `json:"denial_reason,omitempty"`
	AuthenticatedAt time.Time `json:"authenticated_at"`
}

func (r AuthenticatePublicAPIAppRequest) Validate() error {
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

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.KeyFingerprint)) {
		errs = append(errs, ValidationError{Field: "key_fingerprint", Message: "gecersiz format"})
	}

	if !containsValue(allowedPublicAPIKeyEnvironments, strings.TrimSpace(r.Environment)) {
		errs = append(errs, ValidationError{Field: "environment", Message: "desteklenmeyen deger"})
	}

	if len(r.RequiredScopes) == 0 {
		errs = append(errs, ValidationError{Field: "required_scopes", Message: "en az bir scope olmali"})
	}

	seenScopes := map[string]struct{}{}
	for _, scope := range r.RequiredScopes {
		scope = strings.TrimSpace(scope)
		if !containsValue(allowedPublicAPIKeyScopes, scope) {
			errs = append(errs, ValidationError{Field: "required_scopes", Message: "desteklenmeyen scope: " + scope})
			continue
		}

		if _, ok := seenScopes[scope]; ok {
			errs = append(errs, ValidationError{Field: "required_scopes", Message: "tekrar eden scope: " + scope})
		}
		seenScopes[scope] = struct{}{}
	}

	if !publicAPIActorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{Field: "requested_by", Message: "gecersiz format"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r AuthenticatePublicAPIAppResponse) Validate() error {
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

	if !containsValue(allowedPublicAPIKeyEnvironments, strings.TrimSpace(r.Environment)) {
		errs = append(errs, ValidationError{Field: "environment", Message: "desteklenmeyen deger"})
	}

	if len(r.GrantedScopes) == 0 {
		errs = append(errs, ValidationError{Field: "granted_scopes", Message: "en az bir scope olmali"})
	}

	for _, scope := range r.GrantedScopes {
		if !containsValue(allowedPublicAPIKeyScopes, strings.TrimSpace(scope)) {
			errs = append(errs, ValidationError{Field: "granted_scopes", Message: "desteklenmeyen scope"})
		}
	}

	if !containsValue(allowedPublicAPIAppAuthStatuses, strings.TrimSpace(r.AuthStatus)) {
		errs = append(errs, ValidationError{Field: "auth_status", Message: "desteklenmeyen deger"})
	}

	if r.Authenticated && strings.TrimSpace(r.AuthStatus) != "authenticated" {
		errs = append(errs, ValidationError{Field: "auth_status", Message: "authenticated true ise authenticated olmali"})
	}

	if !r.Authenticated && strings.TrimSpace(r.DenialReason) == "" {
		errs = append(errs, ValidationError{Field: "denial_reason", Message: "denied durumda zorunlu alan"})
	}

	if r.AuthenticatedAt.IsZero() {
		errs = append(errs, ValidationError{Field: "authenticated_at", Message: "zorunlu alan"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
