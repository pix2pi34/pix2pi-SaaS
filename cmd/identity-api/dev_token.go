package main

import (
	"os"

	"github.com/gofiber/fiber/v2"
)

func startDevTokenServer() {

	bind := os.Getenv("DEV_TOKEN_BIND")
	port := os.Getenv("DEV_TOKEN_PORT")

	if port == "" {
		println("DEV TOKEN SERVER DISABLED")
		return
	}

	if bind == "" {
		bind = "127.0.0.1"
	}

	app := fiber.New()

	app.Get("/dev/token", func(c *fiber.Ctx) error {

		token := createDevToken()

		return c.JSON(fiber.Map{
			"ok":     true,
			"token":  token,
			"tenant": "1",
			"role":   "admin",
			"sub":    "1",
		})
	})

	addr := bind + ":" + port

	go func() {
		println("DEV TOKEN SERVER:", addr)
		app.Listen(addr)
	}()
}

func createDevToken() string {
	token := os.Getenv("DEV_TOKEN_VALUE")
	if token == "" {
		println("WARNING: DEV_TOKEN_VALUE not set — dev token endpoint is non-functional")
		return "invalid-dev-token-set-DEV_TOKEN_VALUE"
	}
	return token
}

func RegisterDevToken(app *fiber.App) {
	startDevTokenServer()
}
