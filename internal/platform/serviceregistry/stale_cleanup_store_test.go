package serviceregistry

import (
	"context"
	"errors"
	"strings"
	"testing"
	"time"
)

func TestSQLStoreCleanupStaleInstances_Success(t *testing.T) {
	db := &queryRowProviderMock{
		row: &sqlRowMock{
			values: []any{7},
		},
	}

	store := NewSQLStore(db)

	result, err := store.CleanupStaleInstances(context.Background(), CleanupStaleInstancesCommand{
		TenantID:      "tenant-a",
		ThresholdTime: time.Date(2026, 4, 24, 15, 55, 0, 0, time.UTC),
		Limit:         100,
		TargetStatus:  "stopped",
		DryRun:        false,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.CleanedCount != 7 {
		t.Fatalf("beklenen cleaned_count 7, alinan: %d", result.CleanedCount)
	}

	if !strings.Contains(db.lastQuery, "runtime.service_registry_instances") {
		t.Fatalf("service_registry_instances query icinde olmaliydi")
	}

	if !strings.Contains(db.lastQuery, "target_rows") {
		t.Fatalf("target_rows cte bekleniyordu")
	}

	if len(db.lastArgs) != 5 {
		t.Fatalf("beklenen 5 arguman, alinan: %d", len(db.lastArgs))
	}
}

func TestSQLStoreCleanupStaleInstances_DryRun(t *testing.T) {
	db := &queryRowProviderMock{
		row: &sqlRowMock{
			values: []any{3},
		},
	}

	store := NewSQLStore(db)

	result, err := store.CleanupStaleInstances(context.Background(), CleanupStaleInstancesCommand{
		TenantID:      "tenant-a",
		ThresholdTime: time.Date(2026, 4, 24, 15, 55, 0, 0, time.UTC),
		Limit:         50,
		TargetStatus:  "stopped",
		DryRun:        true,
	})
	if err != nil {
		t.Fatalf("beklenen hata yok, alinan hata: %v", err)
	}

	if result.CleanedCount != 3 {
		t.Fatalf("beklenen cleaned_count 3, alinan: %d", result.CleanedCount)
	}
}

func TestSQLStoreCleanupStaleInstances_NoDB(t *testing.T) {
	store := NewSQLStore(nil)

	_, err := store.CleanupStaleInstances(context.Background(), CleanupStaleInstancesCommand{})
	if err == nil {
		t.Fatalf("beklenen nil db hatasi")
	}
}

func TestSQLStoreCleanupStaleInstances_ScanError(t *testing.T) {
	db := &queryRowProviderMock{
		row: &sqlRowMock{
			err: errors.New("cleanup scan failed"),
		},
	}

	store := NewSQLStore(db)

	_, err := store.CleanupStaleInstances(context.Background(), CleanupStaleInstancesCommand{
		TenantID:      "tenant-a",
		ThresholdTime: time.Date(2026, 4, 24, 15, 55, 0, 0, time.UTC),
		Limit:         10,
		TargetStatus:  "stopped",
		DryRun:        false,
	})
	if err == nil {
		t.Fatalf("beklenen scan hatasi")
	}
}
