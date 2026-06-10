package publicapiruntime

import (
	"strings"
	"testing"
)

func newReadyDeveloperDocsRuntime(t *testing.T) *DeveloperDocsPublishRuntime {
	t.Helper()

	runtime := NewDeveloperDocsPublishRuntime(DefaultDeveloperDocsPublishRuntimeConfig())
	runtime.SeedRequiredPublicAPISections()

	decision, err := runtime.RegisterEndpoint(DeveloperEndpointDoc{
		Method:          "GET",
		Path:            "/v1/products",
		Summary:         "List products",
		Description:     "Lists sandbox products for the authenticated app.",
		RequiredScopes:  []string{"read"},
		Environment:     APIKeyEnvironmentSandbox,
		RequestExample:  `{"limit":10}`,
		ResponseExample: `{"items":[]}`,
	})
	if err != nil {
		t.Fatalf("register endpoint failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected endpoint register allowed, got reason=%s", decision.Reason)
	}

	return runtime
}

func TestDeveloperDocsPublishRuntimeRegistersEndpoint(t *testing.T) {
	runtime := NewDeveloperDocsPublishRuntime(DefaultDeveloperDocsPublishRuntimeConfig())

	decision, err := runtime.RegisterEndpoint(DeveloperEndpointDoc{
		Method:         "get",
		Path:           "/v1/products",
		Summary:        "List products",
		Description:    "Lists products.",
		RequiredScopes: []string{"read", "read"},
		Environment:    APIKeyEnvironmentSandbox,
	})
	if err != nil {
		t.Fatalf("register endpoint failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected allowed, got reason=%s", decision.Reason)
	}

	snapshot := runtime.Snapshot()
	if len(snapshot.Endpoints) != 1 {
		t.Fatalf("expected 1 endpoint, got %d", len(snapshot.Endpoints))
	}
	if snapshot.Endpoints[0].Method != "GET" {
		t.Fatalf("expected method GET, got %s", snapshot.Endpoints[0].Method)
	}
	if len(snapshot.Endpoints[0].RequiredScopes) != 1 {
		t.Fatalf("expected deduplicated scope count 1, got %d", len(snapshot.Endpoints[0].RequiredScopes))
	}
}

func TestDeveloperDocsPublishRuntimeRejectsDuplicateEndpoint(t *testing.T) {
	runtime := NewDeveloperDocsPublishRuntime(DefaultDeveloperDocsPublishRuntimeConfig())

	endpoint := DeveloperEndpointDoc{
		Method:         "GET",
		Path:           "/v1/products",
		Description:    "Lists products.",
		RequiredScopes: []string{"read"},
		Environment:    APIKeyEnvironmentSandbox,
	}

	if _, err := runtime.RegisterEndpoint(endpoint); err != nil {
		t.Fatalf("first register failed: %v", err)
	}

	decision, err := runtime.RegisterEndpoint(endpoint)
	if err != ErrDeveloperDocsDuplicateEndpoint {
		t.Fatalf("expected duplicate endpoint error, got %v", err)
	}
	if decision.Reason != DeveloperDocsReasonDuplicateEndpoint {
		t.Fatalf("expected duplicate endpoint reason, got %s", decision.Reason)
	}
}

func TestDeveloperDocsPublishRuntimeRejectsMissingEndpointFields(t *testing.T) {
	runtime := NewDeveloperDocsPublishRuntime(DefaultDeveloperDocsPublishRuntimeConfig())

	_, err := runtime.RegisterEndpoint(DeveloperEndpointDoc{
		Path:           "/v1/products",
		Description:    "Lists products.",
		RequiredScopes: []string{"read"},
	})
	if err != ErrDeveloperDocsMissingMethod {
		t.Fatalf("expected missing method error, got %v", err)
	}

	_, err = runtime.RegisterEndpoint(DeveloperEndpointDoc{
		Method:         "GET",
		Description:    "Lists products.",
		RequiredScopes: []string{"read"},
	})
	if err != ErrDeveloperDocsMissingPath {
		t.Fatalf("expected missing path error, got %v", err)
	}

	_, err = runtime.RegisterEndpoint(DeveloperEndpointDoc{
		Method:         "GET",
		Path:           "/v1/products",
		RequiredScopes: []string{"read"},
	})
	if err != ErrDeveloperDocsMissingDescription {
		t.Fatalf("expected missing description error, got %v", err)
	}

	_, err = runtime.RegisterEndpoint(DeveloperEndpointDoc{
		Method:      "GET",
		Path:        "/v1/products",
		Description: "Lists products.",
	})
	if err != ErrDeveloperDocsMissingScope {
		t.Fatalf("expected missing scope error, got %v", err)
	}
}

func TestDeveloperDocsPublishRuntimeValidatesRequiredSections(t *testing.T) {
	runtime := NewDeveloperDocsPublishRuntime(DefaultDeveloperDocsPublishRuntimeConfig())

	_, err := runtime.RegisterEndpoint(DeveloperEndpointDoc{
		Method:         "GET",
		Path:           "/v1/products",
		Description:    "Lists products.",
		RequiredScopes: []string{"read"},
		Environment:    APIKeyEnvironmentSandbox,
	})
	if err != nil {
		t.Fatalf("register endpoint failed: %v", err)
	}

	decision, err := runtime.ValidateReadyToPublish()
	if err != ErrDeveloperDocsMissingSandboxDocs {
		t.Fatalf("expected missing sandbox docs, got %v", err)
	}
	if decision.Reason != DeveloperDocsReasonMissingSandboxDocs {
		t.Fatalf("expected missing sandbox reason, got %s", decision.Reason)
	}

	runtime.SeedRequiredPublicAPISections()

	decision, err = runtime.ValidateReadyToPublish()
	if err != nil {
		t.Fatalf("validate ready failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected validation allowed, got reason=%s", decision.Reason)
	}
}

func TestDeveloperDocsPublishRuntimePublishesMarkdown(t *testing.T) {
	runtime := newReadyDeveloperDocsRuntime(t)

	result, decision, err := runtime.PublishMarkdown()
	if err != nil {
		t.Fatalf("publish markdown failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected publish allowed, got reason=%s", decision.Reason)
	}
	if result.Format != DeveloperDocsPublishFormatMarkdown {
		t.Fatalf("expected markdown format, got %s", result.Format)
	}
	if result.EndpointCount != 1 {
		t.Fatalf("expected endpoint count 1, got %d", result.EndpointCount)
	}
	if result.SectionCount != 4 {
		t.Fatalf("expected section count 4, got %d", result.SectionCount)
	}
	required := []string{
		"# Pix2pi Public API",
		"### Sandbox",
		"### API Key",
		"### Quota",
		"### App Auth",
		"`GET /v1/products`",
		"Required scopes",
	}
	for _, text := range required {
		if !strings.Contains(result.Content, text) {
			t.Fatalf("markdown output missing %q", text)
		}
	}
}

func TestDeveloperDocsPublishRuntimePublishesOpenAPITrace(t *testing.T) {
	runtime := newReadyDeveloperDocsRuntime(t)

	result, decision, err := runtime.PublishOpenAPITrace()
	if err != nil {
		t.Fatalf("publish openapi trace failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected publish allowed, got reason=%s", decision.Reason)
	}
	if result.Format != DeveloperDocsPublishFormatOpenAPI {
		t.Fatalf("expected openapi trace format, got %s", result.Format)
	}
	if !strings.Contains(result.Content, `"openapi_trace": "3.1.0-draft-ready"`) {
		t.Fatalf("openapi trace missing draft marker")
	}
	if !strings.Contains(result.Content, `"/v1/products"`) {
		t.Fatalf("openapi trace missing endpoint path")
	}
	if !strings.Contains(result.Content, `"Sandbox"`) {
		t.Fatalf("openapi trace missing sandbox section")
	}
}

func TestDeveloperDocsPublishRuntimeRequiresEndpointDocs(t *testing.T) {
	runtime := NewDeveloperDocsPublishRuntime(DefaultDeveloperDocsPublishRuntimeConfig())
	runtime.SeedRequiredPublicAPISections()

	decision, err := runtime.ValidateReadyToPublish()
	if err != ErrDeveloperDocsMissingEndpointDocs {
		t.Fatalf("expected missing endpoint docs, got %v", err)
	}
	if decision.Reason != DeveloperDocsReasonMissingEndpointDocs {
		t.Fatalf("expected missing endpoint docs reason, got %s", decision.Reason)
	}
}

func TestDeveloperEndpointKeyNormalizesMethod(t *testing.T) {
	key := DeveloperEndpointKey("get", "/v1/products")
	if key != "GET /v1/products" {
		t.Fatalf("unexpected endpoint key %s", key)
	}
}
