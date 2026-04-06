package migrator

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
)

type Config struct {
	Host     string
	Port     string
	User     string
	Password string
	DBName   string
	SSLMode  string
}

func FromEnv() Config {
	cfg := Config{
		Host:     getenv("DB_HOST", "localhost"),
		Port:     getenv("DB_PORT", "5432"),
		User:     getenv("DB_USER", "pix2pi_admin"),
		Password: getenv("DB_PASSWORD", "123456"),
		DBName:   getenv("DB_NAME", "pix2pi_saas"),
		SSLMode:  getenv("DB_SSLMODE", "disable"),
	}
	return cfg
}

func (c Config) DSN() string {
	// postgres://user:pass@host:port/db?sslmode=disable
	return fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s?sslmode=%s",
		c.User, c.Password, c.Host, c.Port, c.DBName, c.SSLMode,
	)
}

func AutoMigrate() error {
	cfg := FromEnv()
	return AutoMigrateWith(cfg)
}

func AutoMigrateWith(cfg Config) error {
	dsn := cfg.DSN()

	// Not: migrate "file://" ister. Workdir kökten çalıştırıyoruz.
	m, err := migrate.New("file://internal/db/migrations", dsn)
	if err != nil {
		return fmt.Errorf("migrate.New failed: %w", err)
	}
	defer func() {
		_, _ = m.Close()
	}()

	// Kısa bir retry (container DB yeni kalkınca race olmasın)
	for i := 1; i <= 10; i++ {
		err = m.Up()
		if err == nil {
			log.Println("✅ migrations applied (up)")
			return nil
		}
		if err == migrate.ErrNoChange {
			log.Println("✅ migrations already up-to-date (no change)")
			return nil
		}

		log.Printf("⏳ migrate attempt %d failed: %v", i, err)
		time.Sleep(1 * time.Second)
	}

	return fmt.Errorf("migration failed after retries: %w", err)
}

func getenv(k, def string) string {
	v := os.Getenv(k)
	if v == "" {
		return def
	}
	return v
}
