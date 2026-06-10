package main

import (
	"os"
	"strconv"
	"strings"
)

type gatewayConfig struct {
	JWTSecret                 string
	DefaultRateLimitPerMinute int
	DefaultDailyQuota         int
	HealthTimeoutMS           int
	APITimeoutMS              int
	QueryTimeoutMS            int
}

func envString(key string, def string) string {
	val := strings.TrimSpace(os.Getenv(key))
	if val == "" {
		return def
	}
	return val
}

func envInt(key string, def int) int {
	val := strings.TrimSpace(os.Getenv(key))
	if val == "" {
		return def
	}

	n, err := strconv.Atoi(val)
	if err != nil {
		return def
	}

	return n
}

func loadGatewayConfig() gatewayConfig {
	return gatewayConfig{
		JWTSecret:                 requiredEnv("JWT_SECRET"),
		DefaultRateLimitPerMinute: envInt("GATEWAY_RATE_LIMIT_PER_MINUTE", 3),
		DefaultDailyQuota:         envInt("GATEWAY_DAILY_QUOTA", 10),
		HealthTimeoutMS:           envInt("GATEWAY_HEALTH_TIMEOUT_MS", 1500),
		APITimeoutMS:              envInt("GATEWAY_API_TIMEOUT_MS", 3000),
		QueryTimeoutMS:            envInt("GATEWAY_QUERY_TIMEOUT_MS", 5000),
	}
}

func requiredEnv(key string) string {
	value := os.Getenv(key)
	if value == "" {
		panic("required env missing: " + key)
	}
	return value
}
