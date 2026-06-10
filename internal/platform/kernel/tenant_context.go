package kernel

import (
	"encoding/json"
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

type tenantRow struct {
	ID       int64
	Name     string
	Active   bool
	Plan     string
	Features []byte
	OrgRoot  *string
}

func isPublicPath(path string, publicPrefixes []string) bool {
	if path == "/health" {
		return true
	}
	for _, p := range publicPrefixes {
		if p == "" {
			continue
		}
		if strings.HasPrefix(path, p) {
			return true
		}
	}
	return false
}

// TenantContextMiddleware:
// - expects tenant id either in c.Locals("tenant_id") or header X-Tenant-ID
// - if tenant_uuid also exists, validates full identity through common bridge
// - enriches locals from DB: tenant_name, tenant_active, tenant_plan, tenant_features, tenant_org_root_id
// - sets tenant_ctx_source = "db" when found
func TenantContextMiddleware(masterDB *gorm.DB, publicPrefixes []string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if isPublicPath(c.Path(), publicPrefixes) {
			return c.Next()
		}

		localTenantID := localString(c, "tenant_id")
		localTenantUUID := localString(c, "tenant_uuid")
		headerTenantID := strings.TrimSpace(c.Get("X-Tenant-ID"))

		bridge, err := ResolveTenantContextIdentity(
			localTenantID,
			localTenantUUID,
			headerTenantID,
		)
		if err != nil {
			switch err.Error() {
			case "tenancy: tenant id zorunlu":
				return c.Status(400).JSON(fiber.Map{"ok": false, "error": "X-Tenant-ID header missing"})
			case "tenancy: tenant boundary violation":
				return c.Status(401).JSON(fiber.Map{"ok": false, "error": "tenant boundary violation"})
			default:
				return c.Status(401).JSON(fiber.Map{"ok": false, "error": "tenant identity invalid"})
			}
		}

		tenantIDStr := strings.TrimSpace(bridge.TenantID)
		if tenantIDStr == "" {
			return c.Status(400).JSON(fiber.Map{"ok": false, "error": "X-Tenant-ID header missing"})
		}

		tenantID64, err := strconv.ParseInt(tenantIDStr, 10, 64)
		if err != nil {
			return c.Status(400).JSON(fiber.Map{"ok": false, "error": "X-Tenant-ID must be numeric"})
		}

		var row tenantRow
		q := `
SELECT id, name, active, plan, COALESCE(features,'{}'::jsonb)::text::bytea AS features, org_root_id::text
FROM public.tenants
WHERE id = ?
LIMIT 1
`
		tx := masterDB.Raw(q, tenantID64).Scan(&row)
		if tx.Error != nil {
			return c.Status(500).JSON(fiber.Map{"ok": false, "error": "tenant lookup failed"})
		}

		if tx.RowsAffected == 0 {
			c.Locals("tenant_exists", false)
			c.Locals("tenant_ctx_source", "db")
			return c.Status(404).JSON(fiber.Map{"ok": false, "error": "tenant not found"})
		}

		var featuresAny any = map[string]any{}
		if len(row.Features) > 0 {
			_ = json.Unmarshal(row.Features, &featuresAny)
		}

		c.Locals("tenant_id", bridge.TenantID)
		if bridge.TenantUUID != "" {
			c.Locals("tenant_uuid", bridge.TenantUUID)
		}

		c.Locals("tenant_identity_verified", bridge.IdentityVerified)
		c.Locals("tenant_header_matched", bridge.HeaderMatched)
		c.Locals("tenant_legacy_fallback", bridge.UsedLegacyFallback)

		c.Locals("tenant_exists", true)
		c.Locals("tenant_ctx_source", "db")
		c.Locals("tenant_name", row.Name)
		c.Locals("tenant_active", row.Active)
		c.Locals("tenant_plan", row.Plan)
		c.Locals("tenant_features", featuresAny)

		if row.OrgRoot != nil && *row.OrgRoot != "" {
			orgRootCopy := *row.OrgRoot
			c.Locals("tenant_org_root_id", orgRootCopy)
		} else {
			c.Locals("tenant_org_root_id", nil)
		}

		return c.Next()
	}
}
