package main

import (
	"fmt"

	cacheservice "github.com/divrigili/pix2pi-SaaS/internal/platform/cache/service"
	gatewayservice "github.com/divrigili/pix2pi-SaaS/internal/platform/gateway/service"
)

func main() {
	fmt.Println("STEP redis gateway quota testi basliyor")
	fmt.Println("--------------------------------------")

	redisSvc := cacheservice.NewRedisCacheServiceFromEnv()
	defer func() {
		_ = redisSvc.Close()
	}()

	svc := gatewayservice.NewQuotaServiceWithRedis(redisSvc)

	err := svc.TenantTanimla("tenant-001", 3)
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ tenant-001 quota tanimlandi")

	err = svc.Resetle("tenant-001")
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ test oncesi quota sayaci sifirlandi")

	err = svc.IstekGecir("tenant-001")
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ 1. quota istek gecti")

	err = svc.IstekGecir("tenant-001")
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ 2. quota istek gecti")

	err = svc.IstekGecir("tenant-001")
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ 3. quota istek gecti")

	err = svc.IstekGecir("tenant-001")
	if err != nil {
		fmt.Printf("OK ✅ 4. quota istek engellendi: %s\n", err.Error())
	} else {
		panic("4. quota istek gecmemeliydi")
	}

	kayit, err := svc.KayitGetir("tenant-001")
	if err != nil {
		panic(err)
	}
	fmt.Printf("OK ✅ kullanilan quota sayisi: %d\n", kayit.Kullanilan)

	err = svc.Resetle("tenant-001")
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ tenant-001 quota resetlendi")

	kayit, err = svc.KayitGetir("tenant-001")
	if err != nil {
		panic(err)
	}
	fmt.Printf("OK ✅ reset sonrasi kullanilan quota: %d\n", kayit.Kullanilan)

	err = svc.TenantTanimla("", 3)
	if err != nil {
		fmt.Printf("OK ✅ tenantsiz quota tanim hata verdi: %s\n", err.Error())
	} else {
		panic("tenantsiz quota tanim kabul edildi")
	}

	err = svc.IstekGecir("tenant-999")
	if err != nil {
		fmt.Printf("OK ✅ olmayan tenant quota hata verdi: %s\n", err.Error())
	} else {
		panic("olmayan tenant quota kabul edildi")
	}

	fmt.Println("OK ✅ STEP redis gateway quota testi bitti")
}
