package apisurface

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/e2eflow"
)

type fakeRuntimeFlowAPIService struct {
	err error

	called bool
	gotReq RuntimeFlowAPIRequest
}

func (s *fakeRuntimeFlowAPIService) PostRuntimeFlow(ctx context.Context, req RuntimeFlowAPIRequest) (RuntimeFlowAPIResponse, error) {
	s.called = true
	s.gotReq = req

	if s.err != nil {
		return RuntimeFlowAPIResponse{}, s.err
	}

	return RuntimeFlowAPIResponse{
		OK: true,

		TenantID:  req.TenantID,
		RequestID: req.RequestID,

		TransactionKind: req.TransactionKind,

		SourceModule:       req.Source.SourceModule,
		SourceDocumentType: req.Source.SourceDocumentType,
		SourceDocumentID:   req.Source.SourceDocumentID,
		SourceDocumentNo:   req.Source.SourceDocumentNo,

		Status:      string(e2eflow.FlowStatusCompleted),
		StepCount:   6,
		CompletedAt: time.Date(2026, 4, 26, 10, 0, 0, 0, time.UTC),
		Message:     "runtime flow completed",
	}, nil
}

func TestRuntimeFlowHTTPHandlerSuccess(t *testing.T) {
	service := &fakeRuntimeFlowAPIService{}
	handler := NewRuntimeFlowHTTPHandler(service)

	body := mustRuntimeFlowAPIJSON(t, validRuntimeFlowAPIRequest())

	req := httptest.NewRequest(http.MethodPost, RuntimeFlowAPIPath, bytes.NewReader(body))
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d body=%s", rec.Code, rec.Body.String())
	}

	if !service.called {
		t.Fatal("expected service to be called")
	}

	if service.gotReq.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", service.gotReq.TenantID)
	}

	var resp RuntimeFlowAPIResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	if !resp.OK {
		t.Fatal("expected OK response")
	}

	if resp.Status != "completed" {
		t.Fatalf("expected completed, got %s", resp.Status)
	}

	if resp.StepCount != 6 {
		t.Fatalf("expected step count 6, got %d", resp.StepCount)
	}
}

func TestRuntimeFlowHTTPHandlerMethodNotAllowed(t *testing.T) {
	service := &fakeRuntimeFlowAPIService{}
	handler := NewRuntimeFlowHTTPHandler(service)

	req := httptest.NewRequest(http.MethodGet, RuntimeFlowAPIPath, nil)
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusMethodNotAllowed {
		t.Fatalf("expected status 405, got %d", rec.Code)
	}

	if service.called {
		t.Fatal("service should not be called")
	}

	var resp RuntimeFlowAPIErrorResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode error response: %v", err)
	}

	if resp.OK {
		t.Fatal("expected OK=false")
	}

	if resp.ErrorCode != "INVALID_HTTP_METHOD" {
		t.Fatalf("expected INVALID_HTTP_METHOD, got %s", resp.ErrorCode)
	}
}

func TestRuntimeFlowHTTPHandlerInvalidJSON(t *testing.T) {
	service := &fakeRuntimeFlowAPIService{}
	handler := NewRuntimeFlowHTTPHandler(service)

	req := httptest.NewRequest(http.MethodPost, RuntimeFlowAPIPath, bytes.NewBufferString("{wrong json"))
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400, got %d", rec.Code)
	}

	if service.called {
		t.Fatal("service should not be called")
	}

	var resp RuntimeFlowAPIErrorResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode error response: %v", err)
	}

	if resp.ErrorCode != "INVALID_JSON_REQUEST" {
		t.Fatalf("expected INVALID_JSON_REQUEST, got %s", resp.ErrorCode)
	}
}

func TestRuntimeFlowHTTPHandlerValidationError(t *testing.T) {
	service := &fakeRuntimeFlowAPIService{
		err: ErrTenantIDRequired,
	}
	handler := NewRuntimeFlowHTTPHandler(service)

	body := mustRuntimeFlowAPIJSON(t, validRuntimeFlowAPIRequest())

	req := httptest.NewRequest(http.MethodPost, RuntimeFlowAPIPath, bytes.NewReader(body))
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400, got %d", rec.Code)
	}

	if !service.called {
		t.Fatal("expected service to be called")
	}

	var resp RuntimeFlowAPIErrorResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode error response: %v", err)
	}

	if resp.ErrorCode != "TENANT_ID_REQUIRED" {
		t.Fatalf("expected TENANT_ID_REQUIRED, got %s", resp.ErrorCode)
	}
}

func TestRuntimeFlowHTTPHandlerExecutorRequiredError(t *testing.T) {
	service := &fakeRuntimeFlowAPIService{
		err: ErrRuntimeFlowExecutorRequired,
	}
	handler := NewRuntimeFlowHTTPHandler(service)

	body := mustRuntimeFlowAPIJSON(t, validRuntimeFlowAPIRequest())

	req := httptest.NewRequest(http.MethodPost, RuntimeFlowAPIPath, bytes.NewReader(body))
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("expected status 500, got %d", rec.Code)
	}

	var resp RuntimeFlowAPIErrorResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode error response: %v", err)
	}

	if resp.ErrorCode != "RUNTIME_FLOW_EXECUTOR_REQUIRED" {
		t.Fatalf("expected RUNTIME_FLOW_EXECUTOR_REQUIRED, got %s", resp.ErrorCode)
	}
}

func TestRuntimeFlowHTTPHandlerServiceRequired(t *testing.T) {
	handler := NewRuntimeFlowHTTPHandler(nil)

	body := mustRuntimeFlowAPIJSON(t, validRuntimeFlowAPIRequest())

	req := httptest.NewRequest(http.MethodPost, RuntimeFlowAPIPath, bytes.NewReader(body))
	req.Header.Set("X-Tenant-ID", "tenant_7")
	req.Header.Set("X-Request-ID", "req-123")
	rec := httptest.NewRecorder()

	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("expected status 500, got %d", rec.Code)
	}

	var resp RuntimeFlowAPIErrorResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode error response: %v", err)
	}

	if resp.ErrorCode != "RUNTIME_FLOW_API_SERVICE_REQUIRED" {
		t.Fatalf("expected RUNTIME_FLOW_API_SERVICE_REQUIRED, got %s", resp.ErrorCode)
	}

	if resp.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7 from header, got %s", resp.TenantID)
	}

	if resp.RequestID != "req-123" {
		t.Fatalf("expected req-123 from header, got %s", resp.RequestID)
	}
}

func TestRuntimeFlowAPIHTTPErrorStatusFallback(t *testing.T) {
	statusCode, errorCode := runtimeFlowAPIHTTPErrorStatus(errors.New("unknown"))

	if statusCode != http.StatusInternalServerError {
		t.Fatalf("expected status 500, got %d", statusCode)
	}

	if errorCode != "RUNTIME_FLOW_INTERNAL_ERROR" {
		t.Fatalf("expected RUNTIME_FLOW_INTERNAL_ERROR, got %s", errorCode)
	}
}

func mustRuntimeFlowAPIJSON(t *testing.T, req RuntimeFlowAPIRequest) []byte {
	t.Helper()

	body, err := json.Marshal(req)
	if err != nil {
		t.Fatalf("marshal request: %v", err)
	}

	return body
}
