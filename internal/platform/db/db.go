package db

import (
	"database/sql"
	"log"
	"os"

	_ "github.com/lib/pq"
)

func Connect() *sql.DB {
	connStr := os.Getenv("DB_DSN")
	if connStr == "" {
		log.Fatal("security: DB_DSN environment variable is required")
	}

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err)
	}

	return db
}
