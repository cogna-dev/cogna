package sample

import (
	json "encoding/json"
	"fmt"
	_ "net/http/pprof"
	. "strings"
)

type (
	Message = string
	Greeter struct {
		Prefix string `json:"prefix"`
	}
	PayloadReader interface {
		Read() (Message, error)
	}
)

const (
	LevelInfo = iota
	LevelWarn
	Bit0, Mask0 = 1 << iota, 1<<iota - 1
)

var (
	defaultName     = "world"
	counters, total = 1, 2
)

const Version = "v1"

var Enabled = true

func Hello(name string) string {
	if name == "" {
		name = defaultName
	}
	return fmt.Sprintf("hello %s", ToUpper(name))
}

func (g *Greeter) Greet(name string) Message {
	if g.Prefix == "" {
		g.Prefix = "hi"
	}
	payload, _ := json.Marshal(map[string]string{"name": name})
	return Message(g.Prefix + " " + string(payload))
}

func NewGreeter(prefix string) *Greeter {
	return &Greeter{Prefix: prefix}
}
