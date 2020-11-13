package main

import (
	"context"
	"log"

	"github.com/go-redis/redis/v8"
)

var ctx = context.Background()

func main() {
	from := redis.NewClient(&redis.Options{
		Addr:     "192.168.126.5:36794",
		Password: "xaaU123~", // no password set
		DB:       0,          // use default DB
	})
	defer from.Close()

	to := redis.NewClient(&redis.Options{
		Addr:     "localhost:6379",
		Password: "", // no password set
		DB:       0,  // use default DB
	})
	defer to.Close()

	const hkey = `__gateway_redis__`

	m, err := from.HGetAll(ctx, hkey).Result()
	if err != nil {
		log.Fatal(err)
	}

	for k, v := range m {
		hSet := to.HSet(ctx, hkey, k, v)
		if hSet.Err() != nil {
			log.Fatal(err)
		}

		log.Println(k, " was ported!")
	}

}
