package kernel

import "sync"

//
// ENTERPRISE POLICY CACHE ENGINE (L10)
// role + method + path cache
//

type cacheKey struct {
	Role   string
	Method string
	Path   string
}

var policyCache sync.Map

func cacheLookup(role, method, path string) (bool, bool) {
	key := cacheKey{role, method, path}
	val, ok := policyCache.Load(key)
	if !ok {
		return false, false
	}
	return val.(bool), true
}

func cacheStore(role, method, path string, allow bool) {
	key := cacheKey{role, method, path}
	policyCache.Store(key, allow)
}

//
// ENTERPRISE WRAPPER
//

func ResolveWithCache(resolver PolicyResolver, role, method, path string) bool {

	// 1) cache kontrol
	if val, ok := cacheLookup(role, method, path); ok {
		return val
	}

	// 🔥 SENİN PROJEDE METHOD ADI: Allow
	allow := resolver.Allow(role, method, path)

	// 3) cache yaz
	cacheStore(role, method, path, allow)

	return allow
}
