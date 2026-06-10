package publicapiruntime

import (
	"strings"
	"testing"
)

func TestAPIKeyIssuanceRuntimeIssuesKeyWithHashedSecret(t *testing.T) {
	runtime := NewAPIKeyIssuanceRuntime(DefaultAPIKeyIssuanceRuntimeConfig())

	result, decision, err := runtime.IssueKey(APIKeyIssueRequest{
		TenantID:    "tenant_7",
		Name:        "Backend Integration",
		Environment: APIKeyEnvironmentSandbox,
		Scopes:      []string{"read", "write", "read"},
		CreatedBy:   "admin_1",
	})
	if err != nil {
		t.Fatalf("issue key failed: %v", err)
	}

	if !decision.Allowed {
		t.Fatalf("expected allowed decision, got reason=%s", decision.Reason)
	}
	if result.RawSecret == "" {
		t.Fatal("expected raw secret")
	}
	if !strings.HasPrefix(result.RawSecret, "pix2pi_sandbox_") {
		t.Fatalf("unexpected raw secret prefix: %s", result.RawSecret)
	}
	if result.Record.SecretHash == "" {
		t.Fatal("expected secret hash")
	}
	if strings.Contains(result.Record.SecretHash, result.RawSecret) {
		t.Fatal("secret hash must not contain raw secret")
	}
	if result.Record.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", result.Record.TenantID)
	}
	if result.Record.Status != APIKeyStatusActive {
		t.Fatalf("expected ACTIVE, got %s", result.Record.Status)
	}
	if len(result.Record.Scopes) != 2 {
		t.Fatalf("expected deduplicated scopes length 2, got %d", len(result.Record.Scopes))
	}
}

func TestAPIKeyIssuanceRuntimeRejectsMissingTenant(t *testing.T) {
	runtime := NewAPIKeyIssuanceRuntime(DefaultAPIKeyIssuanceRuntimeConfig())

	_, decision, err := runtime.IssueKey(APIKeyIssueRequest{
		Name:        "No Tenant",
		Environment: APIKeyEnvironmentSandbox,
		Scopes:      []string{"read"},
	})

	if err != ErrAPIKeyMissingTenant {
		t.Fatalf("expected missing tenant error, got %v", err)
	}
	if decision.Reason != APIKeyReasonMissingTenant {
		t.Fatalf("expected missing tenant reason, got %s", decision.Reason)
	}
}

func TestAPIKeyIssuanceRuntimeRejectsInvalidScope(t *testing.T) {
	runtime := NewAPIKeyIssuanceRuntime(DefaultAPIKeyIssuanceRuntimeConfig())

	_, decision, err := runtime.IssueKey(APIKeyIssueRequest{
		TenantID:    "tenant_7",
		Name:        "Bad Scope",
		Environment: APIKeyEnvironmentSandbox,
		Scopes:      []string{"root:all"},
	})

	if err != ErrAPIKeyInvalidScope {
		t.Fatalf("expected invalid scope error, got %v", err)
	}
	if decision.Reason != APIKeyReasonInvalidScope {
		t.Fatalf("expected invalid scope reason, got %s", decision.Reason)
	}
}

func TestAPIKeyIssuanceRuntimeRejectsInvalidEnvironment(t *testing.T) {
	runtime := NewAPIKeyIssuanceRuntime(DefaultAPIKeyIssuanceRuntimeConfig())

	_, decision, err := runtime.IssueKey(APIKeyIssueRequest{
		TenantID:    "tenant_7",
		Name:        "Bad Env",
		Environment: "LOCAL",
		Scopes:      []string{"read"},
	})

	if err != ErrAPIKeyInvalidEnvironment {
		t.Fatalf("expected invalid environment error, got %v", err)
	}
	if decision.Reason != APIKeyReasonInvalidEnvironment {
		t.Fatalf("expected invalid environment reason, got %s", decision.Reason)
	}
}

func TestAPIKeyIssuanceRuntimeTenantSafeGetAndList(t *testing.T) {
	runtime := NewAPIKeyIssuanceRuntime(DefaultAPIKeyIssuanceRuntimeConfig())

	result, _, err := runtime.IssueKey(APIKeyIssueRequest{
		TenantID:    "tenant_7",
		Name:        "Tenant Key",
		Environment: APIKeyEnvironmentProduction,
		Scopes:      []string{"read"},
	})
	if err != nil {
		t.Fatalf("issue key failed: %v", err)
	}

	record, err := runtime.GetKey("tenant_7", result.Record.KeyID)
	if err != nil {
		t.Fatalf("get key failed: %v", err)
	}
	if record.KeyID != result.Record.KeyID {
		t.Fatalf("expected key id %s, got %s", result.Record.KeyID, record.KeyID)
	}

	_, err = runtime.GetKey("tenant_8", result.Record.KeyID)
	if err != ErrAPIKeyCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}

	keysTenant7, err := runtime.ListTenantKeys("tenant_7")
	if err != nil {
		t.Fatalf("list tenant_7 failed: %v", err)
	}
	if len(keysTenant7) != 1 {
		t.Fatalf("expected tenant_7 key count 1, got %d", len(keysTenant7))
	}

	keysTenant8, err := runtime.ListTenantKeys("tenant_8")
	if err != nil {
		t.Fatalf("list tenant_8 failed: %v", err)
	}
	if len(keysTenant8) != 0 {
		t.Fatalf("expected tenant_8 key count 0, got %d", len(keysTenant8))
	}
}

func TestAPIKeyIssuanceRuntimeRevokesKey(t *testing.T) {
	runtime := NewAPIKeyIssuanceRuntime(DefaultAPIKeyIssuanceRuntimeConfig())

	result, _, err := runtime.IssueKey(APIKeyIssueRequest{
		TenantID:    "tenant_7",
		Name:        "Revokable",
		Environment: APIKeyEnvironmentSandbox,
		Scopes:      []string{"read"},
	})
	if err != nil {
		t.Fatalf("issue key failed: %v", err)
	}

	record, decision, err := runtime.RevokeKey("tenant_7", result.Record.KeyID, "admin_1")
	if err != nil {
		t.Fatalf("revoke failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected revoke allowed, got reason=%s", decision.Reason)
	}
	if record.Status != APIKeyStatusRevoked {
		t.Fatalf("expected REVOKED, got %s", record.Status)
	}
	if record.RevokedAt == "" {
		t.Fatal("expected revoked_at")
	}

	_, decision, err = runtime.RevokeKey("tenant_7", result.Record.KeyID, "admin_1")
	if err != ErrAPIKeyAlreadyInactive {
		t.Fatalf("expected already inactive error, got %v", err)
	}
	if decision.Reason != APIKeyReasonAlreadyInactive {
		t.Fatalf("expected already inactive reason, got %s", decision.Reason)
	}
}

func TestAPIKeyIssuanceRuntimeRotateKey(t *testing.T) {
	runtime := NewAPIKeyIssuanceRuntime(DefaultAPIKeyIssuanceRuntimeConfig())

	result, _, err := runtime.IssueKey(APIKeyIssueRequest{
		TenantID:    "tenant_7",
		Name:        "Rotatable",
		Environment: APIKeyEnvironmentProduction,
		Scopes:      []string{"read", "report:read"},
	})
	if err != nil {
		t.Fatalf("issue key failed: %v", err)
	}

	rotated, decision, err := runtime.RotateKey("tenant_7", result.Record.KeyID, "admin_1")
	if err != nil {
		t.Fatalf("rotate failed: %v", err)
	}
	if !decision.Allowed {
		t.Fatalf("expected rotate issue decision allowed, got reason=%s", decision.Reason)
	}
	if rotated.Record.KeyID == result.Record.KeyID {
		t.Fatal("expected new key id after rotation")
	}
	if rotated.RawSecret == result.RawSecret {
		t.Fatal("expected new raw secret after rotation")
	}

	oldRecord, err := runtime.GetKey("tenant_7", result.Record.KeyID)
	if err != nil {
		t.Fatalf("get old key failed: %v", err)
	}
	if oldRecord.Status != APIKeyStatusRotated {
		t.Fatalf("expected old key ROTATED, got %s", oldRecord.Status)
	}

	newRecord, err := runtime.GetKey("tenant_7", rotated.Record.KeyID)
	if err != nil {
		t.Fatalf("get new key failed: %v", err)
	}
	if newRecord.Status != APIKeyStatusActive {
		t.Fatalf("expected new key ACTIVE, got %s", newRecord.Status)
	}
}

func TestHashAPIKeySecretIsDeterministicAndNonRaw(t *testing.T) {
	raw := "pix2pi_sandbox_test_secret"
	hash1 := HashAPIKeySecret(raw)
	hash2 := HashAPIKeySecret(raw)

	if hash1 != hash2 {
		t.Fatal("expected deterministic hash")
	}
	if hash1 == raw {
		t.Fatal("hash must not equal raw secret")
	}
	if !strings.HasPrefix(hash1, "sha256:") {
		t.Fatalf("expected sha256 hash prefix, got %s", hash1)
	}
}
