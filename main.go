package main

import (
	"sync"
	"time"

	"github.com/gofiber/fiber/v2"
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

var countMutex = &sync.RWMutex{}
var count int = 0

func GetCount() (value int) {
	countMutex.RLock()
	value = count
	countMutex.RUnlock()
	return
}

func SetCount(value int) {
	countMutex.Lock()
	count = value
	countMutex.Unlock()
}

func main() {
	SERVER_ID := time.Now().UnixNano()

	app := fiber.New()

	app.Get("/", func(c *fiber.Ctx) error {
		return c.Status(200).SendString("Hello, World!")
	})

	app.Get("/add", func(c *fiber.Ctx) error {
		count := GetCount()

		// Increase count
		count++

		// Set count
		SetCount(count)

		return c.Status(200).JSON(ResponseGet{Count: count})
	})

	app.Get("/get", func(c *fiber.Ctx) error {
		// Get count
		count := GetCount()

		return c.Status(200).JSON(ResponseGet{Count: count})
	})

	app.Get("/reset", func(c *fiber.Ctx) error {
		// Set count
		SetCount(0)

		return c.Status(200).JSON(ResponseGet{Count: 0})
	})

	app.Get("/server-id", func(c *fiber.Ctx) error {
		return c.Status(200).JSON(ResponseServerId{ServerId: SERVER_ID})
	})

	app.Listen(":3000")
}
