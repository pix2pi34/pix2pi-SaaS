package publicapi

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"
)

type PublishDeveloperDocsCommand struct {
	TenantID    string
	AppID       string
	DocsVersion string
	Environment string
	DocsFormat  string
	SourceRef   string
	TargetPath  string
	RequestedBy string
}

type PublishDeveloperDocsResult struct {
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

type PublicAPIDocsPublisherStore interface {
	PublishDocs(ctx context.Context, cmd PublishDeveloperDocsCommand) (PublishDeveloperDocsResult, error)
}

type PublishDeveloperDocsUsecase struct {
	store PublicAPIDocsPublisherStore
	nowFn func() time.Time
}

func NewPublishDeveloperDocsUsecase(store PublicAPIDocsPublisherStore) *PublishDeveloperDocsUsecase {
	return &PublishDeveloperDocsUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *PublishDeveloperDocsUsecase) Publish(ctx context.Context, req PublishDeveloperDocsRequest) (PublishDeveloperDocsResponse, error) {
	if u == nil || u.store == nil {
		return PublishDeveloperDocsResponse{}, errors.New("public api docs publisher usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.AppID = strings.TrimSpace(req.AppID)
	req.DocsVersion = strings.TrimSpace(req.DocsVersion)
	req.Environment = strings.TrimSpace(req.Environment)
	req.DocsFormat = strings.TrimSpace(req.DocsFormat)
	req.SourceRef = strings.TrimSpace(req.SourceRef)
	req.TargetPath = normalizePublicAPIPath(req.TargetPath)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return PublishDeveloperDocsResponse{}, err
	}

	result, err := u.store.PublishDocs(ctx, PublishDeveloperDocsCommand{
		TenantID:    req.TenantID,
		AppID:       req.AppID,
		DocsVersion: req.DocsVersion,
		Environment: req.Environment,
		DocsFormat:  req.DocsFormat,
		SourceRef:   req.SourceRef,
		TargetPath:  req.TargetPath,
		RequestedBy: req.RequestedBy,
	})
	if err != nil {
		return PublishDeveloperDocsResponse{}, err
	}

	status := firstNonEmpty(strings.TrimSpace(result.PublishStatus), "published")
	published := result.Published
	denialReason := strings.TrimSpace(result.DenialReason)

	if status == "published" {
		published = true
		denialReason = ""
	}

	if status == "blocked" {
		published = false
		if denialReason == "" {
			denialReason = "developer docs publish blocked"
		}
	}

	resp := PublishDeveloperDocsResponse{
		DocsID:        firstNonEmpty(strings.TrimSpace(result.DocsID), buildFallbackPublicAPIDocsID(req.AppID, req.DocsVersion)),
		AppID:         firstNonEmpty(strings.TrimSpace(result.AppID), req.AppID),
		DocsVersion:   firstNonEmpty(strings.TrimSpace(result.DocsVersion), req.DocsVersion),
		Environment:   firstNonEmpty(strings.TrimSpace(result.Environment), req.Environment),
		DocsFormat:    firstNonEmpty(strings.TrimSpace(result.DocsFormat), req.DocsFormat),
		SourceRef:     firstNonEmpty(strings.TrimSpace(result.SourceRef), req.SourceRef),
		TargetPath:    firstNonEmpty(normalizePublicAPIPath(result.TargetPath), req.TargetPath),
		PublicURL:     strings.TrimSpace(result.PublicURL),
		PublishStatus: status,
		Published:     published,
		DenialReason:  denialReason,
		PublishedAt:   u.nowFn().UTC(),
	}

	if resp.Published && resp.PublicURL == "" {
		resp.PublicURL = buildFallbackPublicAPIDocsURL(resp.Environment, resp.TargetPath)
	}

	if err := resp.Validate(); err != nil {
		return PublishDeveloperDocsResponse{}, err
	}

	return resp, nil
}

func buildFallbackPublicAPIDocsID(appID, docsVersion string) string {
	seed := fmt.Sprintf("%s:%s", strings.TrimSpace(appID), strings.TrimSpace(docsVersion))
	sum := sha256.Sum256([]byte(seed))
	return "docs-" + hex.EncodeToString(sum[:])[:12]
}

func buildFallbackPublicAPIDocsURL(environment, targetPath string) string {
	environment = strings.TrimSpace(environment)
	targetPath = normalizePublicAPIPath(targetPath)

	if environment == "production" {
		return "https://developer.pix2pi.com.tr" + targetPath
	}

	return "https://sandbox-developer.pix2pi.com.tr" + targetPath
}
