package main

import (
	"context"
	"fmt"

	"github.com/redis/go-redis/v9"
)

func main() {

	ctx := context.Background()

	rdb := redis.NewClient(&redis.Options{
		Addr: "localhost:6379",
	})

	err := rdb.Set(ctx, "pix2pi:test", "redis-ok", 0).Err()
	if err != nil {
		panic(err)
	}

	val, err := rdb.Get(ctx, "pix2pi:test").Result()
	if err != nil {
		panic(err)
	}

	fmt.Println("REDIS OK ✅", val)
}
