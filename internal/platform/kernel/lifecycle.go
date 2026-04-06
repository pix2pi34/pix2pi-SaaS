package kernel

import (
	"time"

	"github.com/gofiber/fiber/v2"
)

type RequestLifecycle struct {
	RequestID string
	Start     time.Time
	Path      string
	Method    string
}

func LifecycleMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {

		lc := &RequestLifecycle{
			RequestID: c.Get("X-Request-ID"),
			Start:     time.Now(),
			Path:      c.Path(),
			Method:    c.Method(),
		}

		c.Locals("lifecycle", lc)

		err := c.Next()

		// request finish
		duration := time.Since(lc.Start)

		// şimdilik log yok (ileride audit engine bağlanacak)
		_ = duration

		return err
	}
}
