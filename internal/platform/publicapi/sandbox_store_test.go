package publicapi

import (
	"context"
	"errors"
	"strings"
	"testing"
)

type publicAPISandboxRowMock struct {
	values []any
	err    error
}

func (r *publicAPISandboxRowMock) Scan(dest ...any) error {
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

type publicAPISandboxQueryRowProviderMock struct {
	lastQuery string
	lastArgs  []any
	row       RowScanner
}

func (m *publicAPISandboxQueryRowProviderMock) QueryRowContext(_ context.Context, query string, args ...any) RowScanner {
	m.lastQuery = query
	m.lastArgs = args
	return m.row
}

func TestEnsurePublicAPISandboxSQLStoreEnsureSandbox_Success(t *testing.T) {
	db := &publicAPISandboxQueryRowProviderMock{
		row: &publicAPISandboxRowMock{
			values: []any{
				"sandbox-001",
				"app-001",
				"sandbox",
				"dev-sandbox",
				"sample_data",
				"https://sandbox.pix2pi.com.tr/app-001/dev-sandbox",
				true,
				"ready",
				true,
				"",
			},
		},
	}

	store := NewEnsurePublicAPISandboxSQLStore(db)

	result, err := store.EnsureSandbox(context.Background(), EnsurePublicAPISandboxCommand{
		TenantID:    "tenant-a",
		AppID:       "app-001",
		Environment: "sandbox",
		SandboxName: "dev-sandbox",
		DataMode:    "sample_data",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.SandboxID != "sandbox-001" {
		t.Fatalf("beklenen sandbox_id sandbox-001, alinan: %s", result.SandboxID)
	}

	if result.AppID != "app-001" {
		t.Fatalf("beklenen app_id app-001, alinan: %s", result.AppID)
	}

	if result.Environment != "sandbox" {
		t.Fatalf("beklenen environment sandbox, alinan: %s", result.Environment)
	}

	if result.SandboxName != "dev-sandbox" {
		t.Fatalf("beklenen sandbox_name dev-sandbox, alinan: %s", result.SandboxName)
	}

	if result.DataMode != "sample_data" {
		t.Fatalf("beklenen data_mode sample_data, alinan: %s", result.DataMode)
	}

	if result.BaseURL != "https://sandbox.pix2pi.com.tr/app-001/dev-sandbox" {
		t.Fatalf("beklenen base_url korunmaliydi, alinan: %s", result.BaseURL)
	}

	if !result.Isolated {
		t.Fatalf("beklenen isolated true")
	}

	if result.SandboxStatus != "ready" {
		t.Fatalf("beklenen sandbox_status ready, alinan: %s", result.SandboxStatus)
	}

	if !result.Ready {
		t.Fatalf("beklenen ready true")
	}

	if result.DenialReason != "" {
		t.Fatalf("ready durumda denial_reason bos olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "runtime.public_api_sandboxes") {
		t.Fatalf("public_api_sandboxes query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "ON CONFLICT (app_id, sandbox_name)") {
		t.Fatalf("sandbox ensure conflict handling query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "sandbox_status") {
		t.Fatalf("sandbox_status query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "isolated") {
		t.Fatalf("isolated query icinde olmaliydi")
	}

	if len(db.lastArgs) != 7 {
		t.Fatalf("beklenen 7 arguman, alinan: %d", len(db.lastArgs))
	}

	if db.lastArgs[5] != "https://sandbox.pix2pi.com.tr/app-001/dev-sandbox" {
		t.Fatalf("base_url fallback argumani beklenenden farkli: %v", db.lastArgs[5])
	}
}

func TestEnsurePublicAPISandboxSQLStoreEnsureSandbox_EmptyDataModeSuccess(t *testing.T) {
	db := &publicAPISandboxQueryRowProviderMock{
		row: &publicAPISandboxRowMock{
			values: []any{
				"sandbox-002",
				"app-002",
				"sandbox",
				"qa",
				"empty",
				"https://sandbox.pix2pi.com.tr/app-002/qa",
				true,
				"ready",
				true,
				"",
			},
		},
	}

	store := NewEnsurePublicAPISandboxSQLStore(db)

	result, err := store.EnsureSandbox(context.Background(), EnsurePublicAPISandboxCommand{
		AppID:       "app-002",
		Environment: "sandbox",
		SandboxName: "qa",
		DataMode:    "empty",
		RequestedBy: "worker-01",
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.DataMode != "empty" {
		t.Fatalf("beklenen data_mode empty, alinan: %s", result.DataMode)
	}

	if result.BaseURL != "https://sandbox.pix2pi.com.tr/app-002/qa" {
		t.Fatalf("beklenen base_url app-002/qa, alinan: %s", result.BaseURL)
	}
}

func TestEnsurePublicAPISandboxSQLStoreEnsureSandbox_NoDB(t *testing.T) {
	store := NewEnsurePublicAPISandboxSQLStore(nil)

	_, err := store.EnsureSandbox(context.Background(), EnsurePublicAPISandboxCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestEnsurePublicAPISandboxSQLStoreEnsureSandbox_ScanError(t *testing.T) {
	db := &publicAPISandboxQueryRowProviderMock{
		row: &publicAPISandboxRowMock{
			err: errors.New("scan failed"),
		},
	}

	store := NewEnsurePublicAPISandboxSQLStore(db)

	_, err := store.EnsureSandbox(context.Background(), EnsurePublicAPISandboxCommand{
		TenantID:    "tenant-a",
		AppID:       "app-001",
		Environment: "sandbox",
		SandboxName: "dev-sandbox",
		DataMode:    "sample_data",
		RequestedBy: "worker-01",
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
