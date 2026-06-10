package main

import (
	"errors"
	"fmt"
	"time"

	cacheservice "github.com/divrigili/pix2pi-SaaS/internal/platform/cache/service"
)

func zorunlu(kosul bool, mesaj string) {
	if !kosul {
		panic(mesaj)
	}
}

func main() {
	fmt.Println("STEP cache pattern clean testi basliyor")
	fmt.Println("---------------------------------------")

	svc := cacheservice.NewRedisCacheServiceFromEnv()
	defer func() {
		_ = svc.Close()
	}()

	err := svc.Ping()
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ redis baglantisi dogrulandi")

	_, err = svc.DeleteEntityNamespace("t1", "product")
	if err != nil {
		panic(err)
	}
	_, err = svc.DeleteEntityNamespace("t1", "order")
	if err != nil {
		panic(err)
	}
	_, err = svc.DeleteEntityNamespace("t2", "product")
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ test oncesi namespace temizlendi")

	err = svc.Set("t1", "product", "p1", "kalem", 300*time.Second)
	if err != nil {
		panic(err)
	}
	err = svc.Set("t1", "product", "p2", "defter", 300*time.Second)
	if err != nil {
		panic(err)
	}
	err = svc.Set("t1", "order", "o1", "siparis-1", 300*time.Second)
	if err != nil {
		panic(err)
	}
	err = svc.Set("t2", "product", "p1", "silgi", 300*time.Second)
	if err != nil {
		panic(err)
	}
	fmt.Println("OK ✅ test verileri yazildi")

	pattern, err := svc.PatternOlustur("t1", "product", "*")
	if err != nil {
		panic(err)
	}
	fmt.Printf("OK ✅ pattern olustu: %s\n", pattern)

	silinen, err := svc.DeleteByPattern("t1", "product", "*")
	if err != nil {
		panic(err)
	}
	zorunlu(silinen == 2, "t1 product altinda 2 key silinmeli")
	fmt.Printf("OK ✅ pattern delete dogrulandi | silinen=%d\n", silinen)

	_, err = svc.Get("t1", "product", "p1")
	zorunlu(errors.Is(err, cacheservice.ErrCacheKeyBulunamadi), "t1 product p1 silinmis olmali")

	_, err = svc.Get("t1", "product", "p2")
	zorunlu(errors.Is(err, cacheservice.ErrCacheKeyBulunamadi), "t1 product p2 silinmis olmali")
	fmt.Println("OK ✅ hedef entity keyleri silindi")

	v, err := svc.Get("t1", "order", "o1")
	if err != nil {
		panic(err)
	}
	zorunlu(v == "siparis-1", "t1 order o1 durmali")

	v, err = svc.Get("t2", "product", "p1")
	if err != nil {
		panic(err)
	}
	zorunlu(v == "silgi", "t2 product p1 durmali")
	fmt.Println("OK ✅ diger namespace'ler korunuyor")

	silinen, err = svc.DeleteEntityNamespace("t1", "order")
	if err != nil {
		panic(err)
	}
	zorunlu(silinen == 1, "t1 order namespace altinda 1 key silinmeli")
	fmt.Printf("OK ✅ entity namespace temizligi dogrulandi | silinen=%d\n", silinen)

	fmt.Println("OK ✅ STEP cache pattern clean testi bitti")
}
