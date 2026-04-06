package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/joho/godotenv"
)

type Config struct {
	JWTSecret string
	AppName   string
	AppEnv    string
	LogLevel  string

	IdentityPort int
	FinancePort  int
	GatewayPort  int

	DBHost     string
	DBPort     int
	DBName     string
	DBUser     string
	DBPassword string

	FiberPrefork           bool
	FiberDisableStartupMsg bool
}

// Load loads configs/env/.env.local by default,
// but allows override with ENV_FILE=/path/to/file
func Load() (*Config, error) {
	envFile := get("ENV_FILE", "configs/env/.env.local")
	_ = godotenv.Overload(envFile)

	cfg := &Config{
		AppName:  get("APP_NAME", "pix2pi-saas"),
		AppEnv:   get("APP_ENV", "local"),
		LogLevel: get("LOG_LEVEL", "info"),

		IdentityPort: mustInt("IDENTITY_PORT", 9001),
		FinancePort:  mustInt("FINANCE_PORT", 9002),
		GatewayPort:  mustInt("GATEWAY_PORT", 9003),

		DBHost:     get("DB_HOST", "127.0.0.1"),
		DBPort:     mustInt("DB_PORT", 5432),
		DBName:     get("DB_NAME", "pix2pi_saas"),
		DBUser:     get("DB_USER", "pix2pi_admin"),
		DBPassword: get("DB_PASSWORD", ""),

		FiberPrefork:           mustBool("FIBER_PREFORK", false),
		FiberDisableStartupMsg: mustBool("FIBER_DISABLE_STARTUP_MSG", false),
	}

	// Minimal validation
	if strings.TrimSpace(cfg.DBPassword) == "" {
		return nil, fmt.Errorf("DB_PASSWORD is empty (set it in %s)", envFile)
	}
	return cfg, nil
}

func get(key, def string) string {
	v := os.Getenv(key)
	if v == "" {
		return def
	}
	return v
}

func mustInt(key string, def int) int {
	v := os.Getenv(key)
	if v == "" {
		return def
	}
	n, err := strconv.Atoi(v)
	if err != nil {
		return def
	}
	return n
}

func mustBool(key string, def bool) bool {
	v := strings.ToLower(strings.TrimSpace(os.Getenv(key)))
	if v == "" {
		return def
	}
	return v == "1" || v == "true" || v == "yes" || v == "y"
}

func getEnv(key, def string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return def
}
