package kernel

import (
	"strings"

	tenancy "github.com/divrigili/pix2pi-SaaS/internal/platform/tenancy"
)

type TenantContextBridgeResult struct {
	TenantID            string
	TenantUUID          string
	IdentityVerified    bool
	HeaderMatched       bool
	UsedLegacyFallback  bool
}

func ResolveTenantContextIdentity(
	localTenantID string,
	localTenantUUID string,
	headerTenantID string,
) (TenantContextBridgeResult, error) {
	localTenantID = strings.TrimSpace(localTenantID)
	localTenantUUID = strings.TrimSpace(localTenantUUID)
	headerTenantID = strings.TrimSpace(headerTenantID)

	// full identity path
	if localTenantID != "" && localTenantUUID != "" {
		identity, err := tenancy.NewTenantIdentity(localTenantID, localTenantUUID)
		if err != nil {
			return TenantContextBridgeResult{}, err
		}

		matched := false
		if headerTenantID != "" {
			if err := identity.RequireHeaderMatch(headerTenantID); err != nil {
				return TenantContextBridgeResult{}, err
			}
			matched = true
		}

		return TenantContextBridgeResult{
			TenantID:         identity.TenantID,
			TenantUUID:       identity.TenantUUID,
			IdentityVerified: true,
			HeaderMatched:    matched,
		}, nil
	}

	// legacy locals path
	if localTenantID != "" {
		if headerTenantID != "" && headerTenantID != localTenantID {
			return TenantContextBridgeResult{}, tenancy.ErrTenantBoundaryViolation
		}

		return TenantContextBridgeResult{
			TenantID:           localTenantID,
			TenantUUID:         localTenantUUID,
			IdentityVerified:   false,
			HeaderMatched:      headerTenantID != "",
			UsedLegacyFallback: true,
		}, nil
	}

	// header only fallback
	if headerTenantID != "" {
		return TenantContextBridgeResult{
			TenantID:           headerTenantID,
			TenantUUID:         "",
			IdentityVerified:   false,
			HeaderMatched:      true,
			UsedLegacyFallback: true,
		}, nil
	}

	return TenantContextBridgeResult{}, tenancy.ErrEmptyTenantID
}
