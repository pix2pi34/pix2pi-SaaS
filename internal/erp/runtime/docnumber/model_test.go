package docnumber

import (
	"errors"
	"testing"
)

func intPtr(value int) *int {
	return &value
}

func int64Ptr(value int64) *int64 {
	return &value
}

func validAllocateRequest() AllocateDocumentNumberRequest {
	return AllocateDocumentNumberRequest{
		TenantID:         "tenant_7",
		RequestID:        "req-123",
		ActorID:          "user-1",
		DocumentModule:   DocumentModuleSales,
		DocumentType:     "invoice",
		FiscalYear:       intPtr(2026),
		FiscalPeriod:     "2026-04",
		SourceDocumentID: "source-doc-1",
	}
}

func validSequenceSnapshot() DocumentSequenceSnapshot {
	return DocumentSequenceSnapshot{
		TenantID:           "tenant_7",
		DocumentSequenceID: "seq-1",
		DocumentModule:     DocumentModuleSales,
		DocumentType:       "invoice",
		FiscalYear:         intPtr(2026),
		Prefix:             "INV-",
		Suffix:             "",
		CurrentNo:          0,
		MinNo:              1,
		MaxNo:              int64Ptr(999999),
		Padding:            6,
		ResetPolicy:        ResetPolicyYearly,
		IsActive:           true,
		Status:             SequenceStatusActive,
	}
}

func TestValidateAllocateDocumentNumberRequestSuccess(t *testing.T) {
	err := ValidateAllocateDocumentNumberRequest(validAllocateRequest())
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateAllocateDocumentNumberRequestTenantRequired(t *testing.T) {
	req := validAllocateRequest()
	req.TenantID = ""

	err := ValidateAllocateDocumentNumberRequest(req)
	if !errors.Is(err, ErrTenantRequired) {
		t.Fatalf("expected ErrTenantRequired, got %v", err)
	}
}

func TestValidateAllocateDocumentNumberRequestModuleInvalid(t *testing.T) {
	req := validAllocateRequest()
	req.DocumentModule = DocumentModule("wrong")

	err := ValidateAllocateDocumentNumberRequest(req)
	if !errors.Is(err, ErrDocumentModuleInvalid) {
		t.Fatalf("expected ErrDocumentModuleInvalid, got %v", err)
	}
}

func TestValidateDocumentSequenceSnapshotSuccess(t *testing.T) {
	err := ValidateDocumentSequenceSnapshot(validSequenceSnapshot())
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}
}

func TestValidateDocumentSequenceSnapshotSequenceIDRequired(t *testing.T) {
	seq := validSequenceSnapshot()
	seq.DocumentSequenceID = ""

	err := ValidateDocumentSequenceSnapshot(seq)
	if !errors.Is(err, ErrSequenceIDRequired) {
		t.Fatalf("expected ErrSequenceIDRequired, got %v", err)
	}
}

func TestValidateDocumentSequenceSnapshotPaddingInvalid(t *testing.T) {
	seq := validSequenceSnapshot()
	seq.Padding = 0

	err := ValidateDocumentSequenceSnapshot(seq)
	if !errors.Is(err, ErrPaddingInvalid) {
		t.Fatalf("expected ErrPaddingInvalid, got %v", err)
	}
}

func TestNextAllocatedNumberSuccess(t *testing.T) {
	seq := validSequenceSnapshot()
	seq.CurrentNo = 41

	nextNo, err := NextAllocatedNumber(seq)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if nextNo != 42 {
		t.Fatalf("expected next no 42, got %d", nextNo)
	}
}

func TestNextAllocatedNumberUsesMinNo(t *testing.T) {
	seq := validSequenceSnapshot()
	seq.CurrentNo = 0
	seq.MinNo = 100

	nextNo, err := NextAllocatedNumber(seq)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if nextNo != 100 {
		t.Fatalf("expected next no 100, got %d", nextNo)
	}
}

func TestNextAllocatedNumberExhausted(t *testing.T) {
	seq := validSequenceSnapshot()
	seq.CurrentNo = 10
	seq.MaxNo = int64Ptr(10)

	_, err := NextAllocatedNumber(seq)
	if !errors.Is(err, ErrSequenceExhausted) {
		t.Fatalf("expected ErrSequenceExhausted, got %v", err)
	}
}

func TestFormatDocumentNumber(t *testing.T) {
	seq := validSequenceSnapshot()
	seq.Prefix = "INV-"
	seq.Suffix = "-TR"
	seq.Padding = 6

	got := FormatDocumentNumber(seq, 42)
	want := "INV-000042-TR"

	if got != want {
		t.Fatalf("expected %s, got %s", want, got)
	}
}

func TestBuildDocumentNumberAllocationSuccess(t *testing.T) {
	req := validAllocateRequest()
	seq := validSequenceSnapshot()

	allocation, err := BuildDocumentNumberAllocation(req, seq)
	if err != nil {
		t.Fatalf("expected success, got %v", err)
	}

	if allocation.DocumentNo != "INV-000001" {
		t.Fatalf("expected document no INV-000001, got %s", allocation.DocumentNo)
	}

	if allocation.AllocatedNo != 1 {
		t.Fatalf("expected allocated no 1, got %d", allocation.AllocatedNo)
	}

	if allocation.AllocationStatus != AllocationStatusAllocated {
		t.Fatalf("expected allocation status allocated, got %s", allocation.AllocationStatus)
	}

	if allocation.AllocatedAt.IsZero() {
		t.Fatal("expected allocated_at")
	}
}

func TestBuildDocumentNumberAllocationTenantMismatch(t *testing.T) {
	req := validAllocateRequest()
	seq := validSequenceSnapshot()
	seq.TenantID = "tenant_99"

	_, err := BuildDocumentNumberAllocation(req, seq)
	if !errors.Is(err, ErrSequenceNotFound) {
		t.Fatalf("expected ErrSequenceNotFound, got %v", err)
	}
}

func TestBuildDocumentNumberAllocationInactive(t *testing.T) {
	req := validAllocateRequest()
	seq := validSequenceSnapshot()
	seq.IsActive = false

	_, err := BuildDocumentNumberAllocation(req, seq)
	if !errors.Is(err, ErrSequenceInactive) {
		t.Fatalf("expected ErrSequenceInactive, got %v", err)
	}
}

func TestBuildDocumentNumberAllocationLocked(t *testing.T) {
	req := validAllocateRequest()
	seq := validSequenceSnapshot()
	seq.Status = SequenceStatusLocked

	_, err := BuildDocumentNumberAllocation(req, seq)
	if !errors.Is(err, ErrSequenceLocked) {
		t.Fatalf("expected ErrSequenceLocked, got %v", err)
	}
}

func TestBuildAllocateDocumentNumberResultSuccess(t *testing.T) {
	req := validAllocateRequest()
	seq := validSequenceSnapshot()

	allocation, err := BuildDocumentNumberAllocation(req, seq)
	if err != nil {
		t.Fatalf("expected allocation success, got %v", err)
	}

	result, err := BuildAllocateDocumentNumberResult(req, allocation)
	if err != nil {
		t.Fatalf("expected result success, got %v", err)
	}

	if !result.OK {
		t.Fatal("expected OK result")
	}

	if result.RequestID != req.RequestID {
		t.Fatalf("expected request id %s, got %s", req.RequestID, result.RequestID)
	}

	if result.DocumentNo != allocation.DocumentNo {
		t.Fatalf("expected document no %s, got %s", allocation.DocumentNo, result.DocumentNo)
	}
}
