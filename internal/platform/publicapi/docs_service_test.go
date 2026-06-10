package publicapi

import (
	"context"
	"errors"
	"testing"
	"time"
)

type publicAPIDocsPublisherStoreMock struct {
	lastCmd PublishDeveloperDocsCommand
	result  PublishDeveloperDocsResult
	err     error
	called  bool
}

func (m *publicAPIDocsPublisherStoreMock) PublishDocs(_ context.Context, cmd PublishDeveloperDocsCommand) (PublishDeveloperDocsResult, error) {
	m.called = true
	m.lastCmd = cmd
	return m.result, m.err
}

func TestPublishDeveloperDocsRequestValidate_Success(t *testing.T) {
	req := PublishDeveloperDocsRequest{
		TenantID:    "tenant-a",
		AppID:       "app-001",
		DocsVersion: "v1",
		Environment: "production",
		DocsFormat:  "openapi",
		SourceRef:   "openapi-v1",
		TargetPath:  "/docs/v1",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err != nil {
		t.Fatalf("beklenen validation success, alinan hata: %v", err)
	}
}

func TestPublishDeveloperDocsRequestValidate_InvalidEnvironment(t *testing.T) {
	req := PublishDeveloperDocsRequest{
		AppID:       "app-001",
		DocsVersion: "v1",
		Environment: "staging",
		DocsFormat:  "openapi",
		SourceRef:   "openapi-v1",
		TargetPath:  "/docs/v1",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestPublishDeveloperDocsRequestValidate_InvalidDocsFormat(t *testing.T) {
	req := PublishDeveloperDocsRequest{
		AppID:       "app-001",
		DocsVersion: "v1",
		Environment: "sandbox",
		DocsFormat:  "pdf",
		SourceRef:   "openapi-v1",
		TargetPath:  "/docs/v1",
		RequestedBy: "worker-01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestPublishDeveloperDocsRequestValidate_InvalidRequestedBy(t *testing.T) {
	req := PublishDeveloperDocsRequest{
		AppID:       "app-001",
		DocsVersion: "v1",
		Environment: "sandbox",
		DocsFormat:  "openapi",
		SourceRef:   "openapi-v1",
		TargetPath:  "/docs/v1",
		RequestedBy: "worker 01",
	}

	if err := req.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}

func TestPublishDeveloperDocsUsecasePublish_Success(t *testing.T) {
	store := &publicAPIDocsPublisherStoreMock{
		result: PublishDeveloperDocsResult{
			DocsID:        "docs-001",
			AppID:         "app-001",
			DocsVersion:   "v1",
			Environment:   "production",
			DocsFormat:    "openapi",
			SourceRef:     "openapi-v1",
			TargetPath:    "/docs/v1",
			PublicURL:     "https://developer.pix2pi.com.tr/docs/v1",
			PublishStatus: "published",
			Published:     true,
		},
	}

	usecase := NewPublishDeveloperDocsUsecase(store)
	usecase.nowFn = func() time.Time {
		return time.Date(2026, 4, 26, 17, 30, 0, 0, time.UTC)
	}

	resp, err := usecase.Publish(context.Background(), PublishDeveloperDocsRequest{
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

	if !store.called {
		t.Fatalf("store cagrilmadi")
	}

	if store.lastCmd.TargetPath != "/docs/v1" {
		t.Fatalf("beklenen target_path /docs/v1, alinan: %s", store.lastCmd.TargetPath)
	}

	if !resp.Published {
		t.Fatalf("beklenen published true")
	}

	if resp.PublishStatus != "published" {
		t.Fatalf("beklenen publish_status published, alinan: %s", resp.PublishStatus)
	}

	if resp.PublicURL != "https://developer.pix2pi.com.tr/docs/v1" {
		t.Fatalf("beklenen public_url korunmaliydi, alinan: %s", resp.PublicURL)
	}

	if !resp.PublishedAt.Equal(time.Date(2026, 4, 26, 17, 30, 0, 0, time.UTC)) {
		t.Fatalf("beklenen published_at sabit zaman")
	}
}

func TestPublishDeveloperDocsUsecasePublish_FallbackSuccess(t *testing.T) {
	store := &publicAPIDocsPublisherStoreMock{
		result: PublishDeveloperDocsResult{},
	}

	usecase := NewPublishDeveloperDocsUsecase(store)

	resp, err := usecase.Publish(context.Background(), PublishDeveloperDocsRequest{
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

	if resp.DocsID == "" {
		t.Fatalf("fallback docs_id dolu olmaliydi")
	}

	if !resp.Published {
		t.Fatalf("fallback published true olmaliydi")
	}

	if resp.PublicURL != "https://sandbox-developer.pix2pi.com.tr/docs/v1" {
		t.Fatalf("beklenen sandbox fallback public_url, alinan: %s", resp.PublicURL)
	}

	if resp.TargetPath != "/docs/v1" {
		t.Fatalf("target_path normalize olmaliydi, alinan: %s", resp.TargetPath)
	}
}

func TestPublishDeveloperDocsUsecasePublish_BlockedSuccess(t *testing.T) {
	store := &publicAPIDocsPublisherStoreMock{
		result: PublishDeveloperDocsResult{
			DocsID:        "docs-003",
			AppID:         "app-003",
			DocsVersion:   "v1",
			Environment:   "sandbox",
			DocsFormat:    "markdown",
			SourceRef:     "markdown-v1",
			TargetPath:    "/docs/v1",
			PublishStatus: "blocked",
			Published:     false,
			DenialReason:  "docs validation failed",
		},
	}

	usecase := NewPublishDeveloperDocsUsecase(store)

	resp, err := usecase.Publish(context.Background(), PublishDeveloperDocsRequest{
		AppID:       "app-003",
		DocsVersion: "v1",
		Environment: "sandbox",
		DocsFormat:  "markdown",
		SourceRef:   "markdown-v1",
		TargetPath:  "/docs/v1",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if resp.Published {
		t.Fatalf("blocked durumda published false olmali")
	}

	if resp.PublishStatus != "blocked" {
		t.Fatalf("beklenen publish_status blocked, alinan: %s", resp.PublishStatus)
	}

	if resp.DenialReason == "" {
		t.Fatalf("blocked durumda denial_reason dolu olmali")
	}
}

func TestPublishDeveloperDocsUsecasePublish_ValidationError(t *testing.T) {
	store := &publicAPIDocsPublisherStoreMock{}
	usecase := NewPublishDeveloperDocsUsecase(store)

	_, err := usecase.Publish(context.Background(), PublishDeveloperDocsRequest{
		AppID:       "app-001",
		DocsVersion: "v1",
		Environment: "sandbox",
		DocsFormat:  "pdf",
		SourceRef:   "openapi-v1",
		TargetPath:  "/docs/v1",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen validation hatasi")
	}

	if store.called {
		t.Fatalf("validation hatasinda store cagrilmamaliydi")
	}
}

func TestPublishDeveloperDocsUsecasePublish_StoreError(t *testing.T) {
	store := &publicAPIDocsPublisherStoreMock{
		err: errors.New("publish docs failed"),
	}

	usecase := NewPublishDeveloperDocsUsecase(store)

	_, err := usecase.Publish(context.Background(), PublishDeveloperDocsRequest{
		AppID:       "app-001",
		DocsVersion: "v1",
		Environment: "sandbox",
		DocsFormat:  "openapi",
		SourceRef:   "openapi-v1",
		TargetPath:  "/docs/v1",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen store hatasi")
	}
}

func TestPublishDeveloperDocsResponseValidate_InvalidPublishedAt(t *testing.T) {
	resp := PublishDeveloperDocsResponse{
		DocsID:        "docs-001",
		AppID:         "app-001",
		DocsVersion:   "v1",
		Environment:   "sandbox",
		DocsFormat:    "openapi",
		SourceRef:     "openapi-v1",
		TargetPath:    "/docs/v1",
		PublicURL:     "https://sandbox-developer.pix2pi.com.tr/docs/v1",
		PublishStatus: "published",
		Published:     true,
	}

	if err := resp.Validate(); err == nil {
		t.Fatalf("beklenen validation hatasi")
	}
}
