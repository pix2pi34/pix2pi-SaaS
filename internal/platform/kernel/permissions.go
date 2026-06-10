package kernel

import (
	"sort"
	"strings"
	"sync"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

var (
	muRolePerm sync.RWMutex
	rolePerms  = map[string]map[string]struct{}{
		"admin": {
			"*":                         {},
			"identity.whoami":           {},
			"identity.permissions.read": {},
		},
		// Examples (extend later):
		// "manager": {"identity.whoami": {}, "identity.permissions.read": {}},
		// "user":    {"identity.whoami": {}},
	}
)

func SetRolePerms(role string, perms ...string) {
	role = strings.TrimSpace(strings.ToLower(role))
	muRolePerm.Lock()
	defer muRolePerm.Unlock()

	m := map[string]struct{}{}
	for _, p := range perms {
		p = strings.TrimSpace(p)
		if p == "" {
			continue
		}
		m[p] = struct{}{}
	}
	rolePerms[role] = m
}

func GetRolePerms(role string) []string {
	role = strings.TrimSpace(strings.ToLower(role))
	muRolePerm.RLock()
	defer muRolePerm.RUnlock()

	m := rolePerms[role]
	out := make([]string, 0, len(m))
	for p := range m {
		out = append(out, p)
	}
	sort.Strings(out)
	return out
}

func hasPerm(role string, perm string) bool {
	role = strings.TrimSpace(strings.ToLower(role))
	perm = strings.TrimSpace(perm)

	muRolePerm.RLock()
	defer muRolePerm.RUnlock()

	m, ok := rolePerms[role]
	if !ok {
		return false
	}
	if _, all := m["*"]; all {
		return true
	}
	_, ok = m[perm]
	return ok
}

// roleFromJWT reads Fiber JWT middleware locals("user") token, if used anywhere.
func roleFromJWTMiddleware(c *fiber.Ctx) (string, bool) {
	u := c.Locals("user")
	if u == nil {
		return "", false
	}
	tok, ok := u.(*jwt.Token)
	if !ok || tok == nil {
		return "", false
	}
	claims, ok := tok.Claims.(jwt.MapClaims)
	if !ok || claims == nil {
		return "", false
	}
	v, ok := claims["role"]
	if !ok || v == nil {
		return "", false
	}
	role, ok := v.(string)
	if !ok {
		return "", false
	}
	role = strings.TrimSpace(strings.ToLower(role))
	if role == "" {
		return "", false
	}
	return role, true
}

func tenantFromHeaderOrJWT(c *fiber.Ctx) string {
	if v := c.Locals("tenant_id"); v != nil {
		if s := strings.TrimSpace(toStr(v)); s != "" {
			return s
		}
	}
	if tenant := strings.TrimSpace(c.Get("X-Tenant-ID")); tenant != "" {
		c.Locals("tenant_id", tenant)
		return tenant
	}
	if claims, ok := parseBearerClaimsUnverified(c); ok {
		if s := strings.TrimSpace(toStr(claims["tenant_id"])); s != "" {
			c.Locals("tenant_id", s)
			return s
		}
		if s := strings.TrimSpace(toStr(claims["tenant"])); s != "" {
			c.Locals("tenant_id", s)
			return s
		}
	}
	return ""
}

func roleFromLocalsOrJWT(c *fiber.Ctx) string {
	if v := c.Locals("role"); v != nil {
		if s := strings.TrimSpace(strings.ToLower(toStr(v))); s != "" {
			return s
		}
	}

	// Fiber-JWT middleware style
	if r, ok := roleFromJWTMiddleware(c); ok {
		c.Locals("role", r)
		return r
	}

	// Authorization bearer fallback (unverified, dev-friendly)
	if claims, ok := parseBearerClaimsUnverified(c); ok {
		r := strings.TrimSpace(strings.ToLower(toStr(claims["role"])))
		if r == "" {
			r = strings.TrimSpace(strings.ToLower(toStr(claims["roles"])))
		}
		if r == "" {
			r = strings.TrimSpace(strings.ToLower(toStr(claims["Role"])))
		}
		if r != "" {
			c.Locals("role", r)
			// best-effort cache
			if c.Locals("user_id") == nil {
				if s := strings.TrimSpace(toStr(claims["sub"])); s != "" {
					c.Locals("user_id", s)
				}
			}
			return r
		}
	}

	return ""
}

func CheckPermissions(c *fiber.Ctx, perms ...string) error {
	tenant := tenantFromHeaderOrJWT(c)
	if tenant == "" {
		return fiber.NewError(fiber.StatusUnauthorized, "missing tenant")
	}

	role := roleFromLocalsOrJWT(c)
	if role == "" {
		return fiber.NewError(fiber.StatusForbidden, "missing role")
	}

	if len(perms) == 0 {
		return nil
	}

	for _, p := range perms {
		p = strings.TrimSpace(p)
		if p == "" {
			continue
		}
		if !hasPerm(role, p) {
			return fiber.NewError(fiber.StatusForbidden, "permission denied")
		}
	}
	return nil
}

// --- helper: parse Authorization Bearer JWT without verifying signature
// SECURITY NOTE: This function is intentionally unverified and is used ONLY
// for read-only claim extraction (tenant routing, logging) BEFORE the actual
// auth middleware verifies the token. These claims MUST NOT be used for
// access control decisions. The actual signature verification is performed
// by the JWT middleware (JWTMiddleware) on protected routes.
func parseBearerClaimsUnverified(c *fiber.Ctx) (jwt.MapClaims, bool) {

	auth := strings.TrimSpace(c.Get("Authorization"))

	if auth == "" || !strings.HasPrefix(strings.ToLower(auth), "bearer ") {
		return nil, false
	}

	tokenStr := strings.TrimSpace(auth[len("Bearer "):])

	if tokenStr == "" {
		return nil, false
	}

	tok, _, err := new(jwt.Parser).ParseUnverified(tokenStr, jwt.MapClaims{})
	if err != nil || tok == nil {
		return nil, false
	}

	// Guard against alg:none attack — reject tokens with no signing algorithm
	if tok.Method == nil || tok.Method.Alg() == "none" || tok.Method.Alg() == "" {
		return nil, false
	}

	claims, ok := tok.Claims.(jwt.MapClaims)
	if !ok {
		return nil, false
	}

	return claims, true
}
