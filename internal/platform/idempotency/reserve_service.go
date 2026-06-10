package idempotency

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

type ReserveIdempotencyKeyCommand struct {
	TenantID       string
	ScopeKey       string
	IdempotencyKey string
	RequestHash    string
	TTLSeconds     int
	RequestedBy    string
}

type ReserveIdempotencyKeyResult struct {
	ReservationID     string
	Status            string
	ExistingResultRef string
	ExpiresAt         *time.Time
}

type ReserveIdempotencyKeyStore interface {
	ReserveOrCheckKey(ctx context.Context, cmd ReserveIdempotencyKeyCommand) (ReserveIdempotencyKeyResult, error)
}

type ReserveIdempotencyKeyUsecase struct {
	store ReserveIdempotencyKeyStore
	nowFn func() time.Time
}

func NewReserveIdempotencyKeyUsecase(store ReserveIdempotencyKeyStore) *ReserveIdempotencyKeyUsecase {
	return &ReserveIdempotencyKeyUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *ReserveIdempotencyKeyUsecase) ReserveOrCheck(ctx context.Context, req ReserveIdempotencyKeyRequest) (ReserveIdempotencyKeyResponse, error) {
	if u == nil || u.store == nil {
		return ReserveIdempotencyKeyResponse{}, errors.New("reserve idempotency usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.ScopeKey = strings.TrimSpace(req.ScopeKey)
	req.IdempotencyKey = strings.TrimSpace(req.IdempotencyKey)
	req.RequestHash = strings.TrimSpace(req.RequestHash)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return ReserveIdempotencyKeyResponse{}, err
	}

	now := u.nowFn().UTC()

	result, err := u.store.ReserveOrCheckKey(ctx, ReserveIdempotencyKeyCommand{
		TenantID:       req.TenantID,
		ScopeKey:       req.ScopeKey,
		IdempotencyKey: req.IdempotencyKey,
		RequestHash:    req.RequestHash,
		TTLSeconds:     req.TTLSeconds,
		RequestedBy:    req.RequestedBy,
	})
	if err != nil {
		return ReserveIdempotencyKeyResponse{}, err
	}

	reservationID := strings.TrimSpace(result.ReservationID)
	if reservationID == "" {
		reservationID = uuid.NewString()
	}

	status := strings.TrimSpace(result.Status)
	if status == "" {
		status = "reserved"
	}

	expiresAt := cloneTimePtr(result.ExpiresAt)
	if expiresAt == nil {
		t := now.Add(time.Duration(req.TTLSeconds) * time.Second)
		expiresAt = &t
	}

	resp := ReserveIdempotencyKeyResponse{
		ReservationID:     reservationID,
		ScopeKey:          req.ScopeKey,
		IdempotencyKey:    req.IdempotencyKey,
		RequestHash:       req.RequestHash,
		Status:            status,
		ExistingResultRef: strings.TrimSpace(result.ExistingResultRef),
		ExpiresAt:         expiresAt.UTC(),
		ReservedAt:        now,
	}

	if err := resp.Validate(); err != nil {
		return ReserveIdempotencyKeyResponse{}, err
	}

	return resp, nil
}

func cloneTimePtr(in *time.Time) *time.Time {
	if in == nil {
		return nil
	}

	t := in.UTC()
	return &t
}
