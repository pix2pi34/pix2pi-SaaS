package publicapi

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type publicAPIDocsPublisherRowMock struct {
	values []any
	err    error
}

func (r *publicAPIDocsPublisherRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *bool:
			*d = r.values[i].(bool)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type publicAPIDocsPublisherQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *publicAPIDocsPublisherQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestPublishDeveloperDocsSQLStorePublishDocs_Success(t *testing.T) {
	db := &publicAPIDocsPublisherQueryRowProviderMock{
		row: &publicAPIDocsPublisherRowMock{
			values: []any{
				"docs-001",
				"app-001",
				"v1",
				"production",
				"openapi",
				"openapi-v1",
				"/docs/v1",
				"https://developer.pix2pi.com.tr/docs/v1",
				"published",
				true,
				"",
			},
		},
	}

	store := NewPublishDeveloperDocsSQLStore(db)

	result, err := store.PublishDocs(context.Background(), PublishDeveloperDocsCommand{
		TenantID:    "tenant-a",
		AppID:       "app-001",
		DocsVersion: "v1",
		Environment: "production",
		DocsFormat:  "openapi",
		SourceRef:   "openapi-v1",
		TargetPath:  "/docs/v1",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.DocsID != "docs-001" {
		t.Fatalf("beklenen docs_id docs-001, alinan: %s", result.DocsID)
	}

	if result.AppID != "app-001" {
		t.Fatalf("beklenen app_id app-001, alinan: %s", result.AppID)
	}

	if result.DocsVersion != "v1" {
		t.Fatalf("beklenen docs_version v1, alinan: %s", result.DocsVersion)
	}

	if result.Environment != "production" {
		t.Fatalf("beklenen environment production, alinan: %s", result.Environment)
	}

	if result.DocsFormat != "openapi" {
		t.Fatalf("beklenen docs_format openapi, alinan: %s", result.DocsFormat)
	}

	if result.SourceRef != "openapi-v1" {
		t.Fatalf("beklenen source_ref openapi-v1, alinan: %s", result.SourceRef)
	}

	if result.TargetPath != "/docs/v1" {
		t.Fatalf("beklenen target_path /docs/v1, alinan: %s", result.TargetPath)
	}

	if result.PublicURL != "https://developer.pix2pi.com.tr/docs/v1" {
		t.Fatalf("beklenen public_url korunmaliydi, alinan: %s", result.PublicURL)
	}

	if result.PublishStatus != "published" {
		t.Fatalf("beklenen publish_status published, alinan: %s", result.PublishStatus)
	}

	if !result.Published {
		t.Fatalf("beklenen published true")
	}

	if result.DenialReason != "" {
		t.Fatalf("published durumda denial_reason bos olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.public_api_docs") {
		t.Fatalf("public_api_docs query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "ON CONFLICT (app_id, docs_version, environment, docs_format)") {
		t.Fatalf("docs publish conflict handling query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "publish_status") {
		t.Fatalf("publish_status query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "public_url") {
		t.Fatalf("public_url query icinde olmaliydi")
	}

	if len(db.lastArgs) != 9 {
		t.Fatalf("beklenen 9 arguman, alinan: %d", len(db.lastArgs))
	}

	if db.lastArgs[7] != "https://developer.pix2pi.com.tr/docs/v1" {
		t.Fatalf("public_url fallback argumani beklenenden farkli: %v", db.lastArgs[7])
	}
}

func TestPublishDeveloperDocsSQLStorePublishDocs_NormalizeTargetPathSuccess(t *testing.T) {
	db := &publicAPIDocsPublisherQueryRowProviderMock{
		row: &publicAPIDocsPublisherRowMock{
			values: []any{
				"docs-002",
				"app-002",
				"v1",
				"sandbox",
				"portal",
				"portal-v1",
				"/docs/v1",
				"https://sandbox-developer.pix2pi.com.tr/docs/v1",
				"published",
				true,
				"",
			},
		},
	}

	store := NewPublishDeveloperDocsSQLStore(db)

	result, err := store.PublishDocs(context.Background(), PublishDeveloperDocsCommand{
		AppID:       "app-002",
		DocsVersion: "v1",
		Environment: "sandbox",
		DocsFormat:  "portal",
		SourceRef:   "portal-v1",
		TargetPath:  "docs/v1",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.TargetPath != "/docs/v1" {
		t.Fatalf("beklenen normalize target_path /docs/v1, alinan: %s", result.TargetPath)
	}

	if db.lastArgs[6] != "/docs/v1" {
		t.Fatalf("query arg target_path normalize olmaliydi, alinan: %v", db.lastArgs[6])
	}

	if db.lastArgs[7] != "https://sandbox-developer.pix2pi.com.tr/docs/v1" {
		t.Fatalf("sandbox public_url fallback beklenenden farkli: %v", db.lastArgs[7])
	}
}

func TestPublishDeveloperDocsSQLStorePublishDocs_NoDB(t *testing.T) {
	store := NewPublishDeveloperDocsSQLStore(nil)

	_, err := store.PublishDocs(context.Background(), PublishDeveloperDocsCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestPublishDeveloperDocsSQLStorePublishDocs_ScanError(t *testing.T) {
	db := &publicAPIDocsPublisherQueryRowProviderMock{
		row: &publicAPIDocsPublisherRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewPublishDeveloperDocsSQLStore(db)

	_, err := store.PublishDocs(context.Background(), PublishDeveloperDocsCommand{
		TenantID:    "tenant-a",
		AppID:       "app-001",
		DocsVersion: "v1",
		Environment: "production",
		DocsFormat:  "openapi",
		SourceRef:   "openapi-v1",
		TargetPath:  "/docs/v1",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
