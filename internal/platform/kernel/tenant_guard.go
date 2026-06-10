package kernel

import (
	"fmt"
	"strings"

	"github.com/gofiber/fiber/v2"

	tenancy "github.com/divrigili/pix2pi-SaaS/internal/platform/tenancy"
)

// TenantGuardMiddleware enforces tenant scope on tenant-scoped endpoints.
//
// SAFE rules:
// - Public endpoints bypass: /health, /dev/*
// - If request not authenticated yet (no auth locals), don't block flow
// - If locals("tenant_id") already exists (set by JWT/auth middleware), it is source of truth and header must match
// - If token tenant identity is complete (tenant_id + tenant_uuid), common tenancy contract is used
// - If token tenant identity is partial/legacy, tenant_id based fallback is preserved
// - Canonical tenant_id / tenant_uuid stored in locals
func TenantGuardMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {
		path := c.Path()

		if path == "/health" || strings.HasPrefix(path, "/dev/") {
			return c.Next()
		}

		if c.Locals("user") == nil && c.Locals("jwt") == nil {
			return c.Next()
		}

		tokenTenantID := localString(c, "tenant_id")
		tokenTenantUUID := localString(c, "tenant_uuid")
		headerTenantID := strings.TrimSpace(c.Get("X-Tenant-ID"))

		// Full contract path: tenant_id + tenant_uuid both present
		if tokenTenantID != "" && tokenTenantUUID != "" {
			identity, err := tenancy.NewTenantIdentity(tokenTenantID, tokenTenantUUID)
			if err != nil {
				return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
					"ok":    false,
					"error": "tenant identity invalid",
				})
			}

			if err := identity.RequireHeaderMatch(headerTenantID); err != nil {
				if err == tenancy.ErrEmptyTenantID {
					return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
						"ok":    false,
						"error": "tenant missing",
					})
				}

				return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
					"ok":    false,
					"error": "tenant boundary violation",
				})
			}

			c.Locals("tenant_id", identity.TenantID)
			c.Locals("tenant_uuid", identity.TenantUUID)
			return c.Next()
		}

		// Legacy token path: only tenant_id exists
		if tokenTenantID != "" {
			if headerTenantID == "" {
				return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
					"ok":    false,
					"error": "tenant missing",
				})
			}

			if headerTenantID != tokenTenantID {
				return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
					"ok":    false,
					"error": "tenant boundary violation",
				})
			}

			c.Locals("tenant_id", tokenTenantID)
			if tokenTenantUUID != "" {
				c.Locals("tenant_uuid", tokenTenantUUID)
			}
			return c.Next()
		}

		// Legacy fallback: header only
		if headerTenantID == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"ok":    false,
				"error": "tenant missing",
			})
		}

		c.Locals("tenant_id", headerTenantID)
		return c.Next()
	}
}

func localString(c *fiber.Ctx, key string) string {
	v := c.Locals(key)
	if v == nil {
		return ""
	}

	switch t := v.(type) {
	case string:
		return strings.TrimSpace(t)
	default:
		return strings.TrimSpace(fmt.Sprint(t))
	}
}
