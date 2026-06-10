package idempotency

import (
	"context"
	"fmt"
	"strings"
	"sync"
	"testing"
	"time"
)

type idemRuntimeReservationRecord struct {
	ReservationID  string
	TenantID       string
	ScopeKey       string
	IdempotencyKey string
	RequestHash    string
	ResultRef      string
	FinalStatus    string
	ExpiresAt      time.Time
	ReservedAt     time.Time
	BoundAt        time.Time
}

type dedupeRuntimeRecord struct {
	RecordID    string
	TenantID    string
	ScopeKey    string
	RecordKey   string
	PayloadHash string
	ValueRef    string
	FinalStatus string
	ExpiresAt   time.Time
	ReservedAt  time.Time
	BoundAt     time.Time
}

type idempotencyRuntimeIntegrationStore struct {
	mu                sync.Mutex
	nowFn             func() time.Time
	reservationSeq    int
	dedupeSeq         int
	reservations      map[string]*idemRuntimeReservationRecord
	dedupeRecords     map[string]*dedupeRuntimeRecord
}

func newIdempotencyRuntimeIntegrationStore() *idempotencyRuntimeIntegrationStore {
	return &idempotencyRuntimeIntegrationStore{
		nowFn: func() time.Time {
			return time.Now().UTC()
		},
		reservations:  make(map[string]*idemRuntimeReservationRecord),
		dedupeRecords: make(map[string]*dedupeRuntimeRecord),
	}
}

func (s *idempotencyRuntimeIntegrationStore) ReserveOrCheckKey(_ context.Context, cmd ReserveIdempotencyKeyCommand) (ReserveIdempotencyKeyResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := s.nowFn().UTC()
	key := buildIdemReservationKey(cmd.TenantID, cmd.ScopeKey, cmd.IdempotencyKey)

	if rec, ok := s.reservations[key]; ok && rec.ExpiresAt.After(now) {
		if rec.RequestHash == strings.TrimSpace(cmd.RequestHash) {
			return ReserveIdempotencyKeyResult{
				ReservationID:     rec.ReservationID,
				Status:            "existing",
				ExistingResultRef: rec.ResultRef,
				ExpiresAt:         &rec.ExpiresAt,
			}, nil
		}

		return ReserveIdempotencyKeyResult{
			ReservationID: rec.ReservationID,
			Status:        "conflict",
			ExpiresAt:     &rec.ExpiresAt,
		}, nil
	}

	s.reservationSeq++
	reservationID := fmt.Sprintf("res-%03d", s.reservationSeq)

	rec := &idemRuntimeReservationRecord{
		ReservationID:  reservationID,
		TenantID:       strings.TrimSpace(cmd.TenantID),
		ScopeKey:       strings.TrimSpace(cmd.ScopeKey),
		IdempotencyKey: strings.TrimSpace(cmd.IdempotencyKey),
		RequestHash:    strings.TrimSpace(cmd.RequestHash),
		ResultRef:      "",
		FinalStatus:    "",
		ExpiresAt:      now.Add(time.Duration(cmd.TTLSeconds) * time.Second),
		ReservedAt:     now,
	}
	s.reservations[key] = rec

	return ReserveIdempotencyKeyResult{
		ReservationID: rec.ReservationID,
		Status:        "reserved",
		ExpiresAt:     &rec.ExpiresAt,
	}, nil
}

func (s *idempotencyRuntimeIntegrationStore) FinalizeKey(_ context.Context, cmd FinalizeIdempotencyKeyCommand) (FinalizeIdempotencyKeyResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := s.nowFn().UTC()
	key := buildIdemReservationKey(cmd.TenantID, cmd.ScopeKey, cmd.IdempotencyKey)

	rec, ok := s.reservations[key]
	if !ok {
		return FinalizeIdempotencyKeyResult{}, fmt.Errorf("reservation not found: %s", cmd.IdempotencyKey)
	}

	if !rec.ExpiresAt.After(now) {
		return FinalizeIdempotencyKeyResult{}, fmt.Errorf("reservation expired: %s", cmd.IdempotencyKey)
	}

	if rec.RequestHash != strings.TrimSpace(cmd.RequestHash) {
		return FinalizeIdempotencyKeyResult{}, fmt.Errorf("request hash mismatch: %s", cmd.RequestHash)
	}

	rec.RequestHash = strings.TrimSpace(cmd.RequestHash)
	rec.ResultRef = strings.TrimSpace(cmd.ResultRef)
	rec.FinalStatus = strings.TrimSpace(cmd.FinalStatus)
	rec.BoundAt = now

	return FinalizeIdempotencyKeyResult{
		ReservationID: rec.ReservationID,
		ResultRef:     rec.ResultRef,
		FinalStatus:   rec.FinalStatus,
	}, nil
}

func (s *idempotencyRuntimeIntegrationStore) ReserveOrCheckRecord(_ context.Context, cmd ReserveDedupeRecordCommand) (ReserveDedupeRecordResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := s.nowFn().UTC()
	key := buildDedupeRecordKey(cmd.TenantID, cmd.ScopeKey, cmd.RecordKey)

	if rec, ok := s.dedupeRecords[key]; ok && rec.ExpiresAt.After(now) {
		if rec.PayloadHash == strings.TrimSpace(cmd.PayloadHash) {
			return ReserveDedupeRecordResult{
				RecordID:         rec.RecordID,
				Status:           "existing",
				ExistingValueRef: rec.ValueRef,
				ExpiresAt:        &rec.ExpiresAt,
			}, nil
		}

		return ReserveDedupeRecordResult{
			RecordID:  rec.RecordID,
			Status:    "conflict",
			ExpiresAt: &rec.ExpiresAt,
		}, nil
	}

	s.dedupeSeq++
	recordID := fmt.Sprintf("ded-%03d", s.dedupeSeq)

	rec := &dedupeRuntimeRecord{
		RecordID:    recordID,
		TenantID:    strings.TrimSpace(cmd.TenantID),
		ScopeKey:    strings.TrimSpace(cmd.ScopeKey),
		RecordKey:   strings.TrimSpace(cmd.RecordKey),
		PayloadHash: strings.TrimSpace(cmd.PayloadHash),
		ValueRef:    "",
		FinalStatus: "",
		ExpiresAt:   now.Add(time.Duration(cmd.TTLSeconds) * time.Second),
		ReservedAt:  now,
	}
	s.dedupeRecords[key] = rec

	return ReserveDedupeRecordResult{
		RecordID:  rec.RecordID,
		Status:    "reserved",
		ExpiresAt: &rec.ExpiresAt,
	}, nil
}

func (s *idempotencyRuntimeIntegrationStore) FinalizeRecord(_ context.Context, cmd FinalizeDedupeRecordCommand) (FinalizeDedupeRecordResult, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := s.nowFn().UTC()
	key := buildDedupeRecordKey(cmd.TenantID, cmd.ScopeKey, cmd.RecordKey)

	rec, ok := s.dedupeRecords[key]
	if !ok {
		return FinalizeDedupeRecordResult{}, fmt.Errorf("dedupe record not found: %s", cmd.RecordKey)
	}

	if !rec.ExpiresAt.After(now) {
		return FinalizeDedupeRecordResult{}, fmt.Errorf("dedupe record expired: %s", cmd.RecordKey)
	}

	if rec.PayloadHash != strings.TrimSpace(cmd.PayloadHash) {
		return FinalizeDedupeRecordResult{}, fmt.Errorf("payload hash mismatch: %s", cmd.PayloadHash)
	}

	rec.PayloadHash = strings.TrimSpace(cmd.PayloadHash)
	rec.ValueRef = strings.TrimSpace(cmd.ValueRef)
	rec.FinalStatus = strings.TrimSpace(cmd.FinalStatus)
	rec.BoundAt = now

	return FinalizeDedupeRecordResult{
		RecordID:    rec.RecordID,
		ValueRef:    rec.ValueRef,
		FinalStatus: rec.FinalStatus,
	}, nil
}

func buildIdemReservationKey(tenantID, scopeKey, idempotencyKey string) string {
	return strings.TrimSpace(tenantID) + "|" + strings.TrimSpace(scopeKey) + "|" + strings.TrimSpace(idempotencyKey)
}

func buildDedupeRecordKey(tenantID, scopeKey, recordKey string) string {
	return strings.TrimSpace(tenantID) + "|" + strings.TrimSpace(scopeKey) + "|" + strings.TrimSpace(recordKey)
}

func TestIdempotencyRuntimeIntegration_ReserveFinalizeReserveExistingFlow(t *testing.T) {
	store := newIdempotencyRuntimeIntegrationStore()

	reserveUsecase := NewReserveIdempotencyKeyUsecase(store)
	finalizeUsecase := NewFinalizeIdempotencyKeyUsecase(store)

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 20, 0, 0, 0, time.UTC)
	}
	reserveUsecase.nowFn = store.nowFn
	finalizeUsecase.nowFn = store.nowFn

	reserveResp, err := reserveUsecase.ReserveOrCheck(context.Background(), ReserveIdempotencyKeyRequest{
		TenantID:       "tenant-a",
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		TTLSeconds:     300,
		RequestedBy:    "api-gateway",
	})
	if err != nil {
		t.Fatalf("reserve hatasi: %v", err)
	}

	if reserveResp.Status != "reserved" {
		t.Fatalf("beklenen status reserved, alinan: %s", reserveResp.Status)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 20, 1, 0, 0, time.UTC)
	}
	finalizeUsecase.nowFn = store.nowFn

	finalizeResp, err := finalizeUsecase.Finalize(context.Background(), FinalizeIdempotencyKeyRequest{
		TenantID:       "tenant-a",
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		ResultRef:      "payment-123",
		FinalStatus:    "completed",
		RequestedBy:    "api-gateway",
	})
	if err != nil {
		t.Fatalf("finalize hatasi: %v", err)
	}

	if finalizeResp.FinalStatus != "completed" {
		t.Fatalf("beklenen final_status completed, alinan: %s", finalizeResp.FinalStatus)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 20, 2, 0, 0, time.UTC)
	}
	reserveUsecase.nowFn = store.nowFn

	existingResp, err := reserveUsecase.ReserveOrCheck(context.Background(), ReserveIdempotencyKeyRequest{
		TenantID:       "tenant-a",
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-001",
		RequestHash:    "hash-001",
		TTLSeconds:     300,
		RequestedBy:    "api-gateway",
	})
	if err != nil {
		t.Fatalf("existing reserve hatasi: %v", err)
	}

	if existingResp.Status != "existing" {
		t.Fatalf("beklenen status existing, alinan: %s", existingResp.Status)
	}

	if existingResp.ExistingResultRef != "payment-123" {
		t.Fatalf("beklenen existing_result_ref payment-123, alinan: %s", existingResp.ExistingResultRef)
	}
}

func TestIdempotencyRuntimeIntegration_DedupeReserveFinalizeReserveExistingFlow(t *testing.T) {
	store := newIdempotencyRuntimeIntegrationStore()

	reserveUsecase := NewReserveDedupeRecordUsecase(store)
	finalizeUsecase := NewFinalizeDedupeRecordUsecase(store)

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 21, 0, 0, 0, time.UTC)
	}
	reserveUsecase.nowFn = store.nowFn
	finalizeUsecase.nowFn = store.nowFn

	reserveResp, err := reserveUsecase.ReserveOrCheck(context.Background(), ReserveDedupeRecordRequest{
		TenantID:    "tenant-a",
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		TTLSeconds:  300,
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("dedupe reserve hatasi: %v", err)
	}

	if reserveResp.Status != "reserved" {
		t.Fatalf("beklenen status reserved, alinan: %s", reserveResp.Status)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 21, 1, 0, 0, time.UTC)
	}
	finalizeUsecase.nowFn = store.nowFn

	finalizeResp, err := finalizeUsecase.Finalize(context.Background(), FinalizeDedupeRecordRequest{
		TenantID:    "tenant-a",
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		ValueRef:    "sync-batch-123",
		FinalStatus: "completed",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("dedupe finalize hatasi: %v", err)
	}

	if finalizeResp.FinalStatus != "completed" {
		t.Fatalf("beklenen final_status completed, alinan: %s", finalizeResp.FinalStatus)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 21, 2, 0, 0, time.UTC)
	}
	reserveUsecase.nowFn = store.nowFn

	existingResp, err := reserveUsecase.ReserveOrCheck(context.Background(), ReserveDedupeRecordRequest{
		TenantID:    "tenant-a",
		ScopeKey:    "stock.sync",
		RecordKey:   "record-001",
		PayloadHash: "hash-001",
		TTLSeconds:  300,
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("dedupe existing reserve hatasi: %v", err)
	}

	if existingResp.Status != "existing" {
		t.Fatalf("beklenen status existing, alinan: %s", existingResp.Status)
	}

	if existingResp.ExistingValueRef != "sync-batch-123" {
		t.Fatalf("beklenen existing_value_ref sync-batch-123, alinan: %s", existingResp.ExistingValueRef)
	}
}

func TestIdempotencyRuntimeIntegration_TenantIsolationAndConflictFlow(t *testing.T) {
	store := newIdempotencyRuntimeIntegrationStore()

	reserveIdemUsecase := NewReserveIdempotencyKeyUsecase(store)
	finalizeIdemUsecase := NewFinalizeIdempotencyKeyUsecase(store)
	reserveDedupeUsecase := NewReserveDedupeRecordUsecase(store)

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 22, 0, 0, 0, time.UTC)
	}
	reserveIdemUsecase.nowFn = store.nowFn
	finalizeIdemUsecase.nowFn = store.nowFn
	reserveDedupeUsecase.nowFn = store.nowFn

	tenantAReserve, err := reserveIdemUsecase.ReserveOrCheck(context.Background(), ReserveIdempotencyKeyRequest{
		TenantID:       "tenant-a",
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-iso",
		RequestHash:    "hash-a",
		TTLSeconds:     300,
		RequestedBy:    "api-gateway",
	})
	if err != nil {
		t.Fatalf("tenant-a reserve hatasi: %v", err)
	}

	if tenantAReserve.Status != "reserved" {
		t.Fatalf("beklenen tenant-a status reserved, alinan: %s", tenantAReserve.Status)
	}

	tenantBReserve, err := reserveIdemUsecase.ReserveOrCheck(context.Background(), ReserveIdempotencyKeyRequest{
		TenantID:       "tenant-b",
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-iso",
		RequestHash:    "hash-a",
		TTLSeconds:     300,
		RequestedBy:    "api-gateway",
	})
	if err != nil {
		t.Fatalf("tenant-b reserve hatasi: %v", err)
	}

	if tenantBReserve.Status != "reserved" {
		t.Fatalf("beklenen tenant-b status reserved, alinan: %s", tenantBReserve.Status)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 22, 1, 0, 0, time.UTC)
	}
	finalizeIdemUsecase.nowFn = store.nowFn

	if _, err := finalizeIdemUsecase.Finalize(context.Background(), FinalizeIdempotencyKeyRequest{
		TenantID:       "tenant-a",
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-iso",
		RequestHash:    "hash-a",
		ResultRef:      "payment-a",
		FinalStatus:    "completed",
		RequestedBy:    "api-gateway",
	}); err != nil {
		t.Fatalf("tenant-a finalize hatasi: %v", err)
	}

	store.nowFn = func() time.Time {
		return time.Date(2026, 4, 25, 22, 2, 0, 0, time.UTC)
	}
	reserveIdemUsecase.nowFn = store.nowFn
	reserveDedupeUsecase.nowFn = store.nowFn

	tenantAConflict, err := reserveIdemUsecase.ReserveOrCheck(context.Background(), ReserveIdempotencyKeyRequest{
		TenantID:       "tenant-a",
		ScopeKey:       "payment.create",
		IdempotencyKey: "idem-iso",
		RequestHash:    "hash-different",
		TTLSeconds:     300,
		RequestedBy:    "api-gateway",
	})
	if err != nil {
		t.Fatalf("tenant-a conflict reserve hatasi: %v", err)
	}

	if tenantAConflict.Status != "conflict" {
		t.Fatalf("beklenen tenant-a status conflict, alinan: %s", tenantAConflict.Status)
	}

	dedupeTenantA, err := reserveDedupeUsecase.ReserveOrCheck(context.Background(), ReserveDedupeRecordRequest{
		TenantID:    "tenant-a",
		ScopeKey:    "stock.sync",
		RecordKey:   "record-iso",
		PayloadHash: "hash-stock-a",
		TTLSeconds:  300,
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("tenant-a dedupe reserve hatasi: %v", err)
	}

	if dedupeTenantA.Status != "reserved" {
		t.Fatalf("beklenen tenant-a dedupe status reserved, alinan: %s", dedupeTenantA.Status)
	}

	dedupeTenantB, err := reserveDedupeUsecase.ReserveOrCheck(context.Background(), ReserveDedupeRecordRequest{
		TenantID:    "tenant-b",
		ScopeKey:    "stock.sync",
		RecordKey:   "record-iso",
		PayloadHash: "hash-stock-a",
		TTLSeconds:  300,
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("tenant-b dedupe reserve hatasi: %v", err)
	}

	if dedupeTenantB.Status != "reserved" {
		t.Fatalf("beklenen tenant-b dedupe status reserved, alinan: %s", dedupeTenantB.Status)
	}

	dedupeConflict, err := reserveDedupeUsecase.ReserveOrCheck(context.Background(), ReserveDedupeRecordRequest{
		TenantID:    "tenant-a",
		ScopeKey:    "stock.sync",
		RecordKey:   "record-iso",
		PayloadHash: "hash-stock-different",
		TTLSeconds:  300,
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("tenant-a dedupe conflict hatasi: %v", err)
	}

	if dedupeConflict.Status != "conflict" {
		t.Fatalf("beklenen tenant-a dedupe status conflict, alinan: %s", dedupeConflict.Status)
	}
}
