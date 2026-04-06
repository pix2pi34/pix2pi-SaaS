package auth

import (
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

type Claims struct {
	UserID      string   `json:"sub"`
	TenantID    string   `json:"tenant_id"`
	Role        string   `json:"role"`
	Permissions []string `json:"permissions"`
	jwt.RegisteredClaims
}

func jwtSecretDefault() string {
	s := os.Getenv("JWT_SECRET")
	if s == "" {
		s = "dev-secret"
	}
	return s
}

func SignJWTWithClaims(secret string, c Claims) (string, error) {
	c.RegisteredClaims = jwt.RegisteredClaims{
		ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
		IssuedAt:  jwt.NewNumericDate(time.Now()),
	}

	t := jwt.NewWithClaims(jwt.SigningMethodHS256, c)
	return t.SignedString([]byte(secret))
}

func SignJWT(m map[string]any) (string, error) {
	secret := fmt.Sprint(m["secret"])
	if secret == "" {
		secret = jwtSecretDefault()
	}

	claims := Claims{
		UserID:   fmt.Sprint(m["sub"]),
		TenantID: fmt.Sprint(m["tenant_id"]),
		Role:     fmt.Sprint(m["role"]),
	}

	return SignJWTWithClaims(secret, claims)
}

func JWTMiddleware(secret string) fiber.Handler {

	if secret == "" {
		secret = jwtSecretDefault()
	}

	return func(ctx *fiber.Ctx) error {

		// HEALTH BYPASS
		p := ctx.Path()
		if p == "/health" || p == "/ready" || p == "/live" {
			return ctx.Next()
		}

		authHeader := ctx.Get("Authorization")
		if authHeader == "" {
			return ctx.Status(401).SendString("missing bearer")
		}

		if !strings.HasPrefix(strings.ToLower(authHeader), "bearer ") {
			return ctx.Status(401).SendString("invalid bearer")
		}

		tokenStr := strings.TrimSpace(authHeader[7:])

		token, err := jwt.ParseWithClaims(
			tokenStr,
			&Claims{},
			func(token *jwt.Token) (interface{}, error) {
				return []byte(secret), nil
			},
		)

		if err != nil || !token.Valid {
			return ctx.Status(401).SendString("invalid token")
		}

		claims := token.Claims.(*Claims)

		ctx.Locals("user_id", claims.UserID)
		ctx.Locals("tenant_id", claims.TenantID)
		ctx.Locals("role", claims.Role)
		ctx.Locals("permissions", claims.Permissions)

		return ctx.Next()
	}
}
