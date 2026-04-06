package kernel

import (
	"sort"
	"sync"
)

var (
	muReg sync.RWMutex
	reg   = map[string]struct{}{}
)

// RegisterPermission records a permission string for debug/visibility.
func RegisterPermission(perm string) {
	if perm == "" {
		return
	}
	muReg.Lock()
	reg[perm] = struct{}{}
	muReg.Unlock()
}

// ListPermissions returns all known permissions (sorted).
func ListPermissions() []string {
	muReg.RLock()
	defer muReg.RUnlock()
	out := make([]string, 0, len(reg))
	for p := range reg {
		out = append(out, p)
	}
	sort.Strings(out)
	return out
}
