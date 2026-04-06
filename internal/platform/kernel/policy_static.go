package kernel

import "strings"

// StaticPolicyResolver: map tabanli policy (RBAC) + basit wildcard destegi
// Key format: "GET /path" veya "GET /admin/*"
type StaticPolicyResolver struct {
	Rules map[string]map[string]bool // routeKey -> role -> allow
}

func (s StaticPolicyResolver) Allow(method, path, role string) bool {
	if s.Rules == nil {
		return false
	}
	key := method + " " + path

	// 1) exact match
	if roles, ok := s.Rules[key]; ok {
		return roles[role]
	}

	// 2) wildcard match (GET /admin/* gibi)
	for pat, roles := range s.Rules {
		if !strings.HasPrefix(pat, method+" ") {
			continue
		}
		p := strings.TrimPrefix(pat, method+" ")
		if matchWildcard(p, path) {
			return roles[role]
		}
	}

	return false
}

func matchWildcard(pattern, path string) bool {
	// destekledigimiz: "/admin/*" (prefix wildcard)
	if strings.HasSuffix(pattern, "/*") {
		prefix := strings.TrimSuffix(pattern, "/*")
		if prefix == "" {
			return true
		}
		return strings.HasPrefix(path, prefix+"/")
	}
	// exact
	return pattern == path
}
