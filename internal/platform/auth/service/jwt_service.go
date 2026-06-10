package service

import (
	"errors"
	"time"

	authdomain "github.com/divrigili/pix2pi-SaaS/internal/platform/auth/domain"
	"github.com/golang-jwt/jwt/v5"
)

const (
	DefaultJWTIssuer   = "pix2pi-auth"
	DefaultJWTAudience = "pix2pi-api"
)

type JWTService struct {
	secretKey []byte
	issuer    string
	audience  string
	ttl       time.Duration
	clockSkew time.Duration
}

func NewJWTService(secretKey string) *JWTService {
	return &JWTService{
		secretKey: []byte(secretKey),
		issuer:    DefaultJWTIssuer,
		audience:  DefaultJWTAudience,
		ttl:       24 * time.Hour,
		clockSkew: 30 * time.Second,
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
			Subject:   userID,
			Issuer:    s.issuer,
			Audience:  jwt.ClaimStrings{s.audience},
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(s.ttl)),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.secretKey)
}

func (s *JWTService) TokenCoz(
	tokenString string,
) (*authdomain.TenantClaims, error) {
	token, err := jwt.ParseWithClaims(
		tokenString,
		&authdomain.TenantClaims{},
		func(token *jwt.Token) (interface{}, error) {
			_, ok := token.Method.(*jwt.SigningMethodHMAC)
			if !ok {
				return nil, errors.New("gecersiz signing method")
			}
			return s.secretKey, nil
		},
		jwt.WithoutClaimsValidation(),
	)
	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*authdomain.TenantClaims)
	if !ok || !token.Valid {
		return nil, errors.New("gecersiz token claims")
	}

	contract := authdomain.JWTClaimContract{
		Subject:       claims.Subject,
		Issuer:        claims.Issuer,
		Audience:      firstAudience(claims.Audience),
		TenantID:      claims.TenantID,
		TenantUUID:    claims.TenantUUID,
		ExpiresAtUnix: numericDateUnix(claims.ExpiresAt),
		IssuedAtUnix:  numericDateUnix(claims.IssuedAt),
		NotBeforeUnix: numericDateUnix(claims.NotBefore),
	}

	err = contract.Validate(
		authdomain.JWTValidationPolicy{
			RequiredIssuer:   s.issuer,
			RequiredAudience: s.audience,
			ClockSkew:        s.clockSkew,
		},
		time.Now(),
	)
	if err != nil {
		return nil, err
	}

	return claims, nil
}

func firstAudience(aud jwt.ClaimStrings) string {
	if len(aud) == 0 {
		return ""
	}
	return aud[0]
}

func numericDateUnix(v *jwt.NumericDate) int64 {
	if v == nil {
		return 0
	}
	return v.Time.Unix()
}
