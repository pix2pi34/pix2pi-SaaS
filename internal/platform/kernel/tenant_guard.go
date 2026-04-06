package kernel

import (
	"fmt"
	"strings"

	"github.com/gofiber/fiber/v2"
)

// TenantGuardMiddleware enforces tenant scope on tenant-scoped endpoints.
//
// SAFE rules:
// - Public endpoints bypass: /health, /dev/*
// - If request not authenticated yet (no auth locals), don't block flow
// - If locals("tenant_id") already exists (set by JWT/auth middleware), it is source of truth and header must match
// - If token tenant is absent, header is required (legacy)
// - Canonical tenant_id stored in locals("tenant_id") as string
func TenantGuardMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {
		path := c.Path()

		// Public/unauth endpoints
		if path == "/health" || strings.HasPrefix(path, "/dev/") {
			return c.Next()
		}

		// If auth not executed yet, do not block (safe for middleware ordering)
		if c.Locals("user") == nil && c.Locals("jwt") == nil {
			return c.Next()
		}

		// Token tenant (source of truth if present)
		var tokenTenant string
		if v := c.Locals("tenant_id"); v != nil {
			switch t := v.(type) {
			case string:
				tokenTenant = strings.TrimSpace(t)
			default:
				tokenTenant = strings.TrimSpace(fmt.Sprint(t))
			}
		}

		headerTenant := strings.TrimSpace(c.Get("X-Tenant-ID"))

		// If JWT carries tenant_id => header must exist and match
		if tokenTenant != "" {
			if headerTenant == "" {
				return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
					"ok":    false,
					"error": "tenant missing",
				})
			}
			if headerTenant != tokenTenant {
				return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
					"ok":    false,
					"error": "tenant boundary violation",
				})
			}
			// Canonicalize
			c.Locals("tenant_id", tokenTenant)
			return c.Next()
		}

		// Legacy fallback: header required
		if headerTenant == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"ok":    false,
				"error": "tenant missing",
			})
		}
		c.Locals("tenant_id", headerTenant)
		return c.Next()
	}
}
