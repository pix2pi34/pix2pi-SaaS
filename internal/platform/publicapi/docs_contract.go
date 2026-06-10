package publicapi

import (
	"strings"
	"time"
)

var allowedPublicAPIDocsFormats = map[string]struct{}{
	"openapi":  {},
	"markdown": {},
	"portal":   {},
}

var allowedPublicAPIDocsPublishStatuses = map[string]struct{}{
	"published": {},
	"blocked":   {},
}

type PublishDeveloperDocsRequest struct {
	TenantID    string `json:"tenant_id,omitempty"`
	AppID       string `json:"app_id"`
	DocsVersion string `json:"docs_version"`
	Environment string `json:"environment"`
	DocsFormat  string `json:"docs_format"`
	SourceRef   string `json:"source_ref"`
	TargetPath  string `json:"target_path"`
	RequestedBy string `json:"requested_by"`
}

type PublishDeveloperDocsResponse struct {
	DocsID        string    `json:"docs_id"`
	AppID         string    `json:"app_id"`
	DocsVersion   string    `json:"docs_version"`
	Environment   string    `json:"environment"`
	DocsFormat    string    `json:"docs_format"`
	SourceRef     string    `json:"source_ref"`
	TargetPath    string    `json:"target_path"`
	PublicURL     string    `json:"public_url,omitempty"`
	PublishStatus string    `json:"publish_status"`
	Published     bool      `json:"published"`
	DenialReason  string    `json:"denial_reason,omitempty"`
	PublishedAt   time.Time `json:"published_at"`
}

func (r PublishDeveloperDocsRequest) Validate() error {
	errs := make(ValidationErrors, 0)

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.AppID)) {
		errs = append(errs, ValidationError{Field: "app_id", Message: "gecersiz format"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.DocsVersion)) {
		errs = append(errs, ValidationError{Field: "docs_version", Message: "gecersiz format"})
	}

	if !containsValue(allowedPublicAPIKeyEnvironments, strings.TrimSpace(r.Environment)) {
		errs = append(errs, ValidationError{Field: "environment", Message: "desteklenmeyen deger"})
	}

	if !containsValue(allowedPublicAPIDocsFormats, strings.TrimSpace(r.DocsFormat)) {
		errs = append(errs, ValidationError{Field: "docs_format", Message: "desteklenmeyen deger"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.SourceRef)) {
		errs = append(errs, ValidationError{Field: "source_ref", Message: "gecersiz format"})
	}

	if !publicAPIPathPattern.MatchString(normalizePublicAPIPath(r.TargetPath)) {
		errs = append(errs, ValidationError{Field: "target_path", Message: "gecersiz format"})
	}

	if !publicAPIActorRefPattern.MatchString(strings.TrimSpace(r.RequestedBy)) {
		errs = append(errs, ValidationError{Field: "requested_by", Message: "gecersiz format"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}

func (r PublishDeveloperDocsResponse) Validate() error {
	errs := make(ValidationErrors, 0)

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.DocsID)) {
		errs = append(errs, ValidationError{Field: "docs_id", Message: "gecersiz format"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.AppID)) {
		errs = append(errs, ValidationError{Field: "app_id", Message: "gecersiz format"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.DocsVersion)) {
		errs = append(errs, ValidationError{Field: "docs_version", Message: "gecersiz format"})
	}

	if !containsValue(allowedPublicAPIKeyEnvironments, strings.TrimSpace(r.Environment)) {
		errs = append(errs, ValidationError{Field: "environment", Message: "desteklenmeyen deger"})
	}

	if !containsValue(allowedPublicAPIDocsFormats, strings.TrimSpace(r.DocsFormat)) {
		errs = append(errs, ValidationError{Field: "docs_format", Message: "desteklenmeyen deger"})
	}

	if !publicAPIKeyPattern.MatchString(strings.TrimSpace(r.SourceRef)) {
		errs = append(errs, ValidationError{Field: "source_ref", Message: "gecersiz format"})
	}

	if !publicAPIPathPattern.MatchString(normalizePublicAPIPath(r.TargetPath)) {
		errs = append(errs, ValidationError{Field: "target_path", Message: "gecersiz format"})
	}

	if strings.TrimSpace(r.PublicURL) != "" &&
		!(strings.HasPrefix(strings.TrimSpace(r.PublicURL), "https://") || strings.HasPrefix(strings.TrimSpace(r.PublicURL), "http://")) {
		errs = append(errs, ValidationError{Field: "public_url", Message: "http veya https URL olmali"})
	}

	if !containsValue(allowedPublicAPIDocsPublishStatuses, strings.TrimSpace(r.PublishStatus)) {
		errs = append(errs, ValidationError{Field: "publish_status", Message: "desteklenmeyen deger"})
	}

	if r.Published && strings.TrimSpace(r.PublishStatus) != "published" {
		errs = append(errs, ValidationError{Field: "publish_status", Message: "published true ise published olmali"})
	}

	if r.Published && strings.TrimSpace(r.PublicURL) == "" {
		errs = append(errs, ValidationError{Field: "public_url", Message: "published durumda zorunlu alan"})
	}

	if !r.Published && strings.TrimSpace(r.DenialReason) == "" {
		errs = append(errs, ValidationError{Field: "denial_reason", Message: "blocked durumda zorunlu alan"})
	}

	if r.PublishedAt.IsZero() {
		errs = append(errs, ValidationError{Field: "published_at", Message: "zorunlu alan"})
	}

	if len(errs) > 0 {
		return errs
	}

	return nil
}
