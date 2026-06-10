package publicapiruntime

import (
	"encoding/json"
	"errors"
	"sort"
	"strings"
	"sync"
	"time"
)

const (
	DeveloperDocsDecisionAllow = "ALLOW"
	DeveloperDocsDecisionDeny  = "DENY"

	DeveloperDocsReasonAllowed             = "DEVELOPER_DOCS_ALLOWED"
	DeveloperDocsReasonMissingTitle        = "DEVELOPER_DOCS_MISSING_TITLE"
	DeveloperDocsReasonMissingVersion      = "DEVELOPER_DOCS_MISSING_VERSION"
	DeveloperDocsReasonMissingMethod       = "DEVELOPER_DOCS_MISSING_METHOD"
	DeveloperDocsReasonMissingPath         = "DEVELOPER_DOCS_MISSING_PATH"
	DeveloperDocsReasonMissingDescription  = "DEVELOPER_DOCS_MISSING_DESCRIPTION"
	DeveloperDocsReasonMissingScope        = "DEVELOPER_DOCS_MISSING_SCOPE"
	DeveloperDocsReasonDuplicateEndpoint   = "DEVELOPER_DOCS_DUPLICATE_ENDPOINT"
	DeveloperDocsReasonMissingSandboxDocs  = "DEVELOPER_DOCS_MISSING_SANDBOX_DOCS"
	DeveloperDocsReasonMissingAPIKeyDocs   = "DEVELOPER_DOCS_MISSING_API_KEY_DOCS"
	DeveloperDocsReasonMissingQuotaDocs    = "DEVELOPER_DOCS_MISSING_QUOTA_DOCS"
	DeveloperDocsReasonMissingAppAuthDocs  = "DEVELOPER_DOCS_MISSING_APP_AUTH_DOCS"
	DeveloperDocsReasonMissingEndpointDocs = "DEVELOPER_DOCS_MISSING_ENDPOINT_DOCS"

	DeveloperDocsPublishFormatMarkdown = "MARKDOWN"
	DeveloperDocsPublishFormatOpenAPI  = "OPENAPI_TRACE"
)

var (
	ErrDeveloperDocsMissingTitle        = errors.New("missing developer docs title")
	ErrDeveloperDocsMissingVersion      = errors.New("missing developer docs version")
	ErrDeveloperDocsMissingMethod       = errors.New("missing developer docs endpoint method")
	ErrDeveloperDocsMissingPath         = errors.New("missing developer docs endpoint path")
	ErrDeveloperDocsMissingDescription  = errors.New("missing developer docs endpoint description")
	ErrDeveloperDocsMissingScope        = errors.New("missing developer docs endpoint scope")
	ErrDeveloperDocsDuplicateEndpoint   = errors.New("duplicate developer docs endpoint")
	ErrDeveloperDocsMissingSandboxDocs  = errors.New("missing sandbox developer docs")
	ErrDeveloperDocsMissingAPIKeyDocs   = errors.New("missing api key developer docs")
	ErrDeveloperDocsMissingQuotaDocs    = errors.New("missing quota developer docs")
	ErrDeveloperDocsMissingAppAuthDocs  = errors.New("missing app auth developer docs")
	ErrDeveloperDocsMissingEndpointDocs = errors.New("missing endpoint developer docs")
)

type DeveloperDocsPublishRuntimeConfig struct {
	Title               string `json:"title"`
	Version             string `json:"version"`
	BaseURL             string `json:"base_url"`
	RequireSandboxDocs  bool   `json:"require_sandbox_docs"`
	RequireAPIKeyDocs   bool   `json:"require_api_key_docs"`
	RequireQuotaDocs    bool   `json:"require_quota_docs"`
	RequireAppAuthDocs  bool   `json:"require_app_auth_docs"`
	RequireEndpointDocs bool   `json:"require_endpoint_docs"`
}

func DefaultDeveloperDocsPublishRuntimeConfig() DeveloperDocsPublishRuntimeConfig {
	return DeveloperDocsPublishRuntimeConfig{
		Title:               "Pix2pi Public API",
		Version:             "v1",
		BaseURL:             "https://api.pix2pi.com.tr",
		RequireSandboxDocs:  true,
		RequireAPIKeyDocs:   true,
		RequireQuotaDocs:    true,
		RequireAppAuthDocs:  true,
		RequireEndpointDocs: true,
	}
}

type DeveloperEndpointDoc struct {
	Method          string   `json:"method"`
	Path            string   `json:"path"`
	Summary         string   `json:"summary"`
	Description     string   `json:"description"`
	RequiredScopes  []string `json:"required_scopes"`
	Environment     string   `json:"environment"`
	RequestExample  string   `json:"request_example,omitempty"`
	ResponseExample string   `json:"response_example,omitempty"`
}

type DeveloperDocsSection struct {
	Title   string `json:"title"`
	Content string `json:"content"`
}

type DeveloperDocsRegistrySnapshot struct {
	Title       string                 `json:"title"`
	Version     string                 `json:"version"`
	BaseURL     string                 `json:"base_url"`
	Endpoints   []DeveloperEndpointDoc `json:"endpoints"`
	Sections    []DeveloperDocsSection `json:"sections"`
	GeneratedAt string                 `json:"generated_at"`
}

type DeveloperDocsPublishResult struct {
	Format        string `json:"format"`
	Content       string `json:"content"`
	EndpointCount int    `json:"endpoint_count"`
	SectionCount  int    `json:"section_count"`
	GeneratedAt   string `json:"generated_at"`
}

type DeveloperDocsDecision struct {
	Decision  string `json:"decision"`
	Allowed   bool   `json:"allowed"`
	Reason    string `json:"reason"`
	CheckedAt string `json:"checked_at"`
}

type DeveloperDocsPublishRuntime struct {
	config    DeveloperDocsPublishRuntimeConfig
	mu        sync.RWMutex
	endpoints map[string]DeveloperEndpointDoc
	sections  map[string]DeveloperDocsSection
}

func NewDeveloperDocsPublishRuntime(config DeveloperDocsPublishRuntimeConfig) *DeveloperDocsPublishRuntime {
	if strings.TrimSpace(config.Title) == "" {
		config.Title = DefaultDeveloperDocsPublishRuntimeConfig().Title
	}
	if strings.TrimSpace(config.Version) == "" {
		config.Version = DefaultDeveloperDocsPublishRuntimeConfig().Version
	}
	if strings.TrimSpace(config.BaseURL) == "" {
		config.BaseURL = DefaultDeveloperDocsPublishRuntimeConfig().BaseURL
	}

	return &DeveloperDocsPublishRuntime{
		config:    config,
		endpoints: make(map[string]DeveloperEndpointDoc),
		sections:  make(map[string]DeveloperDocsSection),
	}
}

func (r *DeveloperDocsPublishRuntime) RegisterEndpoint(doc DeveloperEndpointDoc) (DeveloperDocsDecision, error) {
	decision := newDeveloperDocsDecision()

	doc.Method = strings.ToUpper(strings.TrimSpace(doc.Method))
	doc.Path = strings.TrimSpace(doc.Path)
	doc.Summary = strings.TrimSpace(doc.Summary)
	doc.Description = strings.TrimSpace(doc.Description)
	doc.Environment = normalizeEnvironment(doc.Environment)

	if doc.Method == "" {
		decision.Reason = DeveloperDocsReasonMissingMethod
		return decision, ErrDeveloperDocsMissingMethod
	}
	if doc.Path == "" {
		decision.Reason = DeveloperDocsReasonMissingPath
		return decision, ErrDeveloperDocsMissingPath
	}
	if doc.Description == "" {
		decision.Reason = DeveloperDocsReasonMissingDescription
		return decision, ErrDeveloperDocsMissingDescription
	}
	if len(doc.RequiredScopes) == 0 {
		decision.Reason = DeveloperDocsReasonMissingScope
		return decision, ErrDeveloperDocsMissingScope
	}

	scopes, err := normalizeDeveloperDocScopes(doc.RequiredScopes)
	if err != nil {
		decision.Reason = DeveloperDocsReasonMissingScope
		return decision, err
	}
	doc.RequiredScopes = scopes

	key := DeveloperEndpointKey(doc.Method, doc.Path)

	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.endpoints[key]; exists {
		decision.Reason = DeveloperDocsReasonDuplicateEndpoint
		return decision, ErrDeveloperDocsDuplicateEndpoint
	}

	r.endpoints[key] = doc

	decision.Decision = DeveloperDocsDecisionAllow
	decision.Allowed = true
	decision.Reason = DeveloperDocsReasonAllowed
	return decision, nil
}

func (r *DeveloperDocsPublishRuntime) UpsertSection(section DeveloperDocsSection) (DeveloperDocsDecision, error) {
	decision := newDeveloperDocsDecision()

	section.Title = strings.TrimSpace(section.Title)
	section.Content = strings.TrimSpace(section.Content)

	if section.Title == "" {
		decision.Reason = DeveloperDocsReasonMissingTitle
		return decision, ErrDeveloperDocsMissingTitle
	}
	if section.Content == "" {
		decision.Reason = DeveloperDocsReasonMissingDescription
		return decision, ErrDeveloperDocsMissingDescription
	}

	r.mu.Lock()
	r.sections[strings.ToLower(section.Title)] = section
	r.mu.Unlock()

	decision.Decision = DeveloperDocsDecisionAllow
	decision.Allowed = true
	decision.Reason = DeveloperDocsReasonAllowed
	return decision, nil
}

func (r *DeveloperDocsPublishRuntime) SeedRequiredPublicAPISections() {
	_, _ = r.UpsertSection(DeveloperDocsSection{
		Title:   "Sandbox",
		Content: "Sandbox ortamında production veri erişimi kapalıdır. Sandbox namespace formatı sandbox:{tenant_id}:{app_id}.",
	})
	_, _ = r.UpsertSection(DeveloperDocsSection{
		Title:   "API Key",
		Content: "API key secret yalnızca üretildiği anda gösterilir. Kalıcı saklama alanında sadece sha256 hash tutulur.",
	})
	_, _ = r.UpsertSection(DeveloperDocsSection{
		Title:   "Quota",
		Content: "Quota tenant_id + app_id + key_id + environment + scope + window boyutlarında uygulanır.",
	})
	_, _ = r.UpsertSection(DeveloperDocsSection{
		Title:   "App Auth",
		Content: "App auth doğrulaması tenant, app, key, environment ve effective scope uyumunu kontrol eder.",
	})
}

func (r *DeveloperDocsPublishRuntime) ValidateReadyToPublish() (DeveloperDocsDecision, error) {
	decision := newDeveloperDocsDecision()

	if strings.TrimSpace(r.config.Title) == "" {
		decision.Reason = DeveloperDocsReasonMissingTitle
		return decision, ErrDeveloperDocsMissingTitle
	}
	if strings.TrimSpace(r.config.Version) == "" {
		decision.Reason = DeveloperDocsReasonMissingVersion
		return decision, ErrDeveloperDocsMissingVersion
	}

	r.mu.RLock()
	defer r.mu.RUnlock()

	if r.config.RequireEndpointDocs && len(r.endpoints) == 0 {
		decision.Reason = DeveloperDocsReasonMissingEndpointDocs
		return decision, ErrDeveloperDocsMissingEndpointDocs
	}
	if r.config.RequireSandboxDocs && !sectionExistsLocked(r.sections, "Sandbox") {
		decision.Reason = DeveloperDocsReasonMissingSandboxDocs
		return decision, ErrDeveloperDocsMissingSandboxDocs
	}
	if r.config.RequireAPIKeyDocs && !sectionExistsLocked(r.sections, "API Key") {
		decision.Reason = DeveloperDocsReasonMissingAPIKeyDocs
		return decision, ErrDeveloperDocsMissingAPIKeyDocs
	}
	if r.config.RequireQuotaDocs && !sectionExistsLocked(r.sections, "Quota") {
		decision.Reason = DeveloperDocsReasonMissingQuotaDocs
		return decision, ErrDeveloperDocsMissingQuotaDocs
	}
	if r.config.RequireAppAuthDocs && !sectionExistsLocked(r.sections, "App Auth") {
		decision.Reason = DeveloperDocsReasonMissingAppAuthDocs
		return decision, ErrDeveloperDocsMissingAppAuthDocs
	}

	decision.Decision = DeveloperDocsDecisionAllow
	decision.Allowed = true
	decision.Reason = DeveloperDocsReasonAllowed
	return decision, nil
}

func (r *DeveloperDocsPublishRuntime) Snapshot() DeveloperDocsRegistrySnapshot {
	r.mu.RLock()
	defer r.mu.RUnlock()

	endpoints := make([]DeveloperEndpointDoc, 0, len(r.endpoints))
	for _, endpoint := range r.endpoints {
		endpoints = append(endpoints, endpoint)
	}
	sort.Slice(endpoints, func(i int, j int) bool {
		if endpoints[i].Path == endpoints[j].Path {
			return endpoints[i].Method < endpoints[j].Method
		}
		return endpoints[i].Path < endpoints[j].Path
	})

	sections := make([]DeveloperDocsSection, 0, len(r.sections))
	for _, section := range r.sections {
		sections = append(sections, section)
	}
	sort.Slice(sections, func(i int, j int) bool {
		return sections[i].Title < sections[j].Title
	})

	return DeveloperDocsRegistrySnapshot{
		Title:       r.config.Title,
		Version:     r.config.Version,
		BaseURL:     r.config.BaseURL,
		Endpoints:   endpoints,
		Sections:    sections,
		GeneratedAt: time.Now().UTC().Format(time.RFC3339Nano),
	}
}

func (r *DeveloperDocsPublishRuntime) PublishMarkdown() (DeveloperDocsPublishResult, DeveloperDocsDecision, error) {
	decision, err := r.ValidateReadyToPublish()
	if err != nil {
		return DeveloperDocsPublishResult{}, decision, err
	}

	snapshot := r.Snapshot()

	var b strings.Builder
	b.WriteString("# " + snapshot.Title + "\n\n")
	b.WriteString("Version: `" + snapshot.Version + "`\n\n")
	b.WriteString("Base URL: `" + snapshot.BaseURL + "`\n\n")

	b.WriteString("## Sections\n\n")
	for _, section := range snapshot.Sections {
		b.WriteString("### " + section.Title + "\n\n")
		b.WriteString(section.Content + "\n\n")
	}

	b.WriteString("## Endpoints\n\n")
	for _, endpoint := range snapshot.Endpoints {
		b.WriteString("### `" + endpoint.Method + " " + endpoint.Path + "`\n\n")
		if endpoint.Summary != "" {
			b.WriteString(endpoint.Summary + "\n\n")
		}
		b.WriteString(endpoint.Description + "\n\n")
		b.WriteString("- Environment: `" + endpoint.Environment + "`\n")
		b.WriteString("- Required scopes: `" + strings.Join(endpoint.RequiredScopes, ", ") + "`\n\n")
		if endpoint.RequestExample != "" {
			b.WriteString("#### Request\n\n```json\n" + endpoint.RequestExample + "\n```\n\n")
		}
		if endpoint.ResponseExample != "" {
			b.WriteString("#### Response\n\n```json\n" + endpoint.ResponseExample + "\n```\n\n")
		}
	}

	result := DeveloperDocsPublishResult{
		Format:        DeveloperDocsPublishFormatMarkdown,
		Content:       b.String(),
		EndpointCount: len(snapshot.Endpoints),
		SectionCount:  len(snapshot.Sections),
		GeneratedAt:   snapshot.GeneratedAt,
	}

	return result, decision, nil
}

func (r *DeveloperDocsPublishRuntime) PublishOpenAPITrace() (DeveloperDocsPublishResult, DeveloperDocsDecision, error) {
	decision, err := r.ValidateReadyToPublish()
	if err != nil {
		return DeveloperDocsPublishResult{}, decision, err
	}

	snapshot := r.Snapshot()

	trace := map[string]interface{}{
		"openapi_trace":  "3.1.0-draft-ready",
		"title":          snapshot.Title,
		"version":        snapshot.Version,
		"base_url":       snapshot.BaseURL,
		"endpoint_count": len(snapshot.Endpoints),
		"section_count":  len(snapshot.Sections),
		"endpoints":      snapshot.Endpoints,
		"sections":       snapshot.Sections,
		"generated_at":   snapshot.GeneratedAt,
	}

	raw, err := json.MarshalIndent(trace, "", "  ")
	if err != nil {
		return DeveloperDocsPublishResult{}, decision, err
	}

	result := DeveloperDocsPublishResult{
		Format:        DeveloperDocsPublishFormatOpenAPI,
		Content:       string(raw),
		EndpointCount: len(snapshot.Endpoints),
		SectionCount:  len(snapshot.Sections),
		GeneratedAt:   snapshot.GeneratedAt,
	}

	return result, decision, nil
}

func DeveloperEndpointKey(method string, path string) string {
	return strings.ToUpper(strings.TrimSpace(method)) + " " + strings.TrimSpace(path)
}

func newDeveloperDocsDecision() DeveloperDocsDecision {
	return DeveloperDocsDecision{
		Decision:  DeveloperDocsDecisionDeny,
		Allowed:   false,
		Reason:    DeveloperDocsReasonAllowed,
		CheckedAt: time.Now().UTC().Format(time.RFC3339Nano),
	}
}

func normalizeDeveloperDocScopes(scopes []string) ([]string, error) {
	if len(scopes) == 0 {
		return nil, ErrDeveloperDocsMissingScope
	}

	seen := map[string]struct{}{}
	out := make([]string, 0, len(scopes))

	for _, scope := range scopes {
		scope = strings.TrimSpace(scope)
		if scope == "" {
			continue
		}
		if _, ok := seen[scope]; ok {
			continue
		}
		seen[scope] = struct{}{}
		out = append(out, scope)
	}

	if len(out) == 0 {
		return nil, ErrDeveloperDocsMissingScope
	}

	return out, nil
}

func sectionExistsLocked(sections map[string]DeveloperDocsSection, title string) bool {
	_, ok := sections[strings.ToLower(strings.TrimSpace(title))]
	return ok
}
