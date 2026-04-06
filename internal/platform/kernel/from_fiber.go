package kernel

import (
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

// FromFiber creates kernel context from fiber request
func FromFiber(c *fiber.Ctx) Context {

	// try read role from JWT middleware
	if u := c.Locals("user"); u != nil {
		if tok, ok := u.(*jwt.Token); ok && tok != nil {
			if claims, ok := tok.Claims.(jwt.MapClaims); ok {
				if r, ok := claims["role"].(string); ok {
					c.Locals("role", strings.TrimSpace(strings.ToLower(r)))
				}

				if t, ok := claims["tenant"].(string); ok {
					c.Locals("tenant_id", t)
				}

				if t, ok := claims["tenant_id"].(string); ok {
					c.Locals("tenant_id", t)
				}

				if u, ok := claims["sub"].(string); ok {
					c.Locals("user_id", u)
				}
			}
		}
	}

	return Wrap(c)
}
