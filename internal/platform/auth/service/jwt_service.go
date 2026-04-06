package service

import (
	"errors"
	"time"

	authdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/auth/domain"
	"github.com/golang-jwt/jwt/v5"
)

type JWTService struct {
	secretKey []byte
}

func NewJWTService(secretKey string) *JWTService {
	return &JWTService{
		secretKey: []byte(secretKey),
	}
}

func (s *JWTService) TokenUret(
	userID string,
	email string,
	tenantID string,
	tenantUUID string,
) (string, error) {
	if userID == "" {
		return "", errors.New("user id zorunlu")
	}
	if email == "" {
		return "", errors.New("email zorunlu")
	}
	if tenantID == "" {
		return "", errors.New("tenant id zorunlu")
	}
	if tenantUUID == "" {
		return "", errors.New("tenant uuid zorunlu")
	}

	now := time.Now()

	claims := authdomain.TenantClaims{
		UserID:     userID,
		Email:      email,
		TenantID:   tenantID,
		TenantUUID: tenantUUID,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    "pix2pi",
			Subject:   userID,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(24 * time.Hour)),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	signedToken, err := token.SignedString(s.secretKey)
	if err != nil {
		return "", err
	}

	return signedToken, nil
}

func (s *JWTService) TokenCoz(
	tokenStr string,
) (*authdomain.TenantClaims, error) {
	if tokenStr == "" {
		return nil, errors.New("token zorunlu")
	}

	token, err := jwt.ParseWithClaims(
		tokenStr,
		&authdomain.TenantClaims{},
		func(token *jwt.Token) (interface{}, error) {
			_, ok := token.Method.(*jwt.SigningMethodHMAC)
			if !ok {
				return nil, errors.New("gecersiz signing method")
			}
			return s.secretKey, nil
		},
	)
	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*authdomain.TenantClaims)
	if !ok || !token.Valid {
		return nil, errors.New("gecersiz token claims")
	}

	if claims.TenantID == "" {
		return nil, errors.New("token icinde tenant id yok")
	}
	if claims.TenantUUID == "" {
		return nil, errors.New("token icinde tenant uuid yok")
	}

	return claims, nil
}
