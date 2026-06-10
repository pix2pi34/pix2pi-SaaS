package publicapi

import (
	"strings"
	"time"
)

var allowedPublicAPIKeyEnvironments = map[string]struct{}{
	"production": {},
	"sandbox":    {},
}

var allowedPublicAPIKeyScopes = map[string]struct{}{
	"erp.read":          {},
	"erp.write":         {},
	"webhook.manage":    {},
	"developer.manage":  {},
	"usage.read":        {},
}

var allowedPublicAPIKeyStatuses = map[string]struct{}{
	"active":  {},
	"blocked": {},
}

type IssuePublicAPIKeyRequest struct {
	TenantID    string     `json:"tenant_id,omitempty"`
	AppID       string     `json:"app_id"`
	KeyName     string     `json:"key_name"`
	Environment string     `json:"environment"`
	Scopes      []string   `json:"scopes"`
	ExpiresAt   *time.Time `json:"expires_at,omitempty"`
	RequestedBy string     `json:"requested_by"`
}

type IssuePublicAPIKeyResponse struct {
	APIKeyID     string     `json:"api_key_id"`
	AppID        string     `json:"app_id"`
	KeyName      string     `json:"key_name"`
	Environment  string     `json:"environment"`
	Scopes       []string   `json:"scopes"`
	KeyPrefix    string     `json:"key_prefix"`
	KeyPreview   string     `json:"key_preview"`
	KeyFingerprint string   `json:"key_fingerprint"`
	Status       string     `json:"status"`
	Issued       bool       `json:"issued"`
	ExpiresAt    *time.Time `json:"expires_at,omitempty"`
	IssuedAt     time.Time  `json:"issued_at"`
}

func (r IssuePublicAPIKeyRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.AppID)) {
		errs = append(errs, ValidationError{Field: "app_id", Message: "gecersiz format"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.KeyName)) {
		errs = append(errs, ValidationError{Field: "key_name", Message: "gecersiz format"})
	}

	if !containsValue(allowedPublicAPIKeyEnvironments, strings.TrimSpace(r.Environment)) {
		errs = append(errs, ValidationError{Field: "environment", Message: "desteklenmeyen deger"})
	}

	if len(r.Scopes) == 0 {
		errs = append(errs, ValidationError{Field: "scopes", Message: "en az bir scope olmali"})
	}

	seenScopes := map[string]struct{}{}
	for _, scope := range r.Scopes {
		scope = strings.TrimSpace(scope)
		if !containsValue(allowedPublicAPIKeyScopes, scope) {
			errs = append(errs, ValidationError{Field: "scopes", Message: "desteklenmeyen scope: " + scope})
			continue
		}

		if _, ok := seenScopes[scope]; ok {
			errs = append(errs, ValidationError{Field: "scopes", Message: "tekrar eden scope: " + scope})
		}
		seenScopes[scope] = struct{}{}
	}

	if r.ExpiresAt != nil && r.ExpiresAt.Before(time.Now().UTC().Add(-24*time.Hour)) {
		errs = append(errs, ValidationError{Field: "expires_at", Message: "gecmis tarih olamaz"})
	}

	if !publicAPIActorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{Field: "requested_by", Message: "gecersiz format"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r IssuePublicAPIKeyResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.APIKeyID)) {
		errs = append(errs, ValidationError{Field: "api_key_id", Message: "gecersiz format"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.AppID)) {
		errs = append(errs, ValidationError{Field: "app_id", Message: "gecersiz format"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.KeyName)) {
		errs = append(errs, ValidationError{Field: "key_name", Message: "gecersiz format"})
	}

	if !containsValue(allowedPublicAPIKeyEnvironments, strings.TrimSpace(r.Environment)) {
		errs = append(errs, ValidationError{Field: "environment", Message: "desteklenmeyen deger"})
	}

	if len(r.Scopes) == 0 {
		errs = append(errs, ValidationError{Field: "scopes", Message: "en az bir scope olmali"})
	}

	for _, scope := range r.Scopes {
		if !containsValue(allowedPublicAPIKeyScopes, strings.TrimSpace(scope)) {
			errs = append(errs, ValidationError{Field: "scopes", Message: "desteklenmeyen scope"})
		}
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.KeyPrefix)) {
		errs = append(errs, ValidationError{Field: "key_prefix", Message: "gecersiz format"})
	}

	if strings.TrimSpace(r.KeyPreview) == "" {
		errs = append(errs, ValidationError{Field: "key_preview", Message: "zorunlu alan"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.KeyFingerprint)) {
		errs = append(errs, ValidationError{Field: "key_fingerprint", Message: "gecersiz format"})
	}

	if !containsValue(allowedPublicAPIKeyStatuses, strings.TrimSpace(r.Status)) {
		errs = append(errs, ValidationError{Field: "status", Message: "desteklenmeyen deger"})
	}

	if !r.Issued {
		errs = append(errs, ValidationError{Field: "issued", Message: "true olmali"})
	}

	if r.IssuedAt.IsZero() {
		errs = append(errs, ValidationError{Field: "issued_at", Message: "zorunlu alan"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
