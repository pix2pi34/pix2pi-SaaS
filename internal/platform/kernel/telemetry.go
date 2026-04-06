package kernel

import (
	"log"
	"strconv"
	"time"

	"github.com/gofiber/fiber/v2"
)

func TelemetryMiddleware() fiber.Handler {
	return func(c *fiber.Ctx) error {

		start := time.Now()

		err := c.Next()

		ms := time.Since(start).Milliseconds()

		var rid string
		if v := c.Locals("request_id"); v != nil {
			if s, ok := v.(string); ok {
				rid = s
			}
		}

		c.Set("X-Response-Time-ms", strconv.FormatInt(ms, 10))

		status := c.Response().StatusCode()

		if rid != "" {
			log.Printf("telemetry rid=%s status=%d ms=%d %s %s",
				rid, status, ms, c.Method(), c.Path())
		} else {
			log.Printf("telemetry status=%d ms=%d %s %s",
				status, ms, c.Method(), c.Path())
		}

		return err
	}
}
