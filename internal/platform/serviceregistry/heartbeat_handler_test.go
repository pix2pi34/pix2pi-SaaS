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

type heartbeatStoreHandlerMock struct {
	result RecordHeartbeatResult
	err    error
}

func (m *heartbeatStoreHandlerMock) RecordHeartbeat(_ context.Context, _ RecordHeartbeatCommand) (RecordHeartbeatResult, error) {
	return m.result, m.err
}

func TestHeartbeatHandlerHandle_Success(t *testing.T) {
	app := fiber.New()

	store := &heartbeatStoreHandlerMock{
		result: RecordHeartbeatResult{
			NextHeartbeatInSeconds: 30,
			HealthPullRequested:    false,
		},
	}

	usecase := NewHeartbeatUsecase(store)
	handler := NewHeartbeatHandler(usecase)
	RegisterHeartbeatRoutes(app, handler)

	body := map[string]any{
		"service_key":                "identity-api",
		"instance_key":               "identity-api-01",
		"status":                     "healthy",
		"mode":                       "push",
		"response_time_ms":           25,
		"heartbeat_interval_seconds": 30,
	}

	raw, _ := json.Marshal(body)
	req := httptest.NewRequest(fiber.MethodPost, "/internal/runtime/services/heartbeat", bytes.NewReader(raw))
	req.Header.Set("Content-Type", fiber.MIMEApplicationJSON)

	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("app test hatasi: %v", err)
	}

	if resp.StatusCode != fiber.StatusOK {
		t.Fatalf("beklenen 200, alinan: %d", resp.StatusCode)
	}
}

func TestHeartbeatHandlerHandle_InvalidJSON(t *testing.T) {
	app := fiber.New()

	store := &heartbeatStoreHandlerMock{}
	usecase := NewHeartbeatUsecase(store)
	handler := NewHeartbeatHandler(usecase)
	RegisterHeartbeatRoutes(app, handler)

	req := httptest.NewRequest(fiber.MethodPost, "/internal/runtime/services/heartbeat", bytes.NewBufferString("{invalid"))
	req.Header.Set("Content-Type", fiber.MIMEApplicationJSON)

	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("app test hatasi: %v", err)
	}

	if resp.StatusCode != fiber.StatusBadRequest {
		t.Fatalf("beklenen 400, alinan: %d", resp.StatusCode)
	}
}

func TestHeartbeatHandlerHandle_ValidationError(t *testing.T) {
	app := fiber.New()

	store := &heartbeatStoreHandlerMock{}
	usecase := NewHeartbeatUsecase(store)
	handler := NewHeartbeatHandler(usecase)
	RegisterHeartbeatRoutes(app, handler)

	body := map[string]any{
		"service_key":                "identity api",
		"instance_key":               "identity-api-01",
		"status":                     "healthy",
		"mode":                       "push",
		"response_time_ms":           25,
		"heartbeat_interval_seconds": 30,
	}

	raw, _ := json.Marshal(body)
	req := httptest.NewRequest(fiber.MethodPost, "/internal/runtime/services/heartbeat", bytes.NewReader(raw))
	req.Header.Set("Content-Type", fiber.MIMEApplicationJSON)

	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("app test hatasi: %v", err)
	}

	if resp.StatusCode != fiber.StatusBadRequest {
		t.Fatalf("beklenen 400, alinan: %d", resp.StatusCode)
	}
}

func TestHeartbeatHandlerHandle_UsecaseError(t *testing.T) {
	app := fiber.New()

	store := &heartbeatStoreHandlerMock{
		err: errors.New("heartbeat persist failed"),
	}

	usecase := NewHeartbeatUsecase(store)
	handler := NewHeartbeatHandler(usecase)
	RegisterHeartbeatRoutes(app, handler)

	body := map[string]any{
		"service_key":                "identity-api",
		"instance_key":               "identity-api-01",
		"status":                     "healthy",
		"mode":                       "push",
		"response_time_ms":           25,
		"heartbeat_interval_seconds": 30,
	}

	raw, _ := json.Marshal(body)
	req := httptest.NewRequest(fiber.MethodPost, "/internal/runtime/services/heartbeat", bytes.NewReader(raw))
	req.Header.Set("Content-Type", fiber.MIMEApplicationJSON)

	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("app test hatasi: %v", err)
	}

	if resp.StatusCode != fiber.StatusInternalServerError {
		t.Fatalf("beklenen 500, alinan: %d", resp.StatusCode)
	}
}
