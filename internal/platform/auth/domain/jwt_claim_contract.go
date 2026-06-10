package domain

import (
	"errors"
	"time"
)

var (
	ErrJWTSubjectRequired        = errors.New("auth: jwt subject required")
	ErrJWTIssuerRequired         = errors.New("auth: jwt issuer required")
	ErrJWTAudienceRequired       = errors.New("auth: jwt audience required")
	ErrJWTTenantIDRequired       = errors.New("auth: jwt tenant id required")
	ErrJWTTenantUUIDRequired     = errors.New("auth: jwt tenant uuid required")
	ErrJWTExpiresAtRequired      = errors.New("auth: jwt expires at required")
	ErrJWTIssuedAtRequired       = errors.New("auth: jwt issued at required")
	ErrJWTInvalidIssuer          = errors.New("auth: jwt invalid issuer")
	ErrJWTInvalidAudience        = errors.New("auth: jwt invalid audience")
	ErrJWTExpired                = errors.New("auth: jwt expired")
	ErrJWTNotYetValid            = errors.New("auth: jwt not yet valid")
	ErrJWTIssuedAtInFuture       = errors.New("auth: jwt issued at in future")
	ErrJWTInvalidExpiryWindow    = errors.New("auth: jwt invalid expiry window")
	ErrJWTNegativeClockSkew      = errors.New("auth: jwt negative clock skew")
)

type JWTValidationPolicy struct {
	RequiredIssuer   string
	RequiredAudience string
	ClockSkew        time.Duration
}

func (p JWTValidationPolicy) Validate() error {
	if p.ClockSkew < 0 {
		return ErrJWTNegativeClockSkew
	}
	return nil
}

type JWTClaimContract struct {
	Subject      string
	Issuer       string
	Audience     string
	TenantID     string
	TenantUUID   string
	ExpiresAtUnix int64
	IssuedAtUnix  int64
	NotBeforeUnix int64
}

func (c JWTClaimContract) Validate(
	policy JWTValidationPolicy,
	now time.Time,
) error {
	if err := policy.Validate(); err != nil {
		return err
	}

	if c.Subject == "" {
		return ErrJWTSubjectRequired
	}
	if c.Issuer == "" {
		return ErrJWTIssuerRequired
	}
	if c.Audience == "" {
		return ErrJWTAudienceRequired
	}
	if c.TenantID == "" {
		return ErrJWTTenantIDRequired
	}
	if c.TenantUUID == "" {
		return ErrJWTTenantUUIDRequired
	}
	if c.ExpiresAtUnix <= 0 {
		return ErrJWTExpiresAtRequired
	}
	if c.IssuedAtUnix <= 0 {
		return ErrJWTIssuedAtRequired
	}

	if policy.RequiredIssuer != "" && c.Issuer != policy.RequiredIssuer {
		return ErrJWTInvalidIssuer
	}
	if policy.RequiredAudience != "" && c.Audience != policy.RequiredAudience {
		return ErrJWTInvalidAudience
	}

	expAt := time.Unix(c.ExpiresAtUnix, 0)
	issuedAt := time.Unix(c.IssuedAtUnix, 0)

	if expAt.Before(issuedAt) {
		return ErrJWTInvalidExpiryWindow
	}

	if now.Add(policy.ClockSkew).Before(issuedAt) {
		return ErrJWTIssuedAtInFuture
	}

	if now.Add(-policy.ClockSkew).After(expAt) {
		return ErrJWTExpired
	}

	if c.NotBeforeUnix > 0 {
		notBefore := time.Unix(c.NotBeforeUnix, 0)

		if notBefore.After(expAt) {
			return ErrJWTInvalidExpiryWindow
		}

		if now.Add(policy.ClockSkew).Before(notBefore) {
			return ErrJWTNotYetValid
		}
	}

	return nil
}
