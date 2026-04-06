package handler

import (
	"github.com/divrigili/pix2pi-SaaS/internal/platform/kernel"
	"github.com/gofiber/fiber/v2"
)

type Handler struct {
	svc Service
}

type Service interface {
	WhoAmI(ctx kernel.Context) (any, error)
}

func (h *Handler) WhoAmI(c *fiber.Ctx) error {

	// Fiber → Kernel context adapter
	kctx := kernel.FromFiber(c)

	resp, err := h.svc.WhoAmI(kctx)
	if err != nil {
		return err
	}

	return c.JSON(resp)
}
