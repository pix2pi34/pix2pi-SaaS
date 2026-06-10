package serviceregistry

import (
	"errors"

	"github.com/gofiber/fiber/v2"
)

type RegisterServiceExecutor interface {
	Register(ctx fiber.Ctx, req RegisterServiceRequest) (RegisterServiceResponse, error)
}

type RegisterHandler struct {
	usecase *RegisterServiceUsecase
}

func NewRegisterHandler(usecase *RegisterServiceUsecase) *RegisterHandler {
	return &RegisterHandler{
		usecase: usecase,
	}
}

func (h *RegisterHandler) Register(c *fiber.Ctx) error {
	if h == nil || h.usecase == nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"ok":    false,
			"error": "service registry register handler hazir degil",
		})
	}

	var req RegisterServiceRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"ok":    false,
			"error": "gecersiz json body",
		})
	}

	resp, err := h.usecase.Register(c.UserContext(), req)
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

func RegisterRoutes(app fiber.Router, handler *RegisterHandler) {
	app.Post("/internal/runtime/services/register", handler.Register)
}
