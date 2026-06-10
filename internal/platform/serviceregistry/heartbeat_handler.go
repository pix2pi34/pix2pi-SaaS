package serviceregistry

import (
	"errors"

	"github.com/gofiber/fiber/v2"
)

type HeartbeatHandler struct {
	usecase *HeartbeatUsecase
}

func NewHeartbeatHandler(usecase *HeartbeatUsecase) *HeartbeatHandler {
	return &HeartbeatHandler{
		usecase: usecase,
	}
}

func (h *HeartbeatHandler) Handle(c *fiber.Ctx) error {
	if h == nil || h.usecase == nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"ok":    false,
			"error": "heartbeat handler hazir degil",
		})
	}

	var req HeartbeatRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"ok":    false,
			"error": "gecersiz json body",
		})
	}

	resp, err := h.usecase.Accept(c.UserContext(), req)
	if err != nil {
		var validationErrs ValidationErrors
		if errors.As(err, &validationErrs) {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"ok":      false,
				"error":   "validation failed",
				"details": validationErrs,
			})
		}

		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"ok":    false,
			"error": err.Error(),
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"ok":   true,
		"data": resp,
	})
}

func RegisterHeartbeatRoutes(app fiber.Router, handler *HeartbeatHandler) {
	app.Post("/internal/runtime/services/heartbeat", handler.Handle)
}
