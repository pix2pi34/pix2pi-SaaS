package kernel

import (
	"strings"

	"github.com/gofiber/fiber/v2"
)

// Require registers the permission name(s) and enforces them at runtime.
// Example: app.Get("/whoami", kernel.Require("identity.whoami"), handler)
func Require(perms ...string) fiber.Handler {
	// normalize + register
	clean := make([]string, 0, len(perms))
	for _, p := range perms {
		p = strings.TrimSpace(p)
		if p == "" {
			continue
		}
		RegisterPermission(p)
		clean = append(clean, p)
	}

	return func(c *fiber.Ctx) error {
		if err := CheckPermissions(c, clean...); err != nil {
			return err
		}
		return c.Next()
	}
}
