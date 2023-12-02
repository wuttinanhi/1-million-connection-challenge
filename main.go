package main

import (
	"context"
	"os"
	"time"

	"github.com/go-redsync/redsync/v4"
	"github.com/go-redsync/redsync/v4/redis/goredis/v9"
	"github.com/gofiber/fiber/v2"
	goredislib "github.com/redis/go-redis/v9"
)

type ResponseGet struct {
	Count int `json:"count"`
}

type ResponseError struct {
	Error string `json:"error"`
}

type ResponseServerId struct {
	ServerId int64 `json:"server_id"`
}

func GetCount(redisClient *goredislib.Client, ctx context.Context) (count int, err error) {
	count, err = redisClient.Get(ctx, "count").Int()
	if err != nil {
		// if key not found, set to 0
		if err == goredislib.Nil {
			count = 0
			err = nil
		}
	}
	return
}

func SetCount(redisClient *goredislib.Client, ctx context.Context, count int) (err error) {
	err = redisClient.Set(ctx, "count", count, 0).Err()
	return
}

func main() {
	var SERVER_ID = time.Now().UnixNano()

	var REDIS_HOST = os.Getenv("REDIS_HOST")
	if REDIS_HOST == "" {
		REDIS_HOST = "localhost:6379"
	}

	redisClient := goredislib.NewClient(&goredislib.Options{
		Addr:     REDIS_HOST,
		Password: "",
		DB:       0,
	})

	pool := goredis.NewPool(redisClient)
	rs := redsync.New(pool)

	redisMutex := rs.NewMutex("count-lock")
	ctx := context.Background()

	app := fiber.New()

	app.Get("/", func(c *fiber.Ctx) error {
		return c.Status(200).SendString("Hello, World!")
	})

	app.Get("/add", func(c *fiber.Ctx) error {
		// Aquire lock
		if err := redisMutex.LockContext(ctx); err != nil {
			return c.Status(500).JSON(ResponseError{Error: err.Error()})

		}

		// Get count
		count, err := GetCount(redisClient, ctx)
		if err != nil {
			return c.Status(500).JSON(ResponseError{Error: err.Error()})
		}

		// Increase count
		count++

		// Set count
		err = SetCount(redisClient, ctx, count)
		if err != nil {
			return c.Status(500).JSON(ResponseError{Error: err.Error()})
		}

		// Release lock
		if _, err := redisMutex.UnlockContext(ctx); err != nil {
			return c.Status(500).JSON(ResponseError{Error: err.Error()})
		}

		return c.Status(200).JSON(ResponseGet{Count: count})
	})

	app.Get("/get", func(c *fiber.Ctx) error {
		// Get count
		count, err := GetCount(redisClient, ctx)
		if err != nil {
			return c.Status(500).JSON(ResponseError{Error: err.Error()})
		}

		return c.Status(200).JSON(ResponseGet{Count: count})
	})

	app.Get("/reset", func(c *fiber.Ctx) error {
		// Set count
		err := SetCount(redisClient, ctx, 0)
		if err != nil {
			return c.Status(500).JSON(ResponseError{Error: err.Error()})
		}

		return c.Status(200).JSON(ResponseGet{Count: 0})
	})

	app.Get("/server-id", func(c *fiber.Ctx) error {
		return c.Status(200).JSON(ResponseServerId{ServerId: SERVER_ID})
	})

	app.Listen(":3000")
}
