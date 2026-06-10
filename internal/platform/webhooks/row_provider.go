package webhooks

import "context"

type RowScanner interface {
	Scan(dest ...any) error
}

type QueryRowProvider interface {
	QueryRowContext(ctx context.Context, query string, args ...any) RowScanner
}
