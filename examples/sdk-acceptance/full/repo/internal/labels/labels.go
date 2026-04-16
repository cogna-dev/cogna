package labels

import "github.com/samber/lo"

func JoinNonEmpty(values []string) []string {
	return lo.FilterMap(values, func(value string, _ int) (string, bool) {
		return value, value != ""
	})
}
