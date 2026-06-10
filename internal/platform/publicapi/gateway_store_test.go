package publicapi

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type publicAPIGatewayRowMock struct {
	values []any
	err    error
}

func (r *publicAPIGatewayRowMock) Scan(dest ...any) error {
	if r.err != nil {
		return r.err
	}

	for i := range dest {
		switch d := dest[i].(type) {
		case *string:
			*d = r.values[i].(string)
		case *bool:
			*d = r.values[i].(bool)
		default:
			return errors.New("dest tipi desteklenmiyor")
		}
	}

	return nil
}

type publicAPIGatewayQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *publicAPIGatewayQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestResolvePublicAPIGatewaySQLStoreResolveRoute_Success(t *testing.T) {
	db := &publicAPIGatewayQueryRowProviderMock{
		row: &publicAPIGatewayRowMock{
			values: []any{
				"req-001",
				"app-001",
				"key-001",
				"GET",
				"/v1/erp/customers",
				"erp-api",
				"/v1/erp",
				"accepted",
				true,
				"",
			},
		},
	}

	store := NewResolvePublicAPIGatewaySQLStore(db)

	result, err := store.ResolveRoute(context.Background(), ResolvePublicAPIGatewayCommand{
		TenantID:    "tenant-a",
		RequestID:   "req-001",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Method:      "get",
		Path:        "/v1/erp/customers",
		Origin:      "https://developer.pix2pi.com.tr",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.RequestID != "req-001" {
		t.Fatalf("beklenen request_id req-001, alinan: %s", result.RequestID)
	}

	if result.AppID != "app-001" {
		t.Fatalf("beklenen app_id app-001, alinan: %s", result.AppID)
	}

	if result.APIKeyID != "key-001" {
		t.Fatalf("beklenen api_key_id key-001, alinan: %s", result.APIKeyID)
	}

	if result.Method != "GET" {
		t.Fatalf("beklenen method GET, alinan: %s", result.Method)
	}

	if result.Path != "/v1/erp/customers" {
		t.Fatalf("beklenen path /v1/erp/customers, alinan: %s", result.Path)
	}

	if result.TargetService != "erp-api" {
		t.Fatalf("beklenen target_service erp-api, alinan: %s", result.TargetService)
	}

	if result.TargetPath != "/v1/erp" {
		t.Fatalf("beklenen target_path /v1/erp, alinan: %s", result.TargetPath)
	}

	if result.GatewayStatus != "accepted" {
		t.Fatalf("beklenen gateway_status accepted, alinan: %s", result.GatewayStatus)
	}

	if !result.Accepted {
		t.Fatalf("beklenen accepted true")
	}

	if result.RejectionReason != "" {
		t.Fatalf("accepted durumda rejection_reason bos olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.public_api_routes") {
		t.Fatalf("public_api_routes query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.public_api_gateway_requests") {
		t.Fatalf("public_api_gateway_requests query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "path_prefix") {
		t.Fatalf("path_prefix route matching query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "gateway_status") {
		t.Fatalf("gateway_status query icinde olmaliydi")
	}

	if len(db.lastArgs) != 8 {
		t.Fatalf("beklenen 8 arguman, alinan: %d", len(db.lastArgs))
	}

	if db.lastArgs[4] != "GET" {
		t.Fatalf("method uppercase gecmeliydi, alinan: %v", db.lastArgs[4])
	}
}

func TestResolvePublicAPIGatewaySQLStoreResolveRoute_RejectedSuccess(t *testing.T) {
	db := &publicAPIGatewayQueryRowProviderMock{
		row: &publicAPIGatewayRowMock{
			values: []any{
				"req-002",
				"app-001",
				"key-001",
				"DELETE",
				"/v1/erp/customers",
				"",
				"/v1/erp",
				"rejected",
				false,
				"method not allowed for app",
			},
		},
	}

	store := NewResolvePublicAPIGatewaySQLStore(db)

	result, err := store.ResolveRoute(context.Background(), ResolvePublicAPIGatewayCommand{
		TenantID:    "tenant-a",
		RequestID:   "req-002",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Method:      "DELETE",
		Path:        "/v1/erp/customers",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Accepted {
		t.Fatalf("beklenen accepted false")
	}

	if result.GatewayStatus != "rejected" {
		t.Fatalf("beklenen gateway_status rejected, alinan: %s", result.GatewayStatus)
	}

	if result.RejectionReason == "" {
		t.Fatalf("beklenen rejection_reason dolu")
	}
}

func TestResolvePublicAPIGatewaySQLStoreResolveRoute_NormalizePathSuccess(t *testing.T) {
	db := &publicAPIGatewayQueryRowProviderMock{
		row: &publicAPIGatewayRowMock{
			values: []any{
				"req-003",
				"app-001",
				"key-001",
				"POST",
				"/v1/developer/apps",
				"developer-api",
				"/v1/developer",
				"accepted",
				true,
				"",
			},
		},
	}

	store := NewResolvePublicAPIGatewaySQLStore(db)

	result, err := store.ResolveRoute(context.Background(), ResolvePublicAPIGatewayCommand{
		RequestID:   "req-003",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Method:      "post",
		Path:        "v1/developer/apps",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.Path != "/v1/developer/apps" {
		t.Fatalf("beklenen normalize path /v1/developer/apps, alinan: %s", result.Path)
	}

	if db.lastArgs[5] != "/v1/developer/apps" {
		t.Fatalf("query arg path normalize olmaliydi, alinan: %v", db.lastArgs[5])
	}
}

func TestResolvePublicAPIGatewaySQLStoreResolveRoute_NoDB(t *testing.T) {
	store := NewResolvePublicAPIGatewaySQLStore(nil)

	_, err := store.ResolveRoute(context.Background(), ResolvePublicAPIGatewayCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestResolvePublicAPIGatewaySQLStoreResolveRoute_ScanError(t *testing.T) {
	db := &publicAPIGatewayQueryRowProviderMock{
		row: &publicAPIGatewayRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewResolvePublicAPIGatewaySQLStore(db)

	_, err := store.ResolveRoute(context.Background(), ResolvePublicAPIGatewayCommand{
		TenantID:    "tenant-a",
		RequestID:   "req-001",
		AppID:       "app-001",
		APIKeyID:    "key-001",
		Method:      "GET",
		Path:        "/v1/erp/customers",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
