package idempotency

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/google/uuid"
)

type FinalizeDedupeRecordCommand struct {
	TenantID    string
	ScopeKey    string
	RecordKey   string
	PayloadHash string
	ValueRef    string
	FinalStatus string
	RequestedBy string
}

type FinalizeDedupeRecordResult struct {
	RecordID    string
	ValueRef    string
	FinalStatus string
}

type FinalizeDedupeRecordStore interface {
	FinalizeRecord(ctx context.Context, cmd FinalizeDedupeRecordCommand) (FinalizeDedupeRecordResult, error)
}

type FinalizeDedupeRecordUsecase struct {
	store FinalizeDedupeRecordStore
	nowFn func() time.Time
}

func NewFinalizeDedupeRecordUsecase(store FinalizeDedupeRecordStore) *FinalizeDedupeRecordUsecase {
	return &FinalizeDedupeRecordUsecase{
		store: store,
		nowFn: time.Now,
	}
}

func (u *FinalizeDedupeRecordUsecase) Finalize(ctx context.Context, req FinalizeDedupeRecordRequest) (FinalizeDedupeRecordResponse, error) {
	if u == nil || u.store == nil {
		return FinalizeDedupeRecordResponse{}, errors.New("finalize dedupe usecase hazir degil")
	}

	req.TenantID = strings.TrimSpace(req.TenantID)
	req.ScopeKey = strings.TrimSpace(req.ScopeKey)
	req.RecordKey = strings.TrimSpace(req.RecordKey)
	req.PayloadHash = strings.TrimSpace(req.PayloadHash)
	req.ValueRef = strings.TrimSpace(req.ValueRef)
	req.FinalStatus = strings.TrimSpace(req.FinalStatus)
	req.RequestedBy = strings.TrimSpace(req.RequestedBy)

	if err := req.Validate(); err != nil {
		return FinalizeDedupeRecordResponse{}, err
	}

	result, err := u.store.FinalizeRecord(ctx, FinalizeDedupeRecordCommand{
		TenantID:    req.TenantID,
		ScopeKey:    req.ScopeKey,
		RecordKey:   req.RecordKey,
		PayloadHash: req.PayloadHash,
		ValueRef:    req.ValueRef,
		FinalStatus: req.FinalStatus,
		RequestedBy: req.RequestedBy,
	})
	if err != nil {
		return FinalizeDedupeRecordResponse{}, err
	}

	recordID := strings.TrimSpace(result.RecordID)
	if recordID == "" {
		recordID = uuid.NewString()
	}

	resp := FinalizeDedupeRecordResponse{
		RecordID:    recordID,
		ScopeKey:    req.ScopeKey,
		RecordKey:   req.RecordKey,
		PayloadHash: req.PayloadHash,
		ValueRef:    firstNonEmpty(strings.TrimSpace(result.ValueRef), req.ValueRef),
		FinalStatus: firstNonEmpty(strings.TrimSpace(result.FinalStatus), req.FinalStatus),
		BoundAt:     u.nowFn().UTC(),
	}

	if err := resp.Validate(); err != nil {
		return FinalizeDedupeRecordResponse{}, err
	}

	return resp, nil
}
