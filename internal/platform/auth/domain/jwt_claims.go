package domain

import "github.com/golang-jwt/jwt/v5"

type TenantClaims struct {
	UserID     string `json:"user_id"`
	Email      string `json:"email"`
	TenantID   string `json:"tenant_id"`
	TenantUUID string `json:"tenant_uuid"`
	jwt.RegisteredClaims
}
