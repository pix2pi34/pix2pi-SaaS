package query_read_model

import (
	"strings"
	"testing"
)

func TestNormalizeLimit(t *testing.T) {
	if got := normalizeLimit(0); got != 20 {
		t.Fatalf("beklenen 20, gelen %d", got)
	}

	if got := normalizeLimit(150); got != 100 {
		t.Fatalf("beklenen 100, gelen %d", got)
	}

	if got := normalizeLimit(7); got != 7 {
		t.Fatalf("beklenen 7, gelen %d", got)
	}
}

func TestNormalizeOffset(t *testing.T) {
	if got := normalizeOffset(-5); got != 0 {
		t.Fatalf("beklenen 0, gelen %d", got)
	}

	if got := normalizeOffset(9); got != 9 {
		t.Fatalf("beklenen 9, gelen %d", got)
	}
}

func TestNormalizeUsername(t *testing.T) {
	got := normalizeUsername("  ali  ")
	if got != "ali" {
		t.Fatalf("beklenen ali, gelen %q", got)
	}
}

func TestBuildUserListSQL_WithoutUsername(t *testing.T) {
	listSQL, countSQL, args := buildUserListSQL("")

	if strings.Contains(listSQL, "ILIKE") {
		t.Fatalf("username yokken ILIKE olmamali")
	}

	if strings.Contains(countSQL, "ILIKE") {
		t.Fatalf("count query'de username yokken ILIKE olmamali")
	}

	if len(args) != 0 {
		t.Fatalf("beklenen 0 arg, gelen %d", len(args))
	}
}

func TestBuildUserListSQL_WithUsername(t *testing.T) {
	listSQL, countSQL, args := buildUserListSQL("step")

	if !strings.Contains(listSQL, "username ILIKE ?") {
		t.Fatalf("list query'de username ILIKE olmali")
	}

	if !strings.Contains(countSQL, "username ILIKE ?") {
		t.Fatalf("count query'de username ILIKE olmali")
	}

	if len(args) != 1 {
		t.Fatalf("beklenen 1 arg, gelen %d", len(args))
	}

	if args[0] != "%step%" {
		t.Fatalf("beklenen %%step%%, gelen %#v", args[0])
	}
}
