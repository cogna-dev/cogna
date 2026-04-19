package sample

import (
	json "encoding/json"
	"fmt"
	_ "net/http/pprof"
	. "strings"
)

type (
	Message   = string
	StringSet = map[string]struct{}
	Greeter   struct {
		Prefix string `json:"prefix"`
	}
	Embedded interface {
		Label() string
	}
	Composite interface {
		PayloadReader
		Embedded
	}
	Box[T any] struct {
		Greeter
		Value T
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

func LegacyHello(name string) string {
	return Hello(name)
}

func MapValue[T any, U any](value T, mapper func(T) U) U {
	return mapper(value)
}

func (g *Greeter) Greet(name string) Message {
	if g.Prefix == "" {
		g.Prefix = "hi"
	}
	payload, _ := json.Marshal(map[string]string{"name": name})
	return Message(g.Prefix + " " + string(payload))
}

func (g Greeter) Label() string {
	if g.Prefix == "" {
		return "label:hi"
	}
	return "label:" + g.Prefix
}

func NewGreeter(prefix string) *Greeter {
	return &Greeter{Prefix: prefix}
}
