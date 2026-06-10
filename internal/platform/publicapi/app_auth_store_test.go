package publicapi

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type publicAPIAppAuthRowMock struct {
	values []any
	err    error
}

func (r *publicAPIAppAuthRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *bool:
			*d = r.values[i].(bool)
		case *[]string:
			*d = cloneStringSlice(r.values[i].([]string))
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type publicAPIAppAuthQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *publicAPIAppAuthQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestAuthenticatePublicAPIAppSQLStoreAuthenticateApp_Success(t *testing.T) {
	db := &publicAPIAppAuthQueryRowProviderMock{
		row: &publicAPIAppAuthRowMock{
			values: []any{
				"req-001",
				"app-001",
				"key-001",
				"production",
				[]string{"erp.read", "erp.write"},
				"authenticated",
				true,
				"",
			},
		},
	}

	store := NewAuthenticatePublicAPIAppSQLStore(db)

	result, err := store.AuthenticateApp(context.Background(), AuthenticatePublicAPIAppCommand{
		TenantID:       "tenant-a",
		RequestID:      "req-001",
		AppID:          "app-001",
		APIKeyID:       "key-001",
		KeyFingerprint: "fingerprint-001",
		Environment:    "production",
		RequiredScopes: []string{"erp.read"},
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.RequestID != "req-001" {
		t.Fatalf("beklenen request_id req-001, alinan: %s", result.RequestID)
	}

	if result.AppID != "app-001" {
		t.Fatalf("beklenen app_id app-001, alinan: %s", result.AppID)
	}

	if result.APIKeyID != "key-001" {
		t.Fatalf("beklenen api_key_id key-001, alinan: %s", result.APIKeyID)
	}

	if result.Environment != "production" {
		t.Fatalf("beklenen environment production, alinan: %s", result.Environment)
	}

	if len(result.GrantedScopes) != 2 || result.GrantedScopes[0] != "erp.read" || result.GrantedScopes[1] != "erp.write" {
		t.Fatalf("beklenen granted_scopes erp.read, erp.write; alinan: %#v", result.GrantedScopes)
	}

	if result.AuthStatus != "authenticated" {
		t.Fatalf("beklenen auth_status authenticated, alinan: %s", result.AuthStatus)
	}

	if !result.Authenticated {
		t.Fatalf("beklenen authenticated true")
	}

	if result.DenialReason != "" {
		t.Fatalf("authenticated durumda denial_reason bos olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.public_api_keys") {
		t.Fatalf("public_api_keys query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "key_fingerprint = $4") {
		t.Fatalf("key_fingerprint filtresi query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "$7 <@") {
		t.Fatalf("required scope subset kontrolu query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "expires_at") {
		t.Fatalf("expires_at kontrolu query icinde olmaliydi")
	}

	if len(db.lastArgs) != 8 {
		t.Fatalf("beklenen 8 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestAuthenticatePublicAPIAppSQLStoreAuthenticateApp_DeniedScopeSuccess(t *testing.T) {
	db := &publicAPIAppAuthQueryRowProviderMock{
		row: &publicAPIAppAuthRowMock{
			values: []any{
				"req-002",
				"app-001",
				"key-001",
				"sandbox",
				[]string{"erp.read"},
				"denied",
				false,
				"scope yetkisi yok",
			},
		},
	}

	store := NewAuthenticatePublicAPIAppSQLStore(db)

	result, err := store.AuthenticateApp(context.Background(), AuthenticatePublicAPIAppCommand{
		RequestID:      "req-002",
		AppID:          "app-001",
		APIKeyID:       "key-001",
		KeyFingerprint: "fingerprint-001",
		Environment:    "sandbox",
		RequiredScopes: []string{"erp.write"},
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Authenticated {
		t.Fatalf("beklenen authenticated false")
	}

	if result.AuthStatus != "denied" {
		t.Fatalf("beklenen auth_status denied, alinan: %s", result.AuthStatus)
	}

	if result.DenialReason == "" {
		t.Fatalf("beklenen denial_reason dolu")
	}
}

func TestAuthenticatePublicAPIAppSQLStoreAuthenticateApp_DeniedExpiredSuccess(t *testing.T) {
	db := &publicAPIAppAuthQueryRowProviderMock{
		row: &publicAPIAppAuthRowMock{
			values: []any{
				"req-003",
				"app-001",
				"key-001",
				"production",
				[]string{"erp.read"},
				"denied",
				false,
				"api key suresi dolmus",
			},
		},
	}

	store := NewAuthenticatePublicAPIAppSQLStore(db)

	result, err := store.AuthenticateApp(context.Background(), AuthenticatePublicAPIAppCommand{
		RequestID:      "req-003",
		AppID:          "app-001",
		APIKeyID:       "key-001",
		KeyFingerprint: "fingerprint-001",
		Environment:    "production",
		RequiredScopes: []string{"erp.read"},
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Authenticated {
		t.Fatalf("beklenen authenticated false")
	}

	if result.DenialReason != "api key suresi dolmus" {
		t.Fatalf("beklenen denial_reason api key suresi dolmus, alinan: %s", result.DenialReason)
	}
}

func TestAuthenticatePublicAPIAppSQLStoreAuthenticateApp_NoDB(t *testing.T) {
	store := NewAuthenticatePublicAPIAppSQLStore(nil)

	_, err := store.AuthenticateApp(context.Background(), AuthenticatePublicAPIAppCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestAuthenticatePublicAPIAppSQLStoreAuthenticateApp_ScanError(t *testing.T) {
	db := &publicAPIAppAuthQueryRowProviderMock{
		row: &publicAPIAppAuthRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewAuthenticatePublicAPIAppSQLStore(db)

	_, err := store.AuthenticateApp(context.Background(), AuthenticatePublicAPIAppCommand{
		TenantID:       "tenant-a",
		RequestID:      "req-001",
		AppID:          "app-001",
		APIKeyID:       "key-001",
		KeyFingerprint: "fingerprint-001",
		Environment:    "production",
		RequiredScopes: []string{"erp.read"},
		RequestedBy:    "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
