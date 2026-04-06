package middleware

import (
	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

func Protected() fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")
		if len(authHeader) <= 7 || authHeader[:7] != "Bearer " {
			return c.Status(401).JSON(fiber.Map{"error": "Token eksik veya hatalı"})
		}
		tokenString := authHeader[7:]

		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fiber.ErrUnauthorized
			}
			// AYNI ŞİFRE: sivas-kangali-guvenlik-duvari
			return []byte("sivas-kangali-guvenlik-duvari"), nil
		})

		if err != nil || !token.Valid {
			return c.Status(401).JSON(fiber.Map{"error": "Geçersiz veya süresi dolmuş token"})
		}

		// Token geçerli, bilgileri kaydet
		claims, _ := token.Claims.(jwt.MapClaims)
		c.Locals("user_id", claims["user_id"])
		c.Locals("tenant_id", claims["tenant_id"])
		return c.Next()
	}
}
