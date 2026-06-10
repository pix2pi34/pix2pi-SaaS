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

type IssuePublicAPIKeyCommand struct {
	TenantID       string
	AppID          string
	KeyName        string
	Environment    string
	Scopes         []string
	KeyPrefix      string
	KeyHash        string
	KeyFingerprint string
	KeyPreview     string
	ExpiresAt      *time.Time
	RequestedBy    string
}

type IssuePublicAPIKeyResult struct {
	APIKeyID       string
	AppID          string
	KeyName        string
	Environment    string
	Scopes         []string
	KeyPrefix      string
	KeyPreview     string
	KeyFingerprint string
	Status         string
	Issued         bool
	ExpiresAt      *time.Time
}

type PublicAPIKeyIssuerStore interface {
	IssueAPIKey(ctx context.Context, cmd IssuePublicAPIKeyCommand) (IssuePublicAPIKeyResult, error)
}

type IssuePublicAPIKeyUsecase struct {
	store PublicAPIKeyIssuerStore
	nowFn func() time.Time
	secretFn func(req IssuePublicAPIKeyRequest, issuedAt time.Time) string
}

func NewIssuePublicAPIKeyUsecase(store PublicAPIKeyIssuerStore) *IssuePublicAPIKeyUsecase {
	return &IssuePublicAPIKeyUsecase{
		store: store,
		nowFn: time.Now,
		secretFn: defaultPublicAPIKeySecret,
	}
}

func (u *IssuePublicAPIKeyUsecase) Issue(ctx context.Context, req IssuePublicAPIKeyRequest) (IssuePublicAPIKeyResponse, error) {
	if u == nil || u.store == nil {
		return IssuePublicAPIKeyResponse{}, errors.New("public api key issuer usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.AppID = strings.TrimSpace(req.AppID)
	req.KeyName = strings.TrimSpace(req.KeyName)
	req.Environment = strings.TrimSpace(req.Environment)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)
	req.Scopes = normalizePublicAPIKeyScopes(req.Scopes)
	req.ExpiresAt = clonePublicAPITimePtr(req.ExpiresAt)

	if err := req.Validate(); err != nil {
		return IssuePublicAPIKeyResponse{}, err
	}

	issuedAt := u.nowFn().UTC()
	rawSecret := u.secretFn(req, issuedAt)
	keyHash := hashPublicAPIKeySecret(rawSecret)
	keyPrefix := resolvePublicAPIKeyPrefix(req.Environment)
	keyPreview := previewPublicAPIKeySecret(rawSecret)
	keyFingerprint := fingerprintPublicAPIKeySecret(rawSecret)

	result, err := u.store.IssueAPIKey(ctx, IssuePublicAPIKeyCommand{
		TenantID:       req.TenantID,
		AppID:          req.AppID,
		KeyName:        req.KeyName,
		Environment:    req.Environment,
		Scopes:         cloneStringSlice(req.Scopes),
		KeyPrefix:      keyPrefix,
		KeyHash:        keyHash,
		KeyFingerprint: keyFingerprint,
		KeyPreview:     keyPreview,
		ExpiresAt:      clonePublicAPITimePtr(req.ExpiresAt),
		RequestedBy:    req.RequestedBy,
	})
	if err != nil {
		return IssuePublicAPIKeyResponse{}, err
	}

	resp := IssuePublicAPIKeyResponse{
		APIKeyID:       firstNonEmpty(strings.TrimSpace(result.APIKeyID), buildFallbackPublicAPIKeyID(req.AppID, issuedAt)),
		AppID:          firstNonEmpty(strings.TrimSpace(result.AppID), req.AppID),
		KeyName:        firstNonEmpty(strings.TrimSpace(result.KeyName), req.KeyName),
		Environment:    firstNonEmpty(strings.TrimSpace(result.Environment), req.Environment),
		Scopes:         firstNonEmptyStringSlice(result.Scopes, req.Scopes),
		KeyPrefix:      firstNonEmpty(strings.TrimSpace(result.KeyPrefix), keyPrefix),
		KeyPreview:     firstNonEmpty(strings.TrimSpace(result.KeyPreview), keyPreview),
		KeyFingerprint: firstNonEmpty(strings.TrimSpace(result.KeyFingerprint), keyFingerprint),
		Status:         firstNonEmpty(strings.TrimSpace(result.Status), "active"),
		Issued:         result.Issued,
		ExpiresAt:      clonePublicAPITimePtr(result.ExpiresAt),
		IssuedAt:       issuedAt,
	}

	if len(resp.Scopes) == 0 {
		resp.Scopes = cloneStringSlice(req.Scopes)
	}

	if resp.ExpiresAt == nil {
		resp.ExpiresAt = clonePublicAPITimePtr(req.ExpiresAt)
	}

	if !resp.Issued {
		resp.Issued = true
	}

	if err := resp.Validate(); err != nil {
		return IssuePublicAPIKeyResponse{}, err
	}

	return resp, nil
}

func normalizePublicAPIKeyScopes(scopes []string) []string {
	out := make([]string, 0, len(scopes))
	for _, scope := range scopes {
		scope = strings.TrimSpace(scope)
		if scope != "" {
			out = append(out, scope)
		}
	}
	return out
}

func defaultPublicAPIKeySecret(req IssuePublicAPIKeyRequest, issuedAt time.Time) string {
	base := fmt.Sprintf("%s:%s:%s:%d", req.AppID, req.KeyName, req.Environment, issuedAt.UnixNano())
	sum := sha256.Sum256([]byte(base))
	return resolvePublicAPIKeyPrefix(req.Environment) + "_" + hex.EncodeToString(sum[:])
}

func resolvePublicAPIKeyPrefix(environment string) string {
	if strings.TrimSpace(environment) == "production" {
		return "pix_live"
	}
	return "pix_test"
}

func hashPublicAPIKeySecret(secret string) string {
	sum := sha256.Sum256([]byte(strings.TrimSpace(secret)))
	return hex.EncodeToString(sum[:])
}

func fingerprintPublicAPIKeySecret(secret string) string {
	hash := hashPublicAPIKeySecret(secret)
	if len(hash) <= 16 {
		return hash
	}
	return hash[:16]
}

func previewPublicAPIKeySecret(secret string) string {
	secret = strings.TrimSpace(secret)
	if len(secret) <= 12 {
		return secret
	}
	return secret[:8] + "..." + secret[len(secret)-4:]
}

func buildFallbackPublicAPIKeyID(appID string, issuedAt time.Time) string {
	seed := fmt.Sprintf("%s:%d", strings.TrimSpace(appID), issuedAt.UnixNano())
	sum := sha256.Sum256([]byte(seed))
	return "key-" + hex.EncodeToString(sum[:])[:12]
}

func clonePublicAPITimePtr(in *time.Time) *time.Time {
	if in == nil {
		return nil
	}

	t := in.UTC()
	return &t
}

func cloneStringSlice(in []string) []string {
	if len(in) == 0 {
		return []string{}
	}

	out := make([]string, len(in))
	copy(out, in)
	return out
}

func firstNonEmptyStringSlice(values ...[]string) []string {
	for _, v := range values {
		if len(v) > 0 {
			return cloneStringSlice(v)
		}
	}
	return []string{}
}
