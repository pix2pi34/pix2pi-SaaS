package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/kernel"
	"github.com/gofiber/fiber/v2"
	"log"
	"os"
	"strings"
)

func isDevPath(path string) bool {
	return strings.HasPrefix(path, "/dev/")
}

func decodeJWTClaimsUnverified(token string) (map[string]any, error) {
	parts := strings.Split(token, ".")
	if len(parts) < 2 {
		return nil, fmt.Errorf("invalid token")
	}

	payload := parts[1]
	b, err := base64.RawURLEncoding.DecodeString(payload)
	if err != nil {
		p := payload
		if m := len(p) % 4; m != 0 {
			p += strings.Repeat("=", 4-m)
		}
		b, err = base64.URLEncoding.DecodeString(p)
		if err != nil {
			return nil, err
		}
	}

	var m map[string]any
	if err := json.Unmarshal(b, &m); err != nil {
		return nil, err
	}
	return m, nil
}

func toString(v any) string {
	if v == nil {
		return ""
	}
	return strings.TrimSpace(fmt.Sprint(v))
}

func main() {

	app := fiber.New()

	// PIX2PI_PUBLIC_HEALTH_BEFORE_MIDDLEWARE
	// Public health MUST be registered before JWT middleware
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.Status(200).JSON(fiber.Map{"ok": true, "service": "identity"})
	})

	// ============================================
	// 1️⃣ JWT → Locals middleware (EN BAŞTA)
	// ============================================

	app.Use(func(c *fiber.Ctx) error {

		if isDevPath(c.Path()) {
			return c.Next()
		}

		auth := strings.TrimSpace(c.Get("Authorization"))

		if !strings.HasPrefix(strings.ToLower(auth), "bearer ") {
			return c.Status(401).SendString("missing bearer")
		}

		token := strings.TrimSpace(auth[len("Bearer "):])

		claims, err := decodeJWTClaimsUnverified(token)
		if err != nil {
			return c.Status(401).SendString("invalid token")
		}

		role := strings.ToLower(toString(claims["role"]))
		if role == "" {
			return c.Status(403).SendString("missing role")
		}

		c.Locals("role", role)

		tenant := toString(claims["tenant"])
		if tenant != "" {
			c.Locals("tenant_id", tenant)
		}

		sub := toString(claims["sub"])
		if sub != "" {
			c.Locals("user_id", sub)
		}

		return c.Next()
	})

	// ============================================
	// 2️⃣ Tenant fallback middleware
	// ============================================

	app.Use(func(c *fiber.Ctx) error {

		if isDevPath(c.Path()) {
			return c.Next()
		}

		if c.Locals("tenant_id") != nil {
			return c.Next()
		}

		tenant := strings.TrimSpace(c.Get("X-Tenant-ID"))

		if tenant == "" {
			return c.Status(401).SendString("missing tenant")
		}

		c.Locals("tenant_id", tenant)

		return c.Next()
	})

	// ============================================
	// DEV TOKEN
	// ============================================

	RegisterDevToken(app)

	// ============================================
	// WHOAMI
	// ============================================

	app.Get("/whoami",
		kernel.Require("identity.whoami"),
		func(c *fiber.Ctx) error {

			return c.JSON(fiber.Map{
				"role":      c.Locals("role"),
				"tenant_id": c.Locals("tenant_id"),
				"user_id":   c.Locals("user_id"),
			})
		},
	)

	// ============================================
	// PERMISSIONS
	// ============================================

	app.Get("/permissions",
		kernel.Require("identity.permissions.read"),
		func(c *fiber.Ctx) error {

			role, _ := c.Locals("role").(string)

			return c.JSON(fiber.Map{
				"role":  role,
				"perms": kernel.GetRolePerms(role),
			})
		},
	)

	bind := os.Getenv("IDENTITY_BIND")
	port := os.Getenv("IDENTITY_PORT")

	if bind == "" || port == "" {
		log.Fatal("HATA: IDENTITY_BIND/IDENTITY_PORT env eksik. deploy/ports.env kaynakla (source) ve tekrar dene.")
	}

	addr := bind + ":" + port
	log.Println("🚀 Identity API listening on", addr)
	log.Fatal(app.Listen(addr))
}
