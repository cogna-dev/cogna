package sdkacceptance

import (
	"fmt"

	"example.com/codeiq/sdkacceptance/internal/labels"
	"github.com/google/uuid"
	"github.com/samber/lo"
)

type Greeter struct {
	Prefix string `json:"prefix"`
}

func NewRequestID(prefix string) string {
	return fmt.Sprintf("%s-%s", prefix, uuid.NewString())
}

func BuildLabels(items []string) []string {
	filtered := labels.JoinNonEmpty(items)
	return lo.Map(filtered, func(item string, index int) string {
		return fmt.Sprintf("%s:%d", item, index)
	})
}

func (g Greeter) Greet(name string) string {
	labels := BuildLabels([]string{name})
	if g.Prefix == "" {
		g.Prefix = "hello"
	}
	return fmt.Sprintf("%s %s (%s)", g.Prefix, name, labels[0])
}
