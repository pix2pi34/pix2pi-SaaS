package main

import (
	"github.com/gofiber/fiber/v2"
	"net/http"
	"io/ioutil"
)

func check(url string) string {

	resp, err := http.Get(url)

	if err != nil {
		return "FAIL"
	}

	defer resp.Body.Close()

	body, _ := ioutil.ReadAll(resp.Body)

	if resp.StatusCode == 200 && len(body) > 0 {
		return "OK"
	}

	return "FAIL"
}

func main() {

	app := fiber.New()

	app.Static("/", "./cmd/control-panel/ui")

	app.Get("/health", func(c *fiber.Ctx) error {

		mission := check("http://127.0.0.1:5860/health")

		return c.JSON(fiber.Map{
			"service": "pix2pi-control-panel",
			"status":  "ok",
			"mission_control": mission,
		})
	})

	app.Listen(":5858")
}
