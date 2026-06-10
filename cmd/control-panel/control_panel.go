package main

import (
	"bytes"
	"io"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
)

func envOrDefault(key string, fallback string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}

	return value
}

func normalizePort(port string) string {
	port = strings.TrimSpace(port)
	port = strings.TrimPrefix(port, ":")
	if port == "" {
		return "7100"
	}

	return port
}

func check(url string) string {
	client := &http.Client{
		Timeout: 2 * time.Second,
	}

	resp, err := client.Get(url)
	if err != nil {
		return "FAIL"
	}
	defer resp.Body.Close()

	_, _ = io.Copy(io.Discard, resp.Body)

	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		return "OK"
	}

	return "FAIL"
}

func proxyToTarget(targetBaseURL string, stripPrefix string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		originalURL := c.OriginalURL()
		targetPath := originalURL

		if stripPrefix != "" && strings.HasPrefix(targetPath, stripPrefix) {
			targetPath = strings.TrimPrefix(targetPath, stripPrefix)
			if targetPath == "" {
				targetPath = "/"
			}
		}

		targetURL := strings.TrimRight(targetBaseURL, "/") + targetPath

		req, err := http.NewRequest(
			c.Method(),
			targetURL,
			bytes.NewReader(c.Body()),
		)
		if err != nil {
			return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{
				"error": "proxy request olusturulamadi",
			})
		}

		c.Request().Header.VisitAll(func(key, value []byte) {
			headerKey := string(key)
			if strings.EqualFold(headerKey, "Host") {
				return
			}
			req.Header.Set(headerKey, string(value))
		})

		client := &http.Client{
			Timeout: 10 * time.Second,
		}

		resp, err := client.Do(req)
		if err != nil {
			return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{
				"error": "upstream servise ulasilamadi",
			})
		}
		defer resp.Body.Close()

		for key, values := range resp.Header {
			if strings.EqualFold(key, "Content-Length") ||
				strings.EqualFold(key, "Transfer-Encoding") ||
				strings.EqualFold(key, "Connection") {
				continue
			}

			for _, value := range values {
				c.Append(key, value)
			}
		}

		c.Status(resp.StatusCode)
		_, err = io.Copy(c.Response().BodyWriter(), resp.Body)
		return err
	}
}

func main() {
	panelPort := normalizePort(envOrDefault("PANEL_PORT", "7100"))
	missionPort := normalizePort(envOrDefault("MISSION_PORT", "5860"))
	apiGatewayPort := normalizePort(envOrDefault("API_GATEWAY_PORT", "9010"))
	jobsRuntimePort := normalizePort(envOrDefault("JOBS_RUNTIME_PORT", "5880"))
	webhookRuntimePort := normalizePort(envOrDefault("WEBHOOK_RUNTIME_PORT", "5890"))
	workflowRuntimePort := normalizePort(envOrDefault("WORKFLOW_RUNTIME_PORT", "5900"))
	pluginRuntimePort := normalizePort(envOrDefault("PLUGIN_RUNTIME_PORT", "5910"))
	publicAPIRuntimePort := normalizePort(envOrDefault("PUBLICAPI_RUNTIME_PORT", "5920"))
	notificationRuntimePort := normalizePort(envOrDefault("NOTIFICATION_RUNTIME_PORT", "5930"))
	earlyWarningRuntimePort := normalizePort(envOrDefault("EARLY_WARNING_RUNTIME_PORT", "5940"))
	incidentAuditRuntimePort := normalizePort(envOrDefault("INCIDENT_AUDIT_RUNTIME_PORT", "5950"))
	runtimeTopologyPort := normalizePort(envOrDefault("RUNTIME_TOPOLOGY_PORT", "5960"))
	realtimeRuntimePort := normalizePort(envOrDefault("REALTIME_RUNTIME_PORT", "5970"))

	app := fiber.New()

	app.Get("/health", func(c *fiber.Ctx) error {
		mission := check("http://127.0.0.1:" + missionPort + "/health")
		jobsRuntime := check("http://127.0.0.1:" + jobsRuntimePort + "/health")
		webhookRuntime := check("http://127.0.0.1:" + webhookRuntimePort + "/health")
		workflowRuntime := check("http://127.0.0.1:" + workflowRuntimePort + "/health")
		pluginRuntime := check("http://127.0.0.1:" + pluginRuntimePort + "/health")
		publicAPIRuntime := check("http://127.0.0.1:" + publicAPIRuntimePort + "/health")
		notificationRuntime := check("http://127.0.0.1:" + notificationRuntimePort + "/health")
		earlyWarningRuntime := check("http://127.0.0.1:" + earlyWarningRuntimePort + "/health")
		incidentAuditRuntime := check("http://127.0.0.1:" + incidentAuditRuntimePort + "/health")
		runtimeTopology := check("http://127.0.0.1:" + runtimeTopologyPort + "/health")
		realtimeRuntime := check("http://127.0.0.1:" + realtimeRuntimePort + "/health")

		return c.JSON(fiber.Map{
			"service":                  "pix2pi-control-panel",
			"status":                   "ok",
			"panel_port":               panelPort,
			"api_gateway":              check("http://127.0.0.1:" + apiGatewayPort + "/health"),
			"mission_control":          mission,
			"jobs_runtime":             jobsRuntime,
			"webhook_runtime":          webhookRuntime,
			"workflow_runtime":         workflowRuntime,
			"plugin_runtime":           pluginRuntime,
			"publicapi_runtime":        publicAPIRuntime,
			"notification_runtime":     notificationRuntime,
			"early_warning_runtime":    earlyWarningRuntime,
			"incident_audit_runtime":   incidentAuditRuntime,
			"runtime_topology_runtime": runtimeTopology,
			"realtime_runtime":         realtimeRuntime,
		})
	})

	app.All("/api/*", proxyToTarget("http://127.0.0.1:"+apiGatewayPort, ""))
	app.All("/mission-control/*", proxyToTarget("http://127.0.0.1:"+missionPort, "/mission-control"))
	app.All("/jobs-runtime/*", proxyToTarget("http://127.0.0.1:"+jobsRuntimePort, "/jobs-runtime"))
	app.All("/webhook-runtime/*", proxyToTarget("http://127.0.0.1:"+webhookRuntimePort, "/webhook-runtime"))
	app.All("/workflow-runtime/*", proxyToTarget("http://127.0.0.1:"+workflowRuntimePort, "/workflow-runtime"))
	app.All("/plugin-runtime/*", proxyToTarget("http://127.0.0.1:"+pluginRuntimePort, "/plugin-runtime"))
	app.All("/publicapi-runtime/*", proxyToTarget("http://127.0.0.1:"+publicAPIRuntimePort, "/publicapi-runtime"))
	app.All("/notification-runtime/*", proxyToTarget("http://127.0.0.1:"+notificationRuntimePort, "/notification-runtime"))
	app.All("/early-warning-runtime/*", proxyToTarget("http://127.0.0.1:"+earlyWarningRuntimePort, "/early-warning-runtime"))
	app.All("/incident-audit-runtime/*", proxyToTarget("http://127.0.0.1:"+incidentAuditRuntimePort, "/incident-audit-runtime"))
	app.All("/runtime-topology/*", proxyToTarget("http://127.0.0.1:"+runtimeTopologyPort, "/runtime-topology"))
	app.All("/realtime-runtime/*", proxyToTarget("http://127.0.0.1:"+realtimeRuntimePort, "/realtime-runtime"))

	app.Static("/", "./cmd/control-panel/ui")

	app.Get("/*", func(c *fiber.Ctx) error {
		return c.SendFile("./cmd/control-panel/ui/index.html")
	})

	if err := app.Listen(":" + panelPort); err != nil {
		panic(err)
	}
}
