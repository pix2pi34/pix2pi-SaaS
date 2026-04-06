package query_read_model

import (
	"github.com/gofiber/fiber/v2"
)

func Register(app *fiber.App, svc *Service) {

	app.Get("/api/query/users", func(c *fiber.Ctx) error {
		svc.GetUsers()
		return c.JSON(fiber.Map{
			"status": "ok",
			"message": "read model calisti",
		})
	})

}
