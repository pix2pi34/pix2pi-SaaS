package idempotency

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

type FinalizeIdempotencyKeyCommand struct {
	TenantID       string
	ScopeKey       string
	IdempotencyKey string
	RequestHash    string
	ResultRef      string
	FinalStatus    string
	RequestedBy    string
}

type FinalizeIdempotencyKeyResult struct {
	ReservationID string
	ResultRef     string
	FinalStatus   string
}

type FinalizeIdempotencyKeyStore interface {
	FinalizeKey(ctx context.Context, cmd FinalizeIdempotencyKeyCommand) (FinalizeIdempotencyKeyResult, error)
}

type FinalizeIdempotencyKeyUsecase struct {
	store FinalizeIdempotencyKeyStore
	nowFn func() time.Time
}

func NewFinalizeIdempotencyKeyUsecase(store FinalizeIdempotencyKeyStore) *FinalizeIdempotencyKeyUsecase {
	return &FinalizeIdempotencyKeyUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *FinalizeIdempotencyKeyUsecase) Finalize(ctx context.Context, req FinalizeIdempotencyKeyRequest) (FinalizeIdempotencyKeyResponse, error) {
	if u == nil || u.store == nil {
		return FinalizeIdempotencyKeyResponse{}, errors.New("finalize idempotency usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.ScopeKey = strings.TrimSpace(req.ScopeKey)
	req.IdempotencyKey = strings.TrimSpace(req.IdempotencyKey)
	req.RequestHash = strings.TrimSpace(req.RequestHash)
	req.ResultRef = strings.TrimSpace(req.ResultRef)
	req.FinalStatus = strings.TrimSpace(req.FinalStatus)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return FinalizeIdempotencyKeyResponse{}, err
	}

	result, err := u.store.FinalizeKey(ctx, FinalizeIdempotencyKeyCommand{
		TenantID:       req.TenantID,
		ScopeKey:       req.ScopeKey,
		IdempotencyKey: req.IdempotencyKey,
		RequestHash:    req.RequestHash,
		ResultRef:      req.ResultRef,
		FinalStatus:    req.FinalStatus,
		RequestedBy:    req.RequestedBy,
	})
	if err != nil {
		return FinalizeIdempotencyKeyResponse{}, err
	}

	reservationID := strings.TrimSpace(result.ReservationID)
	if reservationID == "" {
		reservationID = uuid.NewString()
	}

	resp := FinalizeIdempotencyKeyResponse{
		ReservationID:  reservationID,
		ScopeKey:       req.ScopeKey,
		IdempotencyKey: req.IdempotencyKey,
		RequestHash:    req.RequestHash,
		ResultRef:      firstNonEmpty(strings.TrimSpace(result.ResultRef), req.ResultRef),
		FinalStatus:    firstNonEmpty(strings.TrimSpace(result.FinalStatus), req.FinalStatus),
		BoundAt:        u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return FinalizeIdempotencyKeyResponse{}, err
	}

	return resp, nil
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if strings.TrimSpace(v) != "" {
			return v
		}
	}
	return ""
}
