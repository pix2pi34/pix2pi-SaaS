package kernel

import (
	"fmt"
	"strings"

	"gorm.io/gorm"
)

// DBPolicyResolver: tenant schema içindeki policy_rules tablosundan karar verir.
// Route eşleşmesi:
// 1) exact: "GET /admin/ping"
// 2) wildcard: "GET /admin/*"
type DBPolicyResolver struct {
	DB     *gorm.DB
	Schema string // ör: "tenant_7"
}

func (r DBPolicyResolver) Allow(method, path, role string) bool {
	if r.DB == nil || r.Schema == "" || role == "" {
		return false
	}

	routeExact := fmt.Sprintf("%s %s", method, path)

	// 1) exact match
	var allowExact *bool
	r.DB.Raw(
		fmt.Sprintf(`SELECT allow FROM %s.policy_rules WHERE route = ? AND role = ? LIMIT 1`, r.Schema),
		routeExact, role,
	).Scan(&allowExact)
	if allowExact != nil {
		return *allowExact
	}

	// 2) wildcard match: "/admin/*"
	// path prefix üret: "/admin" => "GET /admin/*"
	parts := strings.Split(strings.Trim(path, "/"), "/")
	if len(parts) >= 1 && parts[0] != "" {
		wild := fmt.Sprintf("%s /%s/*", method, parts[0])

		var allowWild *bool
		r.DB.Raw(
			fmt.Sprintf(`SELECT allow FROM %s.policy_rules WHERE route = ? AND role = ? LIMIT 1`, r.Schema),
			wild, role,
		).Scan(&allowWild)

		if allowWild != nil {
			return *allowWild
		}
	}

	// deny by default (DB tarafı)
	return false
}
