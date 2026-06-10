package publicapi

import (
	"strings"
	"time"
)

var allowedPublicAPISandboxStatuses = map[string]struct{}{
	"ready":       {},
	"provisioning": {},
	"blocked":     {},
}

var allowedPublicAPISandboxDataModes = map[string]struct{}{
	"empty":       {},
	"sample_data": {},
	"mirror_schema": {},
}

type EnsurePublicAPISandboxRequest struct {
	TenantID     string `json:"tenant_id,omitempty"`
	AppID        string `json:"app_id"`
	Environment  string `json:"environment"`
	SandboxName  string `json:"sandbox_name"`
	DataMode     string `json:"data_mode"`
	RequestedBy  string `json:"requested_by"`
}

type EnsurePublicAPISandboxResponse struct {
	SandboxID      string    `json:"sandbox_id"`
	AppID          string    `json:"app_id"`
	Environment    string    `json:"environment"`
	SandboxName    string    `json:"sandbox_name"`
	DataMode       string    `json:"data_mode"`
	BaseURL        string    `json:"base_url"`
	Isolated       bool      `json:"isolated"`
	SandboxStatus  string    `json:"sandbox_status"`
	Ready          bool      `json:"ready"`
	DenialReason   string    `json:"denial_reason,omitempty"`
	ProvisionedAt  time.Time `json:"provisioned_at"`
}

func (r EnsurePublicAPISandboxRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.AppID)) {
		errs = append(errs, ValidationError{Field: "app_id", Message: "gecersiz format"})
	}

	if strings.TrimSpace(r.Environment) != "sandbox" {
		errs = append(errs, ValidationError{Field: "environment", Message: "sandbox olmali"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.SandboxName)) {
		errs = append(errs, ValidationError{Field: "sandbox_name", Message: "gecersiz format"})
	}

	if !containsValue(allowedPublicAPISandboxDataModes, strings.TrimSpace(r.DataMode)) {
		errs = append(errs, ValidationError{Field: "data_mode", Message: "desteklenmeyen deger"})
	}

	if !publicAPIActorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{Field: "requested_by", Message: "gecersiz format"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r EnsurePublicAPISandboxResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.SandboxID)) {
		errs = append(errs, ValidationError{Field: "sandbox_id", Message: "gecersiz format"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.AppID)) {
		errs = append(errs, ValidationError{Field: "app_id", Message: "gecersiz format"})
	}

	if strings.TrimSpace(r.Environment) != "sandbox" {
		errs = append(errs, ValidationError{Field: "environment", Message: "sandbox olmali"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.SandboxName)) {
		errs = append(errs, ValidationError{Field: "sandbox_name", Message: "gecersiz format"})
	}

	if !containsValue(allowedPublicAPISandboxDataModes, strings.TrimSpace(r.DataMode)) {
		errs = append(errs, ValidationError{Field: "data_mode", Message: "desteklenmeyen deger"})
	}

	baseURL := strings.TrimSpace(r.BaseURL)
	if baseURL == "" || !(strings.HasPrefix(baseURL, "https://") || strings.HasPrefix(baseURL, "http://")) {
		errs = append(errs, ValidationError{Field: "base_url", Message: "http veya https URL olmali"})
	}

	if !containsValue(allowedPublicAPISandboxStatuses, strings.TrimSpace(r.SandboxStatus)) {
		errs = append(errs, ValidationError{Field: "sandbox_status", Message: "desteklenmeyen deger"})
	}

	if r.Ready && strings.TrimSpace(r.SandboxStatus) != "ready" {
		errs = append(errs, ValidationError{Field: "sandbox_status", Message: "ready true ise ready olmali"})
	}

	if r.Ready && !r.Isolated {
		errs = append(errs, ValidationError{Field: "isolated", Message: "ready sandbox izole olmali"})
	}

	if !r.Ready && strings.TrimSpace(r.DenialReason) == "" && strings.TrimSpace(r.SandboxStatus) == "blocked" {
		errs = append(errs, ValidationError{Field: "denial_reason", Message: "blocked durumda zorunlu alan"})
	}

	if r.ProvisionedAt.IsZero() {
		errs = append(errs, ValidationError{Field: "provisioned_at", Message: "zorunlu alan"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
