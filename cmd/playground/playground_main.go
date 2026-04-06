package main

import (
	"fmt"

	gatewayservice "github.com/divrigili/pix2pi-SaaS/internal/platform/gateway/service"
)

func main() {
	fmt.Println("API gateway rate limit testi")
	fmt.Println("----------------------------")

	svc := gatewayservice.NewRateLimitService()

	err := svc.TenantTanimla("tenant-001", 3)
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ tenant-001 rate limit tanimlandi")

	err = svc.IstekGecir("tenant-001")
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ 1. istek gecti")

	err = svc.IstekGecir("tenant-001")
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ 2. istek gecti")

	err = svc.IstekGecir("tenant-001")
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ 3. istek gecti")

	err = svc.IstekGecir("tenant-001")
	if err != nil {
		fmt.Printf("OK ✅ 4. istek engellendi: %s\n", err.Error())
	} else {
		panic("4. istek gecmemeliydi")
	}

	kayit, err := svc.KayitGetir("tenant-001")
	if err != nil {
		panic(err)
	}
	fmt.Printf("OK ✅ kullanilan istek sayisi: %d\n", kayit.Kullanilan)

	err = svc.Resetle("tenant-001")
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ tenant-001 limiti resetlendi")

	kayit, err = svc.KayitGetir("tenant-001")
	if err != nil {
		panic(err)
	}
	fmt.Printf("OK ✅ reset sonrasi kullanilan: %d\n", kayit.Kullanilan)

	err = svc.TenantTanimla("", 3)
	if err != nil {
		fmt.Printf("OK ✅ tenantsiz tanim hata verdi: %s\n", err.Error())
	} else {
		panic("tenantsiz tanim kabul edildi")
	}

	err = svc.IstekGecir("tenant-999")
	if err != nil {
		fmt.Printf("OK ✅ olmayan tenant hata verdi: %s\n", err.Error())
	} else {
		panic("olmayan tenant kabul edildi")
	}

	fmt.Println("OK ✅ rate limit testleri bitti")
}
