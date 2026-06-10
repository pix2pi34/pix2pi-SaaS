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

type EnsurePublicAPISandboxCommand struct {
	TenantID    string
	AppID       string
	Environment string
	SandboxName string
	DataMode    string
	RequestedBy string
}

type EnsurePublicAPISandboxResult struct {
	SandboxID     string
	AppID         string
	Environment   string
	SandboxName   string
	DataMode      string
	BaseURL       string
	Isolated      bool
	SandboxStatus string
	Ready         bool
	DenialReason  string
}

type PublicAPISandboxStore interface {
	EnsureSandbox(ctx context.Context, cmd EnsurePublicAPISandboxCommand) (EnsurePublicAPISandboxResult, error)
}

type EnsurePublicAPISandboxUsecase struct {
	store PublicAPISandboxStore
	nowFn func() time.Time
}

func NewEnsurePublicAPISandboxUsecase(store PublicAPISandboxStore) *EnsurePublicAPISandboxUsecase {
	return &EnsurePublicAPISandboxUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *EnsurePublicAPISandboxUsecase) Ensure(ctx context.Context, req EnsurePublicAPISandboxRequest) (EnsurePublicAPISandboxResponse, error) {
	if u == nil || u.store == nil {
		return EnsurePublicAPISandboxResponse{}, errors.New("public api sandbox usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.AppID = strings.TrimSpace(req.AppID)
	req.Environment = strings.TrimSpace(req.Environment)
	req.SandboxName = strings.TrimSpace(req.SandboxName)
	req.DataMode = strings.TrimSpace(req.DataMode)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return EnsurePublicAPISandboxResponse{}, err
	}

	result, err := u.store.EnsureSandbox(ctx, EnsurePublicAPISandboxCommand{
		TenantID:    req.TenantID,
		AppID:       req.AppID,
		Environment: req.Environment,
		SandboxName: req.SandboxName,
		DataMode:    req.DataMode,
		RequestedBy: req.RequestedBy,
	})
	if err != nil {
		return EnsurePublicAPISandboxResponse{}, err
	}

	status := firstNonEmpty(strings.TrimSpace(result.SandboxStatus), "ready")
	ready := result.Ready
	denialReason := strings.TrimSpace(result.DenialReason)

	if status == "ready" {
		ready = true
		denialReason = ""
	}

	if status == "blocked" {
		ready = false
		if denialReason == "" {
			denialReason = "sandbox provisioning blocked"
		}
	}

	resp := EnsurePublicAPISandboxResponse{
		SandboxID:     firstNonEmpty(strings.TrimSpace(result.SandboxID), buildFallbackPublicAPISandboxID(req.AppID, req.SandboxName)),
		AppID:         firstNonEmpty(strings.TrimSpace(result.AppID), req.AppID),
		Environment:   firstNonEmpty(strings.TrimSpace(result.Environment), req.Environment),
		SandboxName:   firstNonEmpty(strings.TrimSpace(result.SandboxName), req.SandboxName),
		DataMode:      firstNonEmpty(strings.TrimSpace(result.DataMode), req.DataMode),
		BaseURL:       firstNonEmpty(strings.TrimSpace(result.BaseURL), buildFallbackPublicAPISandboxBaseURL(req.AppID, req.SandboxName)),
		Isolated:      result.Isolated,
		SandboxStatus: status,
		Ready:         ready,
		DenialReason:  denialReason,
		ProvisionedAt: u.nowFn().UTC(),
	}

	if resp.Ready && !resp.Isolated {
		resp.Isolated = true
	}

	if err := resp.Validate(); err != nil {
		return EnsurePublicAPISandboxResponse{}, err
	}

	return resp, nil
}

func buildFallbackPublicAPISandboxID(appID, sandboxName string) string {
	seed := fmt.Sprintf("%s:%s", strings.TrimSpace(appID), strings.TrimSpace(sandboxName))
	sum := sha256.Sum256([]byte(seed))
	return "sandbox-" + hex.EncodeToString(sum[:])[:12]
}

func buildFallbackPublicAPISandboxBaseURL(appID, sandboxName string) string {
	appID = strings.TrimSpace(appID)
	sandboxName = strings.TrimSpace(sandboxName)
	if appID == "" {
		appID = "app"
	}
	if sandboxName == "" {
		sandboxName = "default"
	}
	return "https://sandbox.pix2pi.com.tr/" + appID + "/" + sandboxName
}
