package http

import (
	"time"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/auth"
	"github.com/gofiber/fiber/v2"
)

func RegisterRoutes(app *fiber.App) {

	// PUBLIC HEALTH (NO AUTH)
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"ok": true,
			"service": "identity",
		})
	})

	// AUTH GROUP
	api := app.Group("/", auth.JWTMiddleware(""))

	// WHOAMI
	api.Get("/whoami", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"user_id":     c.Locals("user_id"),
			"tenant_id":   c.Locals("tenant_id"),
			"role":        c.Locals("role"),
			"permissions": c.Locals("permissions"),
		})
	})

	// DEV TOKEN
	app.Get("/dev/token", func(c *fiber.Ctx) error {
		claims := map[string]any{
			"sub":       c.Query("sub", "dev-user"),
			"tenant_id": c.Query("tenant", "1"),
			"role":      c.Query("role", "admin"),
			"permissions": []string{
				"identity:whoami:read",
			},
			"exp": time.Now().Add(24 * time.Hour).Unix(),
		}

		token, err := auth.SignJWT(claims)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"ok": false})
		}

		return c.JSON(fiber.Map{
			"ok": true,
			"token": token,
		})
	})
}
