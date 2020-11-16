package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/go-redis/redis/v8"
)

type OutKey struct {
	Key   string      `json:"key"`
	Type  string      `json:"type"`
	Value interface{} `json:"content"`
}

var (
	from     string
	fromAuth string
	fromDB   int

	to     string
	toAuth string
	toDB   int

	keys string

	fromJsonFile string
	toJsonFile   string

	err    error
	toFile *os.File

	fromRedis *redis.Client
	toRedis   *redis.Client
)

func init() {
	flag.StringVar(&fromJsonFile, "from.file", "", "from json file")
	flag.StringVar(&toJsonFile, "to.file", "", "to json file")

	flag.StringVar(&from, "from", "", "from redis")
	flag.StringVar(&fromAuth, "from.auth", "", "from redis auth")
	flag.IntVar(&fromDB, "from.db", 0, "from redis db")

	flag.StringVar(&to, "to", "", "to redis")
	flag.StringVar(&toAuth, "to.auth", "", "to redis auth")
	flag.IntVar(&toDB, "to.db", 0, "to redis db")

	flag.StringVar(&keys, "keys", "", "port keys separated by ,")

	flag.Parse()
}

var ctx = context.Background()

func main() {
	if from != "" {
		fromRedis = redis.NewClient(&redis.Options{
			Addr:     from,
			Password: fromAuth,
			DB:       fromDB,
			PoolSize: 1,
		})
		defer fromRedis.Close()
	}

	if to != "" {
		toRedis = redis.NewClient(&redis.Options{
			Addr:     to,
			DB:       toDB,
			Password: toAuth,
			PoolSize: 1,
		})
		defer toRedis.Close()
	}

	if toJsonFile != "" {
		dir := filepath.Dir(toJsonFile)
		if err := os.MkdirAll(dir, 0644); err != nil {
			fmt.Printf("failed to create dir:%s err:%v", dir, err)
			os.Exit(1)
		}

		toFile, err = os.OpenFile(toJsonFile, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0644)
		if err != nil {
			fmt.Printf("failed to open file:%s err:%v", toJsonFile, err)
			os.Exit(1)
		}
	}

	if fromJsonFile != "" {
		readFile()
	}

	if fromRedis != nil && keys != "" {
		outKeys := readRedis()
		writeToFile(toFile, outKeys, toJsonFile)
	}

}

func readRedis() []OutKey {
	outKeys := make([]OutKey, 0)

	for _, k := range strings.Split(keys, ",") {
		ktype, err := fromRedis.Type(ctx, k).Result()
		if err != nil {
			fmt.Printf("type key:%s, error:%v", k, err)
			continue
		}
		switch ktype {
		case "string":
			v, err := fromRedis.Get(ctx, k).Result()
			if err != nil {
				fmt.Printf("get key:%s, error:%v", k, err)
				continue
			}

			if toFile != nil {
				outKeys = append(outKeys, OutKey{Key: k, Type: ktype, Value: v})
			}

			if toRedis != nil {
				if _, err := toRedis.Set(ctx, k, v, 0).Result(); err != nil {
					fmt.Printf("set key:%s, error:%v", k, err)
					continue
				}
			}

			log.Println(k, " was ported!")
		case "hash":
			v, err := fromRedis.HGetAll(ctx, k).Result()
			if err != nil {
				fmt.Printf("hgetall key:%s, error:%v", k, err)
				continue
			}

			if toFile != nil {
				outKeys = append(outKeys, OutKey{Key: k, Type: ktype, Value: v})
			}

			if toRedis != nil {
				for sk, sv := range v {
					if _, err := toRedis.HSet(ctx, k, sk, sv).Result(); err != nil {
						fmt.Printf("hset key:%s field:%s error:%v", k, sk, err)
						continue
					}

					log.Println(k, " was ported!")
				}
			}
		default:
			log.Println(k, " was ignored because of unsupported type ", ktype)
		}
	}

	return outKeys
}

func readFile() {
	fromBytes, err := ioutil.ReadFile(fromJsonFile)
	if err != nil {
		fmt.Printf("failed to read file:%s err:%v", fromJsonFile, err)
		os.Exit(1)
	}

	var outKeys []OutKey

	if err := json.Unmarshal(fromBytes, &outKeys); err != nil {
		fmt.Printf("failed to Unmarshal file:%s err:%v", fromJsonFile, err)
		os.Exit(1)
	}

	if toRedis != nil {
		writeRedis(outKeys)
	}
}

func writeRedis(outKeys []OutKey) {
	for _, outKey := range outKeys {
		ktype := outKey.Type
		k := outKey.Key
		v := outKey.Value
		switch ktype {
		case "string":
			if _, err := toRedis.Set(ctx, k, v, 0).Result(); err != nil {
				fmt.Printf("set key:%s, error:%v", k, err)
				continue
			}

			log.Println(k, " was ported!")
		case "hash":
			for sk, sv := range v.(map[string]interface{}) {
				if _, err := toRedis.HSet(ctx, k, sk, sv).Result(); err != nil {
					fmt.Printf("hset key:%s field:%s error:%v", k, sk, err)
					continue
				}
			}
			log.Println(k, " was ported!")
		default:
			log.Println(k, " was ignored because of unsupported type ", ktype)
		}
	}
}

func writeToFile(toFile *os.File, outKeys []OutKey, toJsonFile string) {
	if toFile != nil {
		outJSON, _ := json.Marshal(outKeys)
		if _, err := toFile.Write(outJSON); err != nil {
			fmt.Printf("failed to write file:%s err:%v", toJsonFile, err)
			os.Exit(1)
		}
		_ = toFile.Close()

		log.Println("Total", len(outKeys), "were ported!")
	}
}
