package serviceregistry

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http/httptest"
	"testing"

	"github.com/gofiber/fiber/v2"
)

type registerServiceStoreHandlerMock struct {
	result UpsertServiceInstanceResult
	err    error
}

func (m *registerServiceStoreHandlerMock) UpsertServiceInstance(_ context.Context, _ UpsertServiceInstanceCommand) (UpsertServiceInstanceResult, error) {
	return m.result, m.err
}

func TestRegisterHandlerRegister_Success(t *testing.T) {
	app := fiber.New()

	store := &registerServiceStoreHandlerMock{
		result: UpsertServiceInstanceResult{
			ServiceID:   "svc-1",
			InstanceID:  "ins-1",
			ServiceKey:  "identity-api",
			InstanceKey: "identity-api-01",
		},
	}

	usecase := NewRegisterServiceUsecase(store)
	handler := NewRegisterHandler(usecase)
	RegisterRoutes(app, handler)

	body := map[string]any{
		"service_key":                "identity-api",
		"display_name":               "Identity API",
		"service_kind":               "api",
		"visibility_scope":           "tenant",
		"protocol":                   "http",
		"base_path":                  "/api/v1",
		"health_path":                "/health",
		"default_port":               9001,
		"instance_key":               "identity-api-01",
		"node_name":                  "node-a",
		"host":                       "10.10.10.11",
		"port":                       9001,
		"status":                     "healthy",
		"heartbeat_interval_seconds": 30,
	}

	raw, _ := json.Marshal(body)
	req := httptest.NewRequest(fiber.MethodPost, "/internal/runtime/services/register", bytes.NewReader(raw))
	req.Header.Set("Content-Type", fiber.MIMEApplicationJSON)

	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("app test hatasi: %v", err)
	}

	if resp.StatusCode != fiber.StatusOK {
		t.Fatalf("beklenen 200, alinan: %d", resp.StatusCode)
	}
}

func TestRegisterHandlerRegister_InvalidJSON(t *testing.T) {
	app := fiber.New()

	store := &registerServiceStoreHandlerMock{}
	usecase := NewRegisterServiceUsecase(store)
	handler := NewRegisterHandler(usecase)
	RegisterRoutes(app, handler)

	req := httptest.NewRequest(fiber.MethodPost, "/internal/runtime/services/register", bytes.NewBufferString("{invalid"))
	req.Header.Set("Content-Type", fiber.MIMEApplicationJSON)

	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("app test hatasi: %v", err)
	}

	if resp.StatusCode != fiber.StatusBadRequest {
		t.Fatalf("beklenen 400, alinan: %d", resp.StatusCode)
	}
}

func TestRegisterHandlerRegister_ValidationError(t *testing.T) {
	app := fiber.New()

	store := &registerServiceStoreHandlerMock{}
	usecase := NewRegisterServiceUsecase(store)
	handler := NewRegisterHandler(usecase)
	RegisterRoutes(app, handler)

	body := map[string]any{
		"service_key":                "Identity API",
		"display_name":               "Identity API",
		"service_kind":               "api",
		"visibility_scope":           "tenant",
		"protocol":                   "http",
		"base_path":                  "/api/v1",
		"health_path":                "/health",
		"default_port":               9001,
		"instance_key":               "identity-api-01",
		"node_name":                  "node-a",
		"host":                       "10.10.10.11",
		"port":                       9001,
		"status":                     "healthy",
		"heartbeat_interval_seconds": 30,
	}

	raw, _ := json.Marshal(body)
	req := httptest.NewRequest(fiber.MethodPost, "/internal/runtime/services/register", bytes.NewReader(raw))
	req.Header.Set("Content-Type", fiber.MIMEApplicationJSON)

	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("app test hatasi: %v", err)
	}

	if resp.StatusCode != fiber.StatusBadRequest {
		t.Fatalf("beklenen 400, alinan: %d", resp.StatusCode)
	}
}

func TestRegisterHandlerRegister_UsecaseError(t *testing.T) {
	app := fiber.New()

	store := &registerServiceStoreHandlerMock{
		err: errors.New("db failed"),
	}

	usecase := NewRegisterServiceUsecase(store)
	handler := NewRegisterHandler(usecase)
	RegisterRoutes(app, handler)

	body := map[string]any{
		"service_key":                "identity-api",
		"display_name":               "Identity API",
		"service_kind":               "api",
		"visibility_scope":           "tenant",
		"protocol":                   "http",
		"base_path":                  "/api/v1",
		"health_path":                "/health",
		"default_port":               9001,
		"instance_key":               "identity-api-01",
		"node_name":                  "node-a",
		"host":                       "10.10.10.11",
		"port":                       9001,
		"status":                     "healthy",
		"heartbeat_interval_seconds": 30,
	}

	raw, _ := json.Marshal(body)
	req := httptest.NewRequest(fiber.MethodPost, "/internal/runtime/services/register", bytes.NewReader(raw))
	req.Header.Set("Content-Type", fiber.MIMEApplicationJSON)

	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("app test hatasi: %v", err)
	}

	if resp.StatusCode != fiber.StatusInternalServerError {
		t.Fatalf("beklenen 500, alinan: %d", resp.StatusCode)
	}
}
