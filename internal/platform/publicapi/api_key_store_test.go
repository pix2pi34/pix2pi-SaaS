package publicapi

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"testing"
	"time"
)

type publicAPIKeyIssuerRowMock struct {
	values []any
	err    error
}

func (r *publicAPIKeyIssuerRowMock) Scan(dest ...any) error {
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
		case *sql.NullTime:
			switch v := r.values[i].(type) {
			case sql.NullTime:
				*d = v
			case time.Time:
				*d = sql.NullTime{Time: v, Valid: true}
			case nil:
				*d = sql.NullTime{Valid: false}
			default:
				return errors.New("sql.NullTime tipi desteklenmiyor")
			}
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type publicAPIKeyIssuerQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *publicAPIKeyIssuerQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestIssuePublicAPIKeySQLStoreIssueAPIKey_Success(t *testing.T) {
	expiresAt := time.Date(2026, 12, 31, 23, 59, 0, 0, time.UTC)

	db := &publicAPIKeyIssuerQueryRowProviderMock{
		row: &publicAPIKeyIssuerRowMock{
			values: []any{
				"key-001",
				"app-001",
				"erp-main-key",
				"production",
				[]string{"erp.read", "erp.write"},
				"pix_live",
				"pix_live...abcd",
				"fingerprint-001",
				"active",
				true,
				expiresAt,
			},
		},
	}

	store := NewIssuePublicAPIKeySQLStore(db)

	result, err := store.IssueAPIKey(context.Background(), IssuePublicAPIKeyCommand{
		TenantID:       "tenant-a",
		AppID:          "app-001",
		KeyName:        "erp-main-key",
		Environment:    "production",
		Scopes:         []string{"erp.read", "erp.write"},
		KeyPrefix:      "pix_live",
		KeyHash:        "hash-001",
		KeyFingerprint: "fingerprint-001",
		KeyPreview:     "pix_live...abcd",
		ExpiresAt:      &expiresAt,
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.APIKeyID != "key-001" {
		t.Fatalf("beklenen api_key_id key-001, alinan: %s", result.APIKeyID)
	}

	if result.AppID != "app-001" {
		t.Fatalf("beklenen app_id app-001, alinan: %s", result.AppID)
	}

	if result.KeyName != "erp-main-key" {
		t.Fatalf("beklenen key_name erp-main-key, alinan: %s", result.KeyName)
	}

	if result.Environment != "production" {
		t.Fatalf("beklenen environment production, alinan: %s", result.Environment)
	}

	if len(result.Scopes) != 2 || result.Scopes[0] != "erp.read" || result.Scopes[1] != "erp.write" {
		t.Fatalf("beklenen scopes erp.read, erp.write; alinan: %#v", result.Scopes)
	}

	if result.KeyPrefix != "pix_live" {
		t.Fatalf("beklenen key_prefix pix_live, alinan: %s", result.KeyPrefix)
	}

	if result.KeyPreview != "pix_live...abcd" {
		t.Fatalf("beklenen key_preview pix_live...abcd, alinan: %s", result.KeyPreview)
	}

	if result.KeyFingerprint != "fingerprint-001" {
		t.Fatalf("beklenen key_fingerprint fingerprint-001, alinan: %s", result.KeyFingerprint)
	}

	if result.Status != "active" {
		t.Fatalf("beklenen status active, alinan: %s", result.Status)
	}

	if !result.Issued {
		t.Fatalf("beklenen issued true")
	}

	if result.ExpiresAt == nil || !result.ExpiresAt.Equal(expiresAt) {
		t.Fatalf("beklenen expires_at korunmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.public_api_keys") {
		t.Fatalf("public_api_keys query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "key_hash") {
		t.Fatalf("key_hash query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "key_fingerprint") {
		t.Fatalf("key_fingerprint query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "key_preview") {
		t.Fatalf("key_preview query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "'active'") {
		t.Fatalf("active status query icinde olmaliydi")
	}

	if len(db.lastArgs) != 11 {
		t.Fatalf("beklenen 11 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestIssuePublicAPIKeySQLStoreIssueAPIKey_WithoutExpiresAtSuccess(t *testing.T) {
	db := &publicAPIKeyIssuerQueryRowProviderMock{
		row: &publicAPIKeyIssuerRowMock{
			values: []any{
				"key-002",
				"app-002",
				"sandbox-key",
				"sandbox",
				[]string{"usage.read"},
				"pix_test",
				"pix_test...abcd",
				"fingerprint-002",
				"active",
				true,
				nil,
			},
		},
	}

	store := NewIssuePublicAPIKeySQLStore(db)

	result, err := store.IssueAPIKey(context.Background(), IssuePublicAPIKeyCommand{
		AppID:          "app-002",
		KeyName:        "sandbox-key",
		Environment:    "sandbox",
		Scopes:         []string{"usage.read"},
		KeyPrefix:      "pix_test",
		KeyHash:        "hash-002",
		KeyFingerprint: "fingerprint-002",
		KeyPreview:     "pix_test...abcd",
		RequestedBy:    "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.ExpiresAt != nil {
		t.Fatalf("expires_at nil olmaliydi")
	}

	if result.Environment != "sandbox" {
		t.Fatalf("beklenen environment sandbox, alinan: %s", result.Environment)
	}

	if result.KeyPrefix != "pix_test" {
		t.Fatalf("beklenen key_prefix pix_test, alinan: %s", result.KeyPrefix)
	}
}

func TestIssuePublicAPIKeySQLStoreIssueAPIKey_NoDB(t *testing.T) {
	store := NewIssuePublicAPIKeySQLStore(nil)

	_, err := store.IssueAPIKey(context.Background(), IssuePublicAPIKeyCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestIssuePublicAPIKeySQLStoreIssueAPIKey_ScanError(t *testing.T) {
	db := &publicAPIKeyIssuerQueryRowProviderMock{
		row: &publicAPIKeyIssuerRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewIssuePublicAPIKeySQLStore(db)

	_, err := store.IssueAPIKey(context.Background(), IssuePublicAPIKeyCommand{
		TenantID:       "tenant-a",
		AppID:          "app-001",
		KeyName:        "erp-main-key",
		Environment:    "production",
		Scopes:         []string{"erp.read"},
		KeyPrefix:      "pix_live",
		KeyHash:        "hash-001",
		KeyFingerprint: "fingerprint-001",
		KeyPreview:     "pix_live...abcd",
		RequestedBy:    "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
