package auth

import (
	"strings"

	"github.com/gofiber/fiber/v2"
)

// RequirePermissions checks c.Locals("permissions") and returns 403 if missing.
// Expects locals set by JWTMiddleware: c.Locals("permissions", []string)
func RequirePermissions(perms ...string) fiber.Handler {
	need := make([]string, 0, len(perms))
	for _, p := range perms {
		p = strings.TrimSpace(p)
		if p != "" {
			need = append(need, p)
		}
	}

	return func(c *fiber.Ctx) error {
		// If no perms required, allow.
		if len(need) == 0 {
			return c.Next()
		}

		raw := c.Locals("permissions")
		have := map[string]bool{}

		switch v := raw.(type) {
		case []string:
			for _, x := range v {
				x = strings.TrimSpace(x)
				if x != "" {
					have[x] = true
				}
			}
		case []interface{}:
			for _, it := range v {
				if s, ok := it.(string); ok {
					s = strings.TrimSpace(s)
					if s != "" {
						have[s] = true
					}
				}
			}
		case string:
			// tolerate: "a,b,c" or "a b c"
			for _, x := range strings.FieldsFunc(v, func(r rune) bool { return r == ',' || r == ' ' || r == ';' }) {
				x = strings.TrimSpace(x)
				if x != "" {
					have[x] = true
				}
			}
		}

		for _, p := range need {
			if !have[p] {
				return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
					"ok":    false,
					"error": "permission denied",
					"need":  p,
				})
			}
		}

		return c.Next()
	}
}
