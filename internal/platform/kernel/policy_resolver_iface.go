package kernel

// PolicyResolver: route bazli yetki kararini ureten arayuz.
// method: "GET", "POST" ...
// path: "/admin/ping" gibi (Fiber route path)
// role: "superadmin", "admin", "user" ...
type PolicyResolver interface {
	Allow(method, path, role string) bool
}
