package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strconv"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
)

func mustEnv(key string) string {
	v := os.Getenv(key)
	if v == "" {
		log.Fatalf("missing env: %s", key)
	}
	return v
}

func main() {
	var (
		cmd         = flag.String("cmd", "up", "up|down|steps|version|force")
		steps       = flag.Int("n", 1, "steps count for -cmd=steps (positive=up, negative=down)")
		forceVer    = flag.Int("v", -1, "force version for -cmd=force")
		migrations  = flag.String("dir", "file://internal/db/migrations", "migrations dir (file://...)")
		databaseURL = flag.String("dsn", "", "override DSN (otherwise DATABASE_URL)")
	)
	flag.Parse()

	dsn := *databaseURL
	if dsn == "" {
		dsn = mustEnv("DATABASE_URL")
	}

	m, err := migrate.New(*migrations, dsn)
	if err != nil {
		log.Fatalf("migrate.New: %v", err)
	}
	defer func() {
		_, _ = m.Close()
	}()

	switch *cmd {
	case "up":
		if err := m.Up(); err != nil && err != migrate.ErrNoChange {
			log.Fatalf("up: %v", err)
		}
		fmt.Println("OK ✅  migrations up (or no change)")
	case "down":
		if err := m.Down(); err != nil && err != migrate.ErrNoChange {
			log.Fatalf("down: %v", err)
		}
		fmt.Println("OK ✅  migrations down (or no change)")
	case "steps":
		if *steps == 0 {
			log.Fatalf("steps cannot be 0")
		}
		if err := m.Steps(*steps); err != nil && err != migrate.ErrNoChange {
			log.Fatalf("steps: %v", err)
		}
		fmt.Println("OK ✅  migrations steps:", *steps)
	case "version":
		v, dirty, err := m.Version()
		if err == migrate.ErrNilVersion {
			fmt.Println("version: none")
			return
		}
		if err != nil {
			log.Fatalf("version: %v", err)
		}
		fmt.Printf("version: %d dirty=%v\n", v, dirty)
	case "force":
		if *forceVer < 0 {
			log.Fatalf("force requires -v >= 0")
		}
		if err := m.Force(*forceVer); err != nil {
			log.Fatalf("force: %v", err)
		}
		fmt.Println("OK ✅  forced version:", strconv.Itoa(*forceVer))
	default:
		log.Fatalf("unknown -cmd=%s", *cmd)
	}
}
