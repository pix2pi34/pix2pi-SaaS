package kernel

import (
	"strconv"
	"sync"
	"time"

	cacheservice "github.com/divrigili/pix2pi-SaaS/internal/platform/cache/service"
)

//
// ENTERPRISE POLICY CACHE ENGINE (L1 + L2)
// L1 = process memory
// L2 = redis
//

type cacheKey struct {
	Role   string
	Method string
	Path   string
}

var policyCache sync.Map

var policyRedisCache *cacheservice.RedisCacheService

var policyCacheTTL = 10 * time.Minute

const (
	policyCacheTenant = "platform"
	policyCacheEntity = "policy_cache"
)

func SetPolicyRedisCache(redisSvc *cacheservice.RedisCacheService) {
	policyRedisCache = redisSvc
}

func SetPolicyCacheTTL(ttl time.Duration) {
	if ttl <= 0 {
		return
	}

	policyCacheTTL = ttl
}

func policyKeyOlustur(role, method, path string) cacheKey {
	return cacheKey{
		Role:   role,
		Method: method,
		Path:   path,
	}
}

func policyRedisKey(role, method, path string) string {
	return role + "|" + method + "|" + path
}

func cacheLookup(role, method, path string) (bool, bool) {
	key := policyKeyOlustur(role, method, path)

	// L1 memory
	val, ok := policyCache.Load(key)
	if ok {
		return val.(bool), true
	}

	// L2 redis
	if policyRedisCache != nil {
		redisKey := policyRedisKey(role, method, path)

		deger, err := policyRedisCache.Get(
			policyCacheTenant,
			policyCacheEntity,
			redisKey,
		)
		if err == nil {
			allow, parseErr := strconv.ParseBool(deger)
			if parseErr == nil {
				policyCache.Store(key, allow)
				return allow, true
			}
		}
	}

	return false, false
}

func cacheStore(role, method, path string, allow bool) {
	key := policyKeyOlustur(role, method, path)

	// L1 memory
	policyCache.Store(key, allow)

	// L2 redis
	if policyRedisCache != nil {
		redisKey := policyRedisKey(role, method, path)

		_ = policyRedisCache.Set(
			policyCacheTenant,
			policyCacheEntity,
			redisKey,
			strconv.FormatBool(allow),
			policyCacheTTL,
		)
	}
}

func InvalidatePolicyCache(role, method, path string) {
	key := policyKeyOlustur(role, method, path)

	policyCache.Delete(key)

	if policyRedisCache != nil {
		redisKey := policyRedisKey(role, method, path)

		_ = policyRedisCache.Delete(
			policyCacheTenant,
			policyCacheEntity,
			redisKey,
		)
	}
}

func ClearPolicyMemoryCache() {
	policyCache.Range(func(key, value any) bool {
		policyCache.Delete(key)
		return true
	})
}

func ResolveWithCache(resolver PolicyResolver, role, method, path string) bool {
	// 1) cache kontrol
	if val, ok := cacheLookup(role, method, path); ok {
		return val
	}

	// 2) resolver
	allow := resolver.Allow(role, method, path)

	// 3) cache yaz
	cacheStore(role, method, path, allow)

	return allow
}
