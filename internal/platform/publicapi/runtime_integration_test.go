package publicapi

import (
	"context"
	"fmt"
	"strings"
	"sync"
	"testing"
	"time"
)

type publicAPIRuntimeKeyRecord struct {
	TenantID       string
	AppID          string
	APIKeyID       string
	Environment    string
	Scopes         []string
	KeyPrefix      string
	KeyPreview     string
	KeyFingerprint string
	Status         string
	ExpiresAt      *time.Time
	CreatedAt      time.Time
}

type publicAPIRuntimeSandboxRecord struct {
	TenantID      string
	SandboxID     string
	AppID         string
	Environment   string
	SandboxName   string
	DataMode      string
	BaseURL       string
	Isolated      bool
	SandboxStatus string
	Ready         bool
}

type publicAPIRuntimeDocsRecord struct {
	TenantID      string
	DocsID        string
	AppID         string
	DocsVersion   string
	Environment   string
	DocsFormat    string
	SourceRef     string
	TargetPath    string
	PublicURL     string
	PublishStatus string
	Published     bool
	DenialReason  string
}

type publicAPIRuntimeIntegrationStore struct {
	mu       sync.Mutex
	nowFn    func() time.Time
	keySeq   int
	docsSeq  int
	keys     map[string]*publicAPIRuntimeKeyRecord
	usage    map[string]int
	sandboxes map[string]*publicAPIRuntimeSandboxRecord
	docs     map[string]*publicAPIRuntimeDocsRecord
}

func newPublicAPIRuntimeIntegrationStore() *publicAPIRuntimeIntegrationStore {
	return &publicAPIRuntimeIntegrationStore{
		nowFn: func() time.Time {
			return time.Now().UTC()
		},
		keys:      make(map[string]*publicAPIRuntimeKeyRecord),
		usage:     make(map[string]int),
		sandboxes: make(map[string]*publicAPIRuntimeSandboxRecord),
		docs:      make(map[string]*publicAPIRuntimeDocsRecord),
	}
}

func publicAPIRuntimeKey(tenantID, appID, apiKeyID string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(appID) + "::" + strings.TrimSpace(apiKeyID)
}

func publicAPIRuntimeUsageKey(tenantID, appID, apiKeyID, environment, quotaWindow string) string {
	return strings.Join([]string{
		strings.TrimSpace(tenantID),
		strings.TrimSpace(appID),
		strings.TrimSpace(apiKeyID),
		strings.TrimSpace(environment),
		strings.TrimSpace(quotaWindow),
	}, "::")
}

func publicAPIRuntimeSandboxKey(tenantID, appID, sandboxName string) string {
	return strings.TrimSpace(tenantID) + "::" + strings.TrimSpace(appID) + "::" + strings.TrimSpace(sandboxName)
}

func publicAPIRuntimeDocsKey(tenantID, appID, docsVersion, environment, docsFormat string) string {
	return strings.Join([]string{
		strings.TrimSpace(tenantID),
		strings.TrimSpace(appID),
		strings.TrimSpace(docsVersion),
		strings.TrimSpace(environment),
		strings.TrimSpace(docsFormat),
	}, "::")
}

func (s *publicAPIRuntimeIntegrationStore) ResolveRoute(_ context.Context, cmd ResolvePublicAPIGatewayCommand) (ResolvePublicAPIGatewayResult, error) {
	path := normalizePublicAPIPath(cmd.Path)
	method := strings.ToUpper(strings.TrimSpace(cmd.Method))

	if strings.HasPrefix(path, "/v1/erp") && (method == "GET" || method == "POST") {
		return ResolvePublicAPIGatewayResult{
			RequestID:     cmd.RequestID,
			AppID:         cmd.AppID,
			APIKeyID:      cmd.APIKeyID,
			Method:        method,
			Path:          path,
			TargetService: "erp-api",
			TargetPath:    path,
			GatewayStatus: "accepted",
			Accepted:      true,
		}, nil
	}

	if strings.HasPrefix(path, "/v1/developer") && (method == "GET" || method == "POST") {
		return ResolvePublicAPIGatewayResult{
			RequestID:     cmd.RequestID,
			AppID:         cmd.AppID,
			APIKeyID:      cmd.APIKeyID,
			Method:        method,
			Path:          path,
			TargetService: "developer-api",
			TargetPath:    path,
			GatewayStatus: "accepted",
			Accepted:      true,
		}, nil
	}

	return ResolvePublicAPIGatewayResult{
		RequestID:       cmd.RequestID,
		AppID:           cmd.AppID,
		APIKeyID:        cmd.APIKeyID,
		Method:          method,
		Path:            path,
		GatewayStatus:   "rejected",
		Accepted:        false,
		RejectionReason: "public api route not allowed",
	}, nil
}

func (s *publicAPIRuntimeIntegrationStore) IssueAPIKey(_ context.Context, cmd IssuePublicAPIKeyCommand) (IssuePublicAPIKeyResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.keySeq++
	apiKeyID := fmt.Sprintf("key-%03d", s.keySeq)

	rec := &publicAPIRuntimeKeyRecord{
		TenantID:       strings.TrimSpace(cmd.TenantID),
		AppID:          strings.TrimSpace(cmd.AppID),
		APIKeyID:       apiKeyID,
		Environment:    strings.TrimSpace(cmd.Environment),
		Scopes:         cloneStringSlice(cmd.Scopes),
		KeyPrefix:      strings.TrimSpace(cmd.KeyPrefix),
		KeyPreview:     strings.TrimSpace(cmd.KeyPreview),
		KeyFingerprint: strings.TrimSpace(cmd.KeyFingerprint),
		Status:         "active",
		ExpiresAt:      clonePublicAPITimePtr(cmd.ExpiresAt),
		CreatedAt:      s.nowFn().UTC(),
	}

	s.keys[publicAPIRuntimeKey(rec.TenantID, rec.AppID, rec.APIKeyID)] = rec

	return IssuePublicAPIKeyResult{
		APIKeyID:       rec.APIKeyID,
		AppID:          rec.AppID,
		KeyName:        strings.TrimSpace(cmd.KeyName),
		Environment:    rec.Environment,
		Scopes:         cloneStringSlice(rec.Scopes),
		KeyPrefix:      rec.KeyPrefix,
		KeyPreview:     rec.KeyPreview,
		KeyFingerprint: rec.KeyFingerprint,
		Status:         rec.Status,
		Issued:         true,
		ExpiresAt:      clonePublicAPITimePtr(rec.ExpiresAt),
	}, nil
}

func (s *publicAPIRuntimeIntegrationStore) AuthenticateApp(_ context.Context, cmd AuthenticatePublicAPIAppCommand) (AuthenticatePublicAPIAppResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	rec, ok := s.keys[publicAPIRuntimeKey(cmd.TenantID, cmd.AppID, cmd.APIKeyID)]
	if !ok {
		return AuthenticatePublicAPIAppResult{
			RequestID:     cmd.RequestID,
			AppID:         cmd.AppID,
			APIKeyID:      cmd.APIKeyID,
			Environment:   cmd.Environment,
			GrantedScopes: cloneStringSlice(cmd.RequiredScopes),
			AuthStatus:    "denied",
			Authenticated: false,
			DenialReason:  "api key bulunamadi",
		}, nil
	}

	if rec.KeyFingerprint != strings.TrimSpace(cmd.KeyFingerprint) {
		return AuthenticatePublicAPIAppResult{
			RequestID:     cmd.RequestID,
			AppID:         cmd.AppID,
			APIKeyID:      cmd.APIKeyID,
			Environment:   cmd.Environment,
			GrantedScopes: cloneStringSlice(rec.Scopes),
			AuthStatus:    "denied",
			Authenticated: false,
			DenialReason:  "api key fingerprint eslesmedi",
		}, nil
	}

	if rec.Environment != strings.TrimSpace(cmd.Environment) {
		return AuthenticatePublicAPIAppResult{
			RequestID:     cmd.RequestID,
			AppID:         cmd.AppID,
			APIKeyID:      cmd.APIKeyID,
			Environment:   cmd.Environment,
			GrantedScopes: cloneStringSlice(rec.Scopes),
			AuthStatus:    "denied",
			Authenticated: false,
			DenialReason:  "environment eslesmedi",
		}, nil
	}

	for _, requiredScope := range cmd.RequiredScopes {
		if !publicAPIRuntimeHasScope(rec.Scopes, requiredScope) {
			return AuthenticatePublicAPIAppResult{
				RequestID:     cmd.RequestID,
				AppID:         cmd.AppID,
				APIKeyID:      cmd.APIKeyID,
				Environment:   cmd.Environment,
				GrantedScopes: cloneStringSlice(rec.Scopes),
				AuthStatus:    "denied",
				Authenticated: false,
				DenialReason:  "scope yetkisi yok",
			}, nil
		}
	}

	return AuthenticatePublicAPIAppResult{
		RequestID:     cmd.RequestID,
		AppID:         rec.AppID,
		APIKeyID:      rec.APIKeyID,
		Environment:   rec.Environment,
		GrantedScopes: cloneStringSlice(rec.Scopes),
		AuthStatus:    "authenticated",
		Authenticated: true,
	}, nil
}

func publicAPIRuntimeHasScope(scopes []string, target string) bool {
	target = strings.TrimSpace(target)
	for _, scope := range scopes {
		if strings.TrimSpace(scope) == target {
			return true
		}
	}
	return false
}

func (s *publicAPIRuntimeIntegrationStore) EvaluateQuota(_ context.Context, cmd EvaluatePublicAPIQuotaCommand) (EvaluatePublicAPIQuotaResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	limit := fallbackPublicAPIQuotaLimit(cmd.Environment, cmd.QuotaWindow)
	if strings.TrimSpace(cmd.Environment) == "sandbox" && strings.TrimSpace(cmd.QuotaWindow) == "minute" {
		limit = 2
	}

	key := publicAPIRuntimeUsageKey(cmd.TenantID, cmd.AppID, cmd.APIKeyID, cmd.Environment, cmd.QuotaWindow)
	usedBefore := s.usage[key]
	usedAfter := usedBefore + cmd.Cost

	if usedAfter > limit {
		return EvaluatePublicAPIQuotaResult{
			RequestID:         cmd.RequestID,
			AppID:             cmd.AppID,
			APIKeyID:          cmd.APIKeyID,
			Environment:       cmd.Environment,
			QuotaWindow:       cmd.QuotaWindow,
			Limit:             limit,
			UsedBefore:        usedBefore,
			Cost:              cmd.Cost,
			UsedAfter:         usedAfter,
			Remaining:         0,
			RateLimitStatus:   "limited",
			Allowed:           false,
			RetryAfterSeconds: fallbackPublicAPIRetryAfterSeconds(cmd.QuotaWindow),
			DenialReason:      "quota limit asildi",
		}, nil
	}

	s.usage[key] = usedAfter

	return EvaluatePublicAPIQuotaResult{
		RequestID:       cmd.RequestID,
		AppID:           cmd.AppID,
		APIKeyID:        cmd.APIKeyID,
		Environment:     cmd.Environment,
		QuotaWindow:     cmd.QuotaWindow,
		Limit:           limit,
		UsedBefore:      usedBefore,
		Cost:            cmd.Cost,
		UsedAfter:       usedAfter,
		Remaining:       limit - usedAfter,
		RateLimitStatus: "allowed",
		Allowed:         true,
	}, nil
}

func (s *publicAPIRuntimeIntegrationStore) EnsureSandbox(_ context.Context, cmd EnsurePublicAPISandboxCommand) (EnsurePublicAPISandboxResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	rec := &publicAPIRuntimeSandboxRecord{
		TenantID:      strings.TrimSpace(cmd.TenantID),
		SandboxID:     buildFallbackPublicAPISandboxID(cmd.AppID, cmd.SandboxName),
		AppID:         strings.TrimSpace(cmd.AppID),
		Environment:   strings.TrimSpace(cmd.Environment),
		SandboxName:   strings.TrimSpace(cmd.SandboxName),
		DataMode:      strings.TrimSpace(cmd.DataMode),
		BaseURL:       buildFallbackPublicAPISandboxBaseURL(cmd.AppID, cmd.SandboxName),
		Isolated:      true,
		SandboxStatus: "ready",
		Ready:         true,
	}

	s.sandboxes[publicAPIRuntimeSandboxKey(rec.TenantID, rec.AppID, rec.SandboxName)] = rec

	return EnsurePublicAPISandboxResult{
		SandboxID:     rec.SandboxID,
		AppID:         rec.AppID,
		Environment:   rec.Environment,
		SandboxName:   rec.SandboxName,
		DataMode:      rec.DataMode,
		BaseURL:       rec.BaseURL,
		Isolated:      rec.Isolated,
		SandboxStatus: rec.SandboxStatus,
		Ready:         rec.Ready,
	}, nil
}

func (s *publicAPIRuntimeIntegrationStore) PublishDocs(_ context.Context, cmd PublishDeveloperDocsCommand) (PublishDeveloperDocsResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.docsSeq++
	docsID := fmt.Sprintf("docs-%03d", s.docsSeq)

	if strings.TrimSpace(cmd.SourceRef) == "blocked-docs" {
		return PublishDeveloperDocsResult{
			DocsID:        docsID,
			AppID:         cmd.AppID,
			DocsVersion:   cmd.DocsVersion,
			Environment:   cmd.Environment,
			DocsFormat:    cmd.DocsFormat,
			SourceRef:     cmd.SourceRef,
			TargetPath:    normalizePublicAPIPath(cmd.TargetPath),
			PublishStatus: "blocked",
			Published:     false,
			DenialReason:  "docs validation failed",
		}, nil
	}

	rec := &publicAPIRuntimeDocsRecord{
		TenantID:      strings.TrimSpace(cmd.TenantID),
		DocsID:        docsID,
		AppID:         strings.TrimSpace(cmd.AppID),
		DocsVersion:   strings.TrimSpace(cmd.DocsVersion),
		Environment:   strings.TrimSpace(cmd.Environment),
		DocsFormat:    strings.TrimSpace(cmd.DocsFormat),
		SourceRef:     strings.TrimSpace(cmd.SourceRef),
		TargetPath:    normalizePublicAPIPath(cmd.TargetPath),
		PublicURL:     buildFallbackPublicAPIDocsURL(cmd.Environment, cmd.TargetPath),
		PublishStatus: "published",
		Published:     true,
	}

	s.docs[publicAPIRuntimeDocsKey(rec.TenantID, rec.AppID, rec.DocsVersion, rec.Environment, rec.DocsFormat)] = rec

	return PublishDeveloperDocsResult{
		DocsID:        rec.DocsID,
		AppID:         rec.AppID,
		DocsVersion:   rec.DocsVersion,
		Environment:   rec.Environment,
		DocsFormat:    rec.DocsFormat,
		SourceRef:     rec.SourceRef,
		TargetPath:    rec.TargetPath,
		PublicURL:     rec.PublicURL,
		PublishStatus: rec.PublishStatus,
		Published:     rec.Published,
	}, nil
}

func TestPublicAPIRuntimeIntegration_ProductionGatewayKeyAuthQuotaDocsFlow(t *testing.T) {
	store := newPublicAPIRuntimeIntegrationStore()

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 18, 0, 0, 0, time.UTC)
	}

	gatewayUsecase := NewResolvePublicAPIGatewayUsecase(store)
	keyUsecase := NewIssuePublicAPIKeyUsecase(store)
	authUsecase := NewAuthenticatePublicAPIAppUsecase(store)
	quotaUsecase := NewEvaluatePublicAPIQuotaUsecase(store)
	docsUsecase := NewPublishDeveloperDocsUsecase(store)

	gatewayUsecase.nowFn = store.nowFn
	keyUsecase.nowFn = store.nowFn
	authUsecase.nowFn = store.nowFn
	quotaUsecase.nowFn = store.nowFn
	docsUsecase.nowFn = store.nowFn

	keyUsecase.secretFn = func(_ IssuePublicAPIKeyRequest, _ time.Time) string {
		return "pix_live_1234567890abcdef"
	}

	keyResp, err := keyUsecase.Issue(context.Background(), IssuePublicAPIKeyRequest{
		TenantID:    "tenant-a",
		AppID:       "app-prod",
		KeyName:     "prod-main-key",
		Environment: "production",
		Scopes:      []string{"erp.read", "erp.write"},
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("api key issue hatasi: %v", err)
	}

	if !keyResp.Issued || keyResp.KeyPrefix != "pix_live" {
		t.Fatalf("production api key beklenen gibi degil")
	}

	gatewayResp, err := gatewayUsecase.Resolve(context.Background(), ResolvePublicAPIGatewayRequest{
		TenantID:    "tenant-a",
		RequestID:   "req-prod-001",
		AppID:       "app-prod",
		APIKeyID:    keyResp.APIKeyID,
		Method:      "GET",
		Path:        "/v1/erp/customers",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("gateway resolve hatasi: %v", err)
	}

	if !gatewayResp.Accepted || gatewayResp.TargetService != "erp-api" {
		t.Fatalf("gateway erp-api route kabul etmeli")
	}

	authResp, err := authUsecase.Authenticate(context.Background(), AuthenticatePublicAPIAppRequest{
		TenantID:       "tenant-a",
		RequestID:      "req-prod-001",
		AppID:          "app-prod",
		APIKeyID:       keyResp.APIKeyID,
		KeyFingerprint: keyResp.KeyFingerprint,
		Environment:    "production",
		RequiredScopes: []string{"erp.read"},
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("app auth hatasi: %v", err)
	}

	if !authResp.Authenticated {
		t.Fatalf("production app auth authenticated olmaliydi")
	}

	quotaResp, err := quotaUsecase.Evaluate(context.Background(), EvaluatePublicAPIQuotaRequest{
		TenantID:    "tenant-a",
		RequestID:   "req-prod-001",
		AppID:       "app-prod",
		APIKeyID:    keyResp.APIKeyID,
		Environment: "production",
		QuotaWindow: "minute",
		Cost:        1,
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("quota evaluate hatasi: %v", err)
	}

	if !quotaResp.Allowed || quotaResp.UsedAfter != 1 {
		t.Fatalf("production quota allowed ve used_after 1 olmaliydi")
	}

	docsResp, err := docsUsecase.Publish(context.Background(), PublishDeveloperDocsRequest{
		TenantID:    "tenant-a",
		AppID:       "app-prod",
		DocsVersion: "v1",
		Environment: "production",
		DocsFormat:  "openapi",
		SourceRef:   "openapi-v1",
		TargetPath:  "/docs/v1",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("docs publish hatasi: %v", err)
	}

	if !docsResp.Published || docsResp.PublicURL != "https://developer.pix2pi.com.tr/docs/v1" {
		t.Fatalf("production docs publish beklenen gibi degil")
	}
}

func TestPublicAPIRuntimeIntegration_SandboxEnvironmentAndQuotaLimitFlow(t *testing.T) {
	store := newPublicAPIRuntimeIntegrationStore()

	keyUsecase := NewIssuePublicAPIKeyUsecase(store)
	authUsecase := NewAuthenticatePublicAPIAppUsecase(store)
	quotaUsecase := NewEvaluatePublicAPIQuotaUsecase(store)
	sandboxUsecase := NewEnsurePublicAPISandboxUsecase(store)
	docsUsecase := NewPublishDeveloperDocsUsecase(store)

	keyUsecase.secretFn = func(_ IssuePublicAPIKeyRequest, _ time.Time) string {
		return "pix_test_1234567890abcdef"
	}

	keyResp, err := keyUsecase.Issue(context.Background(), IssuePublicAPIKeyRequest{
		TenantID:    "tenant-b",
		AppID:       "app-sandbox",
		KeyName:     "sandbox-key",
		Environment: "sandbox",
		Scopes:      []string{"usage.read", "developer.manage"},
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("sandbox key issue hatasi: %v", err)
	}

	if keyResp.KeyPrefix != "pix_test" {
		t.Fatalf("sandbox key prefix pix_test olmaliydi")
	}

	sandboxResp, err := sandboxUsecase.Ensure(context.Background(), EnsurePublicAPISandboxRequest{
		TenantID:    "tenant-b",
		AppID:       "app-sandbox",
		Environment: "sandbox",
		SandboxName: "qa",
		DataMode:    "sample_data",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("sandbox ensure hatasi: %v", err)
	}

	if !sandboxResp.Ready || !sandboxResp.Isolated {
		t.Fatalf("sandbox ready ve isolated olmaliydi")
	}

	authResp, err := authUsecase.Authenticate(context.Background(), AuthenticatePublicAPIAppRequest{
		TenantID:       "tenant-b",
		RequestID:      "req-sandbox-001",
		AppID:          "app-sandbox",
		APIKeyID:       keyResp.APIKeyID,
		KeyFingerprint: keyResp.KeyFingerprint,
		Environment:    "sandbox",
		RequiredScopes: []string{"usage.read"},
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("sandbox auth hatasi: %v", err)
	}

	if !authResp.Authenticated {
		t.Fatalf("sandbox auth authenticated olmaliydi")
	}

	allowedResp, err := quotaUsecase.Evaluate(context.Background(), EvaluatePublicAPIQuotaRequest{
		TenantID:    "tenant-b",
		RequestID:   "req-sandbox-001",
		AppID:       "app-sandbox",
		APIKeyID:    keyResp.APIKeyID,
		Environment: "sandbox",
		QuotaWindow: "minute",
		Cost:        2,
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("sandbox quota allowed hatasi: %v", err)
	}

	if !allowedResp.Allowed || allowedResp.Remaining != 0 {
		t.Fatalf("ilk sandbox quota istegi allowed ve remaining 0 olmaliydi")
	}

	limitedResp, err := quotaUsecase.Evaluate(context.Background(), EvaluatePublicAPIQuotaRequest{
		TenantID:    "tenant-b",
		RequestID:   "req-sandbox-002",
		AppID:       "app-sandbox",
		APIKeyID:    keyResp.APIKeyID,
		Environment: "sandbox",
		QuotaWindow: "minute",
		Cost:        1,
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("sandbox quota limited hatasi: %v", err)
	}

	if limitedResp.Allowed || limitedResp.RateLimitStatus != "limited" {
		t.Fatalf("ikinci sandbox quota istegi limited olmaliydi")
	}

	docsResp, err := docsUsecase.Publish(context.Background(), PublishDeveloperDocsRequest{
		TenantID:    "tenant-b",
		AppID:       "app-sandbox",
		DocsVersion: "v1",
		Environment: "sandbox",
		DocsFormat:  "portal",
		SourceRef:   "portal-v1",
		TargetPath:  "docs/v1",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("sandbox docs publish hatasi: %v", err)
	}

	if !docsResp.Published || docsResp.PublicURL != "https://sandbox-developer.pix2pi.com.tr/docs/v1" {
		t.Fatalf("sandbox docs publish beklenen gibi degil")
	}
}

func TestPublicAPIRuntimeIntegration_DeniedAuthRejectedRouteAndBlockedDocsFlow(t *testing.T) {
	store := newPublicAPIRuntimeIntegrationStore()

	gatewayUsecase := NewResolvePublicAPIGatewayUsecase(store)
	keyUsecase := NewIssuePublicAPIKeyUsecase(store)
	authUsecase := NewAuthenticatePublicAPIAppUsecase(store)
	docsUsecase := NewPublishDeveloperDocsUsecase(store)

	keyUsecase.secretFn = func(_ IssuePublicAPIKeyRequest, _ time.Time) string {
		return "pix_test_denied1234567890"
	}

	keyResp, err := keyUsecase.Issue(context.Background(), IssuePublicAPIKeyRequest{
		TenantID:    "tenant-c",
		AppID:       "app-denied",
		KeyName:     "limited-key",
		Environment: "sandbox",
		Scopes:      []string{"erp.read"},
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("key issue hatasi: %v", err)
	}

	rejectedRoute, err := gatewayUsecase.Resolve(context.Background(), ResolvePublicAPIGatewayRequest{
		TenantID:    "tenant-c",
		RequestID:   "req-denied-001",
		AppID:       "app-denied",
		APIKeyID:    keyResp.APIKeyID,
		Method:      "DELETE",
		Path:        "/v1/admin/root",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("gateway rejected route hatasi: %v", err)
	}

	if rejectedRoute.Accepted {
		t.Fatalf("admin route rejected olmaliydi")
	}

	authResp, err := authUsecase.Authenticate(context.Background(), AuthenticatePublicAPIAppRequest{
		TenantID:       "tenant-c",
		RequestID:      "req-denied-002",
		AppID:          "app-denied",
		APIKeyID:       keyResp.APIKeyID,
		KeyFingerprint: keyResp.KeyFingerprint,
		Environment:    "sandbox",
		RequiredScopes: []string{"erp.write"},
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("denied auth hatasi: %v", err)
	}

	if authResp.Authenticated || authResp.AuthStatus != "denied" {
		t.Fatalf("scope eksigi nedeniyle auth denied olmaliydi")
	}

	blockedDocs, err := docsUsecase.Publish(context.Background(), PublishDeveloperDocsRequest{
		TenantID:    "tenant-c",
		AppID:       "app-denied",
		DocsVersion: "v1",
		Environment: "sandbox",
		DocsFormat:  "markdown",
		SourceRef:   "blocked-docs",
		TargetPath:  "/docs/v1",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("blocked docs publish hatasi: %v", err)
	}

	if blockedDocs.Published || blockedDocs.PublishStatus != "blocked" {
		t.Fatalf("blocked docs published false olmaliydi")
	}

	if blockedDocs.DenialReason == "" {
		t.Fatalf("blocked docs denial_reason dolu olmaliydi")
	}
}
