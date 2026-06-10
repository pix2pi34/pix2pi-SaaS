package idempotency

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

type ReserveDedupeRecordCommand struct {
	TenantID    string
	ScopeKey    string
	RecordKey   string
	PayloadHash string
	TTLSeconds  int
	RequestedBy string
}

type ReserveDedupeRecordResult struct {
	RecordID         string
	Status           string
	ExistingValueRef string
	ExpiresAt        *time.Time
}

type ReserveDedupeRecordStore interface {
	ReserveOrCheckRecord(ctx context.Context, cmd ReserveDedupeRecordCommand) (ReserveDedupeRecordResult, error)
}

type ReserveDedupeRecordUsecase struct {
	store ReserveDedupeRecordStore
	nowFn func() time.Time
}

func NewReserveDedupeRecordUsecase(store ReserveDedupeRecordStore) *ReserveDedupeRecordUsecase {
	return &ReserveDedupeRecordUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *ReserveDedupeRecordUsecase) ReserveOrCheck(ctx context.Context, req ReserveDedupeRecordRequest) (ReserveDedupeRecordResponse, error) {
	if u == nil || u.store == nil {
		return ReserveDedupeRecordResponse{}, errors.New("reserve dedupe usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.ScopeKey = strings.TrimSpace(req.ScopeKey)
	req.RecordKey = strings.TrimSpace(req.RecordKey)
	req.PayloadHash = strings.TrimSpace(req.PayloadHash)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return ReserveDedupeRecordResponse{}, err
	}

	now := u.nowFn().UTC()

	result, err := u.store.ReserveOrCheckRecord(ctx, ReserveDedupeRecordCommand{
		TenantID:    req.TenantID,
		ScopeKey:    req.ScopeKey,
		RecordKey:   req.RecordKey,
		PayloadHash: req.PayloadHash,
		TTLSeconds:  req.TTLSeconds,
		RequestedBy: req.RequestedBy,
	})
	if err != nil {
		return ReserveDedupeRecordResponse{}, err
	}

	recordID := strings.TrimSpace(result.RecordID)
	if recordID == "" {
		recordID = uuid.NewString()
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

	resp := ReserveDedupeRecordResponse{
		RecordID:         recordID,
		ScopeKey:         req.ScopeKey,
		RecordKey:        req.RecordKey,
		PayloadHash:      req.PayloadHash,
		Status:           status,
		ExistingValueRef: strings.TrimSpace(result.ExistingValueRef),
		ExpiresAt:        expiresAt.UTC(),
		ReservedAt:       now,
	}

	if err := resp.Validate(); err != nil {
		return ReserveDedupeRecordResponse{}, err
	}

	return resp, nil
}
