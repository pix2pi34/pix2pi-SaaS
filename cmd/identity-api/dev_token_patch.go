package main

import (
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

func buildDevToken(role, tenant, sub string) (string, error) {

	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "dev_secret_change_me"
	}

	claims := jwt.MapClaims{
		"role":   role,
		"tenant": tenant,
		"sub":    sub,
		"exp":    time.Now().Add(24 * time.Hour).Unix(),
	}

	t := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return t.SignedString([]byte(secret))
}
