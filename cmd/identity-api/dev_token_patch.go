package main

import (
	"fmt"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

func buildDevToken(role, tenant, sub string) (string, error) {

	secret := os.Getenv("JWT_SECRET")
	if secret == "" || len(secret) < 32 {
		return "", fmt.Errorf("security: JWT_SECRET must be set and at least 32 characters")
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
