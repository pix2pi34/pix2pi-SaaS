package kernel

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gofiber/fiber/v2"
)

func newTenantGuardTestApp() *fiber.App {
	app := fiber.New()

	app.Use(func(c *fiber.Ctx) error {
		if c.Get("X-Test-Auth") == "1" {
			c.Locals("user", "user-1")
		}
		if v := c.Get("X-Test-Tenant-ID"); v != "" {
			c.Locals("tenant_id", v)
		}
		if v := c.Get("X-Test-Tenant-UUID"); v != "" {
			c.Locals("tenant_uuid", v)
		}
		return c.Next()
	})

	app.Use(TenantGuardMiddleware())

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.Status(fiber.StatusOK).JSON(fiber.Map{"ok": true})
	})

	app.Get("/orders", func(c *fiber.Ctx) error {
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"tenant_id":   c.Locals("tenant_id"),
			"tenant_uuid": c.Locals("tenant_uuid"),
		})
	})

	return app
}

func TestTenantGuardMiddleware_PublicBypass(t *testing.T) {
	app := newTenantGuardTestApp()

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestTenantGuardMiddleware_UnauthenticatedBypass(t *testing.T) {
	app := newTenantGuardTestApp()

	req := httptest.NewRequest(http.MethodGet, "/orders", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestTenantGuardMiddleware_FullIdentityMatch(t *testing.T) {
	app := newTenantGuardTestApp()

	req := httptest.NewRequest(http.MethodGet, "/orders", nil)
	req.Header.Set("X-Test-Auth", "1")
	req.Header.Set("X-Test-Tenant-ID", "tenant_42")
	req.Header.Set("X-Test-Tenant-UUID", "uuid-42")
	req.Header.Set("X-Tenant-ID", "tenant_42")

	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}

	var body map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&body); err != nil {
		t.Fatalf("unexpected decode error: %v", err)
	}

	if body["tenant_id"] != "tenant_42" {
		t.Fatalf("expected tenant_42, got %v", body["tenant_id"])
	}
	if body["tenant_uuid"] != "uuid-42" {
		t.Fatalf("expected uuid-42, got %v", body["tenant_uuid"])
	}
}

func TestTenantGuardMiddleware_FullIdentityMissingHeader(t *testing.T) {
	app := newTenantGuardTestApp()

	req := httptest.NewRequest(http.MethodGet, "/orders", nil)
	req.Header.Set("X-Test-Auth", "1")
	req.Header.Set("X-Test-Tenant-ID", "tenant_42")
	req.Header.Set("X-Test-Tenant-UUID", "uuid-42")

	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if resp.StatusCode != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", resp.StatusCode)
	}
}

func TestTenantGuardMiddleware_FullIdentityMismatch(t *testing.T) {
	app := newTenantGuardTestApp()

	req := httptest.NewRequest(http.MethodGet, "/orders", nil)
	req.Header.Set("X-Test-Auth", "1")
	req.Header.Set("X-Test-Tenant-ID", "tenant_42")
	req.Header.Set("X-Test-Tenant-UUID", "uuid-42")
	req.Header.Set("X-Tenant-ID", "tenant_99")

	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", resp.StatusCode)
	}
}

func TestTenantGuardMiddleware_LegacyHeaderFallback(t *testing.T) {
	app := newTenantGuardTestApp()

	req := httptest.NewRequest(http.MethodGet, "/orders", nil)
	req.Header.Set("X-Test-Auth", "1")
	req.Header.Set("X-Tenant-ID", "tenant_77")

	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}

	var body map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&body); err != nil {
		t.Fatalf("unexpected decode error: %v", err)
	}

	if body["tenant_id"] != "tenant_77" {
		t.Fatalf("expected tenant_77, got %v", body["tenant_id"])
	}
}
