package main

import (
	"fmt"

	"github.com/divrigili/pix2pi-SaaS/internal/platform/cache"
)

func main() {

	c := cache.NewRedis("localhost:6379")

	err := c.Set("pix2pi:cache:test", "hello")

	if err != nil {
		panic(err)
	}

	v, err := c.Get("pix2pi:cache:test")

	if err != nil {
		panic(err)
	}

	fmt.Println("CACHE OK:", v)

}
