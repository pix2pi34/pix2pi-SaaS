package main

import (
	"fmt"
	"time"

	cacheservice "github.com/divrigili/pix2pi-SaaS/internal/platform/cache/service"
	kernel "github.com/divrigili/pix2pi-SaaS/internal/platform/kernel"
)

type fakeResolver struct {
	decision bool
	calls    int
}

func (f *fakeResolver) Allow(role, method, path string) bool {
	f.calls++
	return f.decision
}

func zorunlu(kosul bool, mesaj string) {
	if !kosul {
		panic(mesaj)
	}
}

func main() {
	fmt.Println("STEP policy cache hybrid testi basliyor")
	fmt.Println("---------------------------------------")

	redisSvc := cacheservice.NewRedisCacheServiceFromEnv()
	defer func() {
		_ = redisSvc.Close()
	}()

	err := redisSvc.Ping()
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ redis baglantisi dogrulandi")

	kernel.SetPolicyRedisCache(redisSvc)
	kernel.SetPolicyCacheTTL(120 * time.Second)
	kernel.ClearPolicyMemoryCache()
	kernel.InvalidatePolicyCache("admin", "GET", "/users")
	fmt.Println("OK ✅ test oncesi cache temizlendi")

	resolverTrue := &fakeResolver{decision: true}

	allow := kernel.ResolveWithCache(resolverTrue, "admin", "GET", "/users")
	zorunlu(allow, "ilk resolve true olmali")
	zorunlu(resolverTrue.calls == 1, "ilk resolve resolver cagrilmali")
	fmt.Println("OK ✅ ilk resolve resolver uzerinden calisti")

	allow = kernel.ResolveWithCache(resolverTrue, "admin", "GET", "/users")
	zorunlu(allow, "ikinci resolve true olmali")
	zorunlu(resolverTrue.calls == 1, "ikinci resolve L1 memory cache'ten gelmeli")
	fmt.Println("OK ✅ ikinci resolve L1 memory cache'ten geldi")

	kernel.ClearPolicyMemoryCache()

	resolverFalse := &fakeResolver{decision: false}

	allow = kernel.ResolveWithCache(resolverFalse, "admin", "GET", "/users")
	zorunlu(allow, "L2 redis cache true donmeli")
	zorunlu(resolverFalse.calls == 0, "L2 redis cache varken resolver cagrilmamali")
	fmt.Println("OK ✅ L2 redis cache dogrulandi")

	kernel.InvalidatePolicyCache("admin", "GET", "/users")
	kernel.ClearPolicyMemoryCache()

	allow = kernel.ResolveWithCache(resolverFalse, "admin", "GET", "/users")
	zorunlu(!allow, "invalidate sonrasi resolver false donmeli")
	zorunlu(resolverFalse.calls == 1, "invalidate sonrasi resolver tekrar cagrilmali")
	fmt.Println("OK ✅ invalidation sonrasi resolver tekrar devreye girdi")

	anotherResolver := &fakeResolver{decision: true}
	allow = kernel.ResolveWithCache(anotherResolver, "admin", "POST", "/users")
	zorunlu(allow, "farkli key icin yeni cache kaydi olusmali")
	zorunlu(anotherResolver.calls == 1, "farkli key resolver uzerinden gelmeli")
	fmt.Println("OK ✅ farkli key ayrimi dogrulandi")

	fmt.Println("OK ✅ STEP policy cache hybrid testi bitti")
}
