package main

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/erp/runtime/apisurface"
)

type fakeGatewayERPRuntimeAPIService struct {
	err error

	called bool
	gotReq apisurface.RuntimeFlowAPIRequest
}

func (s *fakeGatewayERPRuntimeAPIService) PostRuntimeFlow(ctx context.Context, req apisurface.RuntimeFlowAPIRequest) (apisurface.RuntimeFlowAPIResponse, error) {
	s.called = true
	s.gotReq = req

	if s.err != nil {
		return apisurface.RuntimeFlowAPIResponse{}, s.err
	}

	return apisurface.RuntimeFlowAPIResponse{
		OK: true,

		TenantID:  req.TenantID,
		RequestID: req.RequestID,

		TransactionKind: req.TransactionKind,

		SourceModule:       req.Source.SourceModule,
		SourceDocumentType: req.Source.SourceDocumentType,
		SourceDocumentID:   req.Source.SourceDocumentID,
		SourceDocumentNo:   req.Source.SourceDocumentNo,

		Status:      "completed",
		StepCount:   6,
		CompletedAt: time.Date(2026, 4, 26, 20, 0, 0, 0, time.UTC),
		Message:     "runtime flow completed",
	}, nil
}

func validGatewayERPRuntimeAPIRequest() apisurface.RuntimeFlowAPIRequest {
	return apisurface.RuntimeFlowAPIRequest{
		TenantID: "tenant_7",

		RequestID: "req-gateway-erp-runtime",
		ActorID:   "user-gateway",
		ActorType: "user",

		TransactionKind: "sales_invoice",

		Source: apisurface.RuntimeFlowAPISource{
			SourceModule:       "sales",
			SourceDocumentType: "invoice",
			SourceDocumentNo:   "GW-ERP-INV-2026-000001",
		},

		Money: apisurface.RuntimeFlowAPIMoney{
			TotalAmount:  120,
			CurrencyCode: "TRY",
			ExchangeRate: 1,
		},

		IdempotencyKey: "tenant_7:sales_invoice:GW-ERP-INV-2026-000001",
		CorrelationID:  "corr-gateway-erp-runtime",
	}
}

func TestMountERPRuntimeGatewayRoutesSuccess(t *testing.T) {
	mux := http.NewServeMux()
	service := &fakeGatewayERPRuntimeAPIService{}

	binding, err := mountERPRuntimeGatewayRoutes(mux, service)
	if err != nil {
		t.Fatalf("expected mount success, got %v", err)
	}

	if binding.Plan.Name != apisurface.RuntimeFlowGatewayMountName {
		t.Fatalf("expected mount name %s, got %s", apisurface.RuntimeFlowGatewayMountName, binding.Plan.Name)
	}

	if len(binding.RouteBindings) != 1 {
		t.Fatalf("expected 1 route binding, got %d", len(binding.RouteBindings))
	}

	body, err := json.Marshal(validGatewayERPRuntimeAPIRequest())
	if err != nil {
		t.Fatalf("marshal request: %v", err)
	}

	req := httptest.NewRequest(http.MethodPost, apisurface.RuntimeFlowAPIPath, bytes.NewReader(body))
	rec := httptest.NewRecorder()

	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected HTTP 200, got %d body=%s", rec.Code, rec.Body.String())
	}

	if !service.called {
		t.Fatal("expected service to be called")
	}

	if service.gotReq.TenantID != "tenant_7" {
		t.Fatalf("expected tenant_7, got %s", service.gotReq.TenantID)
	}

	var resp apisurface.RuntimeFlowAPIResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	if !resp.OK {
		t.Fatal("expected OK response")
	}

	if resp.Status != "completed" {
		t.Fatalf("expected completed, got %s", resp.Status)
	}
}

func TestMountERPRuntimeGatewayRoutesNilMux(t *testing.T) {
	service := &fakeGatewayERPRuntimeAPIService{}

	_, err := mountERPRuntimeGatewayRoutes(nil, service)
	if err != apisurface.ErrRouteRegistrarRequired {
		t.Fatalf("expected ErrRouteRegistrarRequired, got %v", err)
	}
}

func TestMountERPRuntimeGatewayRoutesNilService(t *testing.T) {
	mux := http.NewServeMux()

	_, err := mountERPRuntimeGatewayRoutes(mux, nil)
	if err != apisurface.ErrRuntimeFlowAPIServiceRequired {
		t.Fatalf("expected ErrRuntimeFlowAPIServiceRequired, got %v", err)
	}
}

func TestERPRuntimeGatewayMuxRegistrarNilMux(t *testing.T) {
	registrar := newERPRuntimeGatewayMuxRegistrar(nil)

	err := registrar.RegisterRoute(http.MethodPost, apisurface.RuntimeFlowAPIPath, http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}))
	if err != apisurface.ErrRouteRegistrarRequired {
		t.Fatalf("expected ErrRouteRegistrarRequired, got %v", err)
	}
}

func TestERPRuntimeGatewayMuxRegistrarNilHandler(t *testing.T) {
	registrar := newERPRuntimeGatewayMuxRegistrar(http.NewServeMux())

	err := registrar.RegisterRoute(http.MethodPost, apisurface.RuntimeFlowAPIPath, nil)
	if err != apisurface.ErrRouteHandlerRequired {
		t.Fatalf("expected ErrRouteHandlerRequired, got %v", err)
	}
}
