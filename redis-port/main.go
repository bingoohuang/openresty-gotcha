package main

import (
	"context"
	"log"

	"github.com/go-redis/redis/v8"
)

func main() {
	from := redis.NewClient(&redis.Options{
		Addr:     "192.168.126.5:36794",
		Password: "xaaU123~",
		DB:       0, // use default DB
		PoolSize: 1,
	})
	defer from.Close()

	to := redis.NewClient(&redis.Options{
		Addr:     "localhost:6379",
		DB:       0, // use default DB
		PoolSize: 1,
	})
	defer to.Close()

	const hkey = `__gateway_redis__`

	ctx := context.Background()

	m, err := from.HGetAll(ctx, hkey).Result()
	if err != nil {
		panic(err)
	}

	for k, v := range m {
		if hSet := to.HSet(ctx, hkey, k, v); hSet.Err() != nil {
			panic(err)
		}

		log.Println(k, " was ported!")
	}
}
