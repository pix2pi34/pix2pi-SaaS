package platform

import (
	"testing"
	"time"

	miniredis "github.com/alicebob/miniredis/v2"
	"github.com/redis/go-redis/v9"
)

func TestIdempotencyStore_AlreadyProcessed_BeforeMark(t *testing.T) {
	mr, err := miniredis.Run()
	if err != nil {
		t.Fatalf("miniredis baslatma hatasi: %v", err)
	}
	defer mr.Close()

	rdb := redis.NewClient(&redis.Options{
		Addr: mr.Addr(),
	})

	store := NewIdempotencyStore(rdb, 24*time.Hour)

	ok, err := store.AlreadyProcessed("sale-S1001")
	if err != nil {
		t.Fatalf("AlreadyProcessed hatasi: %v", err)
	}

	if ok {
		t.Fatalf("beklenen false, gelen true")
	}
}

func TestIdempotencyStore_MarkProcessed_ThenAlreadyProcessed(t *testing.T) {
	mr, err := miniredis.Run()
	if err != nil {
		t.Fatalf("miniredis baslatma hatasi: %v", err)
	}
	defer mr.Close()

	rdb := redis.NewClient(&redis.Options{
		Addr: mr.Addr(),
	})

	store := NewIdempotencyStore(rdb, 24*time.Hour)

	err = store.MarkProcessed("sale-S1001")
	if err != nil {
		t.Fatalf("MarkProcessed hatasi: %v", err)
	}

	ok, err := store.AlreadyProcessed("sale-S1001")
	if err != nil {
		t.Fatalf("AlreadyProcessed hatasi: %v", err)
	}

	if !ok {
		t.Fatalf("beklenen true, gelen false")
	}
}

func TestIdempotencyStore_KeyHasTTL(t *testing.T) {
	mr, err := miniredis.Run()
	if err != nil {
		t.Fatalf("miniredis baslatma hatasi: %v", err)
	}
	defer mr.Close()

	rdb := redis.NewClient(&redis.Options{
		Addr: mr.Addr(),
	})

	store := NewIdempotencyStore(rdb, 24*time.Hour)

	err = store.MarkProcessed("sale-S1001")
	if err != nil {
		t.Fatalf("MarkProcessed hatasi: %v", err)
	}

	ttl := mr.TTL("pix2pi:idempotency:sale-S1001")
	if ttl <= 0 {
		t.Fatalf("ttl beklenenden kucuk veya sifir: %v", ttl)
	}
}
