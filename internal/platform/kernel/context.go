package kernel

import (
	"fmt"
	"strings"

	"github.com/gofiber/fiber/v2"
)

type Context interface {
	Raw() any
	TenantID() string
	Role() string
	UserID() string
	RequestID() string
}

type fiberContext struct {
	c *fiber.Ctx
}

func Wrap(c *fiber.Ctx) Context {
	return fiberContext{c: c}
}

func (f fiberContext) Raw() any { return f.c }

func toStr(v any) string {
	if v == nil {
		return ""
	}
	return strings.TrimSpace(fmt.Sprint(v))
}

func (f fiberContext) TenantID() string {
	if v := f.c.Locals("tenant_id"); v != nil {
		return toStr(v)
	}

	if tenant := strings.TrimSpace(f.c.Get("X-Tenant-ID")); tenant != "" {
		f.c.Locals("tenant_id", tenant)
		return tenant
	}

	if claims, ok := parseBearerClaimsUnverified(f.c); ok {
		if t := strings.TrimSpace(toStr(claims["tenant"])); t != "" {
			f.c.Locals("tenant_id", t)
			return t
		}
	}

	return ""
}

func (f fiberContext) Role() string {
	if v := f.c.Locals("role"); v != nil {
		r := strings.ToLower(toStr(v))
		if r != "" {
			return r
		}
	}

	if claims, ok := parseBearerClaimsUnverified(f.c); ok {
		r := strings.ToLower(strings.TrimSpace(toStr(claims["role"])))
		if r == "" {
			r = strings.ToLower(strings.TrimSpace(toStr(claims["roles"])))
		}
		if r != "" {
			f.c.Locals("role", r)
			return r
		}
	}

	return ""
}

func (f fiberContext) UserID() string {
	if v := f.c.Locals("user_id"); v != nil {
		return toStr(v)
	}

	if claims, ok := parseBearerClaimsUnverified(f.c); ok {
		if sub := strings.TrimSpace(toStr(claims["sub"])); sub != "" {
			f.c.Locals("user_id", sub)
			return sub
		}
	}

	return ""
}

func (f fiberContext) RequestID() string {
	if v := strings.TrimSpace(f.c.Get("X-Request-ID")); v != "" {
		return v
	}

	if v := f.c.Locals("request_id"); v != nil {
		return toStr(v)
	}

	return ""
}
