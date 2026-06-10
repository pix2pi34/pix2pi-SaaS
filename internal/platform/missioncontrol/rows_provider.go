package missioncontrol

import "context"

type RowsScanner interface {
	Next() bool
	Scan(dest ...any) error
	Err() error
	Close() error
}

type QueryRowsProvider interface {
	QueryContext(ctx context.Context, query string, args ...any) (RowsScanner, error)
}
