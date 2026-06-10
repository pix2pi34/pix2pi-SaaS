package publicapiruntime

import "testing"

func issueTestAPIKeyForAppAuth(t *testing.T, tenantID string, environment string, scopes []string) APIKeyRecord {
	t.Helper()

	keyRuntime := NewAPIKeyIssuanceRuntime(DefaultAPIKeyIssuanceRuntimeConfig())
	result, _, err := keyRuntime.IssueKey(APIKeyIssueRequest{
		TenantID:    tenantID,
		Name:        "App Auth Test Key",
		Environment: environment,
		Scopes:      scopes,
	})
	if err != nil {
		t.Fatalf("issue api key failed: %v", err)
	}

	return result.Record
}

func TestAppAuthRuntimeRegistersApp(t *testing.T) {
	runtime := NewAppAuthRuntime(DefaultAppAuthRuntimeConfig())

	app, decision, err := runtime.RegisterApp(AppRegistrationRequest{
		TenantID:      "tenant_7",
		Name:          "Integration App",
		Environment:   APIKeyEnvironmentSandbox,
		AllowedScopes: []string{"read", "write"},
		CreatedBy:     "admin_1",
	})
	if err != nil {
		t.Fatalf("register app failed: %v", err)
	}

	if !decision.Allowed {
		t.Fatalf("expected register allowed, got reason=%s", decision.Reason)
	}
	if app.AppID == "" {
		t.Fatal("expected app id")
	}
	if app.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", app.TenantID)
	}
	if app.Status != AppStatusActive {
		t.Fatalf("expected ACTIVE, got %s", app.Status)
	}
	if len(app.AllowedScopes) != 2 {
		t.Fatalf("expected 2 scopes, got %d", len(app.AllowedScopes))
	}
}

func TestAppAuthRuntimeRejectsInvalidScope(t *testing.T) {
	runtime := NewAppAuthRuntime(DefaultAppAuthRuntimeConfig())

	_, decision, err := runtime.RegisterApp(AppRegistrationRequest{
		TenantID:      "tenant_7",
		Name:          "Bad Scope App",
		Environment:   APIKeyEnvironmentSandbox,
		AllowedScopes: []string{"root:all"},
	})

	if err != ErrAppAuthInvalidScope {
		t.Fatalf("expected invalid scope error, got %v", err)
	}
	if decision.Reason != AppAuthReasonInvalidScope {
		t.Fatalf("expected invalid scope reason, got %s", decision.Reason)
	}
}

func TestAppAuthRuntimeLinksAPIKeyToApp(t *testing.T) {
	runtime := NewAppAuthRuntime(DefaultAppAuthRuntimeConfig())

	app, _, err := runtime.RegisterApp(AppRegistrationRequest{
		TenantID:      "tenant_7",
		Name:          "Linked App",
		Environment:   APIKeyEnvironmentSandbox,
		AllowedScopes: []string{"read", "write", "report:read"},
	})
	if err != nil {
		t.Fatalf("register app failed: %v", err)
	}

	key := issueTestAPIKeyForAppAuth(t, "tenant_7", APIKeyEnvironmentSandbox, []string{"read", "report:read"})

	relation, decision, err := runtime.LinkAPIKey(AppAPIKeyRelationRequest{
		TenantID:     "tenant_7",
		AppID:        app.AppID,
		APIKeyRecord: key,
		CreatedBy:    "admin_1",
	})
	if err != nil {
		t.Fatalf("link api key failed: %v", err)
	}

	if !decision.Allowed {
		t.Fatalf("expected link allowed, got reason=%s", decision.Reason)
	}
	if relation.RelationID == "" {
		t.Fatal("expected relation id")
	}
	if relation.AppID != app.AppID {
		t.Fatalf("expected app id %s, got %s", app.AppID, relation.AppID)
	}
	if relation.KeyID != key.KeyID {
		t.Fatalf("expected key id %s, got %s", key.KeyID, relation.KeyID)
	}
	if len(relation.EffectiveScopes) != 2 {
		t.Fatalf("expected 2 effective scopes, got %d", len(relation.EffectiveScopes))
	}
}

func TestAppAuthRuntimeRejectsCrossTenantAPIKeyRelation(t *testing.T) {
	runtime := NewAppAuthRuntime(DefaultAppAuthRuntimeConfig())

	app, _, err := runtime.RegisterApp(AppRegistrationRequest{
		TenantID:      "tenant_7",
		Name:          "Tenant App",
		Environment:   APIKeyEnvironmentSandbox,
		AllowedScopes: []string{"read"},
	})
	if err != nil {
		t.Fatalf("register app failed: %v", err)
	}

	key := issueTestAPIKeyForAppAuth(t, "tenant_8", APIKeyEnvironmentSandbox, []string{"read"})

	_, decision, err := runtime.LinkAPIKey(AppAPIKeyRelationRequest{
		TenantID:     "tenant_7",
		AppID:        app.AppID,
		APIKeyRecord: key,
	})

	if err != ErrAppAuthCrossTenant {
		t.Fatalf("expected cross tenant error, got %v", err)
	}
	if decision.Reason != AppAuthReasonCrossTenant {
		t.Fatalf("expected cross tenant reason, got %s", decision.Reason)
	}
}

func TestAppAuthRuntimeRejectsEnvironmentMismatch(t *testing.T) {
	runtime := NewAppAuthRuntime(DefaultAppAuthRuntimeConfig())

	app, _, err := runtime.RegisterApp(AppRegistrationRequest{
		TenantID:      "tenant_7",
		Name:          "Sandbox App",
		Environment:   APIKeyEnvironmentSandbox,
		AllowedScopes: []string{"read"},
	})
	if err != nil {
		t.Fatalf("register app failed: %v", err)
	}

	key := issueTestAPIKeyForAppAuth(t, "tenant_7", APIKeyEnvironmentProduction, []string{"read"})

	_, decision, err := runtime.LinkAPIKey(AppAPIKeyRelationRequest{
		TenantID:     "tenant_7",
		AppID:        app.AppID,
		APIKeyRecord: key,
	})

	if err != ErrAppAuthEnvironmentMismatch {
		t.Fatalf("expected environment mismatch error, got %v", err)
	}
	if decision.Reason != AppAuthReasonEnvironmentMismatch {
		t.Fatalf("expected environment mismatch reason, got %s", decision.Reason)
	}
}

func TestAppAuthRuntimeRejectsAPIKeyScopeOutsideAppAllowedScopes(t *testing.T) {
	runtime := NewAppAuthRuntime(DefaultAppAuthRuntimeConfig())

	app, _, err := runtime.RegisterApp(AppRegistrationRequest{
		TenantID:      "tenant_7",
		Name:          "Read Only App",
		Environment:   APIKeyEnvironmentSandbox,
		AllowedScopes: []string{"read"},
	})
	if err != nil {
		t.Fatalf("register app failed: %v", err)
	}

	key := issueTestAPIKeyForAppAuth(t, "tenant_7", APIKeyEnvironmentSandbox, []string{"read", "write"})

	_, decision, err := runtime.LinkAPIKey(AppAPIKeyRelationRequest{
		TenantID:     "tenant_7",
		AppID:        app.AppID,
		APIKeyRecord: key,
	})

	if err != ErrAppAuthScopeNotAllowed {
		t.Fatalf("expected scope not allowed error, got %v", err)
	}
	if decision.Reason != AppAuthReasonScopeNotAllowed {
		t.Fatalf("expected scope not allowed reason, got %s", decision.Reason)
	}
}

func TestAppAuthRuntimeValidatesAppAuth(t *testing.T) {
	runtime := NewAppAuthRuntime(DefaultAppAuthRuntimeConfig())

	app, _, err := runtime.RegisterApp(AppRegistrationRequest{
		TenantID:      "tenant_7",
		Name:          "Validation App",
		Environment:   APIKeyEnvironmentProduction,
		AllowedScopes: []string{"read", "report:read"},
	})
	if err != nil {
		t.Fatalf("register app failed: %v", err)
	}

	key := issueTestAPIKeyForAppAuth(t, "tenant_7", APIKeyEnvironmentProduction, []string{"read", "report:read"})

	relation, _, err := runtime.LinkAPIKey(AppAPIKeyRelationRequest{
		TenantID:     "tenant_7",
		AppID:        app.AppID,
		APIKeyRecord: key,
	})
	if err != nil {
		t.Fatalf("link api key failed: %v", err)
	}

	decision, err := runtime.ValidateAppAuth(AppAuthValidationRequest{
		TenantID:        "tenant_7",
		AppID:           app.AppID,
		KeyID:           key.KeyID,
		RequestedScopes: []string{"read"},
		Environment:     APIKeyEnvironmentProduction,
	})
	if err != nil {
		t.Fatalf("validate app auth failed: %v", err)
	}

	if !decision.Allowed {
		t.Fatalf("expected validation allowed, got reason=%s", decision.Reason)
	}
	if decision.RelationID != relation.RelationID {
		t.Fatalf("expected relation id %s, got %s", relation.RelationID, decision.RelationID)
	}
	if len(decision.Scopes) != 1 || decision.Scopes[0] != "read" {
		t.Fatalf("unexpected decision scopes %#v", decision.Scopes)
	}
}

func TestAppAuthRuntimeRejectsValidationForUnlinkedKey(t *testing.T) {
	runtime := NewAppAuthRuntime(DefaultAppAuthRuntimeConfig())

	app, _, err := runtime.RegisterApp(AppRegistrationRequest{
		TenantID:      "tenant_7",
		Name:          "Unlinked App",
		Environment:   APIKeyEnvironmentSandbox,
		AllowedScopes: []string{"read"},
	})
	if err != nil {
		t.Fatalf("register app failed: %v", err)
	}

	key := issueTestAPIKeyForAppAuth(t, "tenant_7", APIKeyEnvironmentSandbox, []string{"read"})

	decision, err := runtime.ValidateAppAuth(AppAuthValidationRequest{
		TenantID:        "tenant_7",
		AppID:           app.AppID,
		KeyID:           key.KeyID,
		RequestedScopes: []string{"read"},
		Environment:     APIKeyEnvironmentSandbox,
	})

	if err != ErrAppAuthMissingRelation {
		t.Fatalf("expected missing relation error, got %v", err)
	}
	if decision.Reason != AppAuthReasonMissingRelation {
		t.Fatalf("expected missing relation reason, got %s", decision.Reason)
	}
}

func TestAppAuthRuntimeRejectsValidationForDisallowedScope(t *testing.T) {
	runtime := NewAppAuthRuntime(DefaultAppAuthRuntimeConfig())

	app, _, err := runtime.RegisterApp(AppRegistrationRequest{
		TenantID:      "tenant_7",
		Name:          "Scoped App",
		Environment:   APIKeyEnvironmentSandbox,
		AllowedScopes: []string{"read", "write"},
	})
	if err != nil {
		t.Fatalf("register app failed: %v", err)
	}

	key := issueTestAPIKeyForAppAuth(t, "tenant_7", APIKeyEnvironmentSandbox, []string{"read"})

	_, _, err = runtime.LinkAPIKey(AppAPIKeyRelationRequest{
		TenantID:     "tenant_7",
		AppID:        app.AppID,
		APIKeyRecord: key,
	})
	if err != nil {
		t.Fatalf("link api key failed: %v", err)
	}

	decision, err := runtime.ValidateAppAuth(AppAuthValidationRequest{
		TenantID:        "tenant_7",
		AppID:           app.AppID,
		KeyID:           key.KeyID,
		RequestedScopes: []string{"write"},
		Environment:     APIKeyEnvironmentSandbox,
	})

	if err != ErrAppAuthScopeNotAllowed {
		t.Fatalf("expected scope not allowed error, got %v", err)
	}
	if decision.Reason != AppAuthReasonScopeNotAllowed {
		t.Fatalf("expected scope not allowed reason, got %s", decision.Reason)
	}
}

func TestAppAuthRuntimeTenantSafeAppListAndGet(t *testing.T) {
	runtime := NewAppAuthRuntime(DefaultAppAuthRuntimeConfig())

	app, _, err := runtime.RegisterApp(AppRegistrationRequest{
		TenantID:      "tenant_7",
		Name:          "Tenant 7 App",
		Environment:   APIKeyEnvironmentSandbox,
		AllowedScopes: []string{"read"},
	})
	if err != nil {
		t.Fatalf("register app failed: %v", err)
	}

	_, _, err = runtime.RegisterApp(AppRegistrationRequest{
		TenantID:      "tenant_8",
		Name:          "Tenant 8 App",
		Environment:   APIKeyEnvironmentSandbox,
		AllowedScopes: []string{"read"},
	})
	if err != nil {
		t.Fatalf("register tenant_8 app failed: %v", err)
	}

	got, err := runtime.GetApp("tenant_7", app.AppID)
	if err != nil {
		t.Fatalf("get app failed: %v", err)
	}
	if got.AppID != app.AppID {
		t.Fatalf("expected app id %s, got %s", app.AppID, got.AppID)
	}

	_, err = runtime.GetApp("tenant_8", app.AppID)
	if err != ErrAppAuthCrossTenant {
		t.Fatalf("expected cross tenant get error, got %v", err)
	}

	apps, err := runtime.ListTenantApps("tenant_7")
	if err != nil {
		t.Fatalf("list tenant apps failed: %v", err)
	}
	if len(apps) != 1 {
		t.Fatalf("expected tenant_7 app count 1, got %d", len(apps))
	}
}

func TestAppAuthRuntimeSuspendedAppCannotValidate(t *testing.T) {
	runtime := NewAppAuthRuntime(DefaultAppAuthRuntimeConfig())

	app, _, err := runtime.RegisterApp(AppRegistrationRequest{
		TenantID:      "tenant_7",
		Name:          "Suspend App",
		Environment:   APIKeyEnvironmentSandbox,
		AllowedScopes: []string{"read"},
	})
	if err != nil {
		t.Fatalf("register app failed: %v", err)
	}

	key := issueTestAPIKeyForAppAuth(t, "tenant_7", APIKeyEnvironmentSandbox, []string{"read"})

	_, _, err = runtime.LinkAPIKey(AppAPIKeyRelationRequest{
		TenantID:     "tenant_7",
		AppID:        app.AppID,
		APIKeyRecord: key,
	})
	if err != nil {
		t.Fatalf("link api key failed: %v", err)
	}

	app, _, err = runtime.SuspendApp("tenant_7", app.AppID)
	if err != nil {
		t.Fatalf("suspend app failed: %v", err)
	}
	if app.Status != AppStatusSuspended {
		t.Fatalf("expected SUSPENDED, got %s", app.Status)
	}

	decision, err := runtime.ValidateAppAuth(AppAuthValidationRequest{
		TenantID:        "tenant_7",
		AppID:           app.AppID,
		KeyID:           key.KeyID,
		RequestedScopes: []string{"read"},
		Environment:     APIKeyEnvironmentSandbox,
	})
	if err != ErrAppAuthInactiveApp {
		t.Fatalf("expected inactive app error, got %v", err)
	}
	if decision.Reason != AppAuthReasonInactiveApp {
		t.Fatalf("expected inactive app reason, got %s", decision.Reason)
	}
}
