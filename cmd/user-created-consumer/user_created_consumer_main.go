package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"log"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/nats-io/nats.go"
)

type UserCreatedEvent struct {
	Event     string `json:"event"`
	UserID    string `json:"user_id"`
	Username  string `json:"username"`
	CreatedAt string `json:"created_at"`
}

func parseUserCreated(data []byte) (UserCreatedEvent, error) {
	var evt UserCreatedEvent

	if err := json.Unmarshal(data, &evt); err != nil {
		return evt, err
	}

	evt.Event = strings.TrimSpace(evt.Event)
	evt.UserID = strings.TrimSpace(evt.UserID)
	evt.Username = strings.TrimSpace(evt.Username)
	evt.CreatedAt = strings.TrimSpace(evt.CreatedAt)

	if evt.UserID == "" {
		return evt, errors.New("user_id bos")
	}

	if evt.Username == "" {
		return evt, errors.New("username bos")
	}

	if evt.Event != "" && evt.Event != "user.created" {
		return evt, errors.New("beklenmeyen event tipi")
	}

	return evt, nil
}

func ensureProjectionTables(ctx context.Context, db *sql.DB) error {
	stmts := []string{
		`
		CREATE TABLE IF NOT EXISTS read_users (
			id SMALLINT PRIMARY KEY,
			total_count BIGINT NOT NULL DEFAULT 0
		);
		`,
		`
		INSERT INTO read_users (id, total_count)
		VALUES (1, 0)
		ON CONFLICT (id) DO NOTHING;
		`,
		`
		CREATE TABLE IF NOT EXISTS read_user_projection (
			user_id TEXT PRIMARY KEY,
			username TEXT NOT NULL,
			created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
		);
		`,
	}

	for _, stmt := range stmts {
		if _, err := db.ExecContext(ctx, stmt); err != nil {
			return err
		}
	}

	return nil
}

func parseCreatedAt(raw string) time.Time {
	if strings.TrimSpace(raw) == "" {
		return time.Now().UTC()
	}

	t, err := time.Parse(time.RFC3339Nano, raw)
	if err != nil {
		return time.Now().UTC()
	}

	return t
}

func applyUserCreated(ctx context.Context, db *sql.DB, evt UserCreatedEvent) error {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}

	createdAt := parseCreatedAt(evt.CreatedAt)

	res, err := tx.ExecContext(
		ctx,
		`
		INSERT INTO read_user_projection (user_id, username, created_at)
		VALUES ($1, $2, $3)
		ON CONFLICT (user_id) DO NOTHING
		`,
		evt.UserID,
		evt.Username,
		createdAt,
	)
	if err != nil {
		_ = tx.Rollback()
		return err
	}

	rows, err := res.RowsAffected()
	if err != nil {
		_ = tx.Rollback()
		return err
	}

	if rows == 0 {
		_ = tx.Rollback()
		log.Printf("OK ✅ duplicate user skip -> user_id=%s", evt.UserID)
		return nil
	}

	if _, err := tx.ExecContext(
		ctx,
		`UPDATE read_users SET total_count = total_count + 1 WHERE id = 1`,
	); err != nil {
		_ = tx.Rollback()
		return err
	}

	if err := tx.Commit(); err != nil {
		return err
	}

	var totalCount int64
	if err := db.QueryRowContext(
		ctx,
		`SELECT total_count FROM read_users WHERE id = 1`,
	).Scan(&totalCount); err != nil {
		return err
	}

	log.Printf("OK ✅ read_users total_count artirildi -> %d", totalCount)
	return nil
}

func main() {
	log.Println("STEP ▶ user-created-consumer boot basladi")

	writeDSN := strings.TrimSpace(os.Getenv("DB_WRITE_DSN"))
	if writeDSN == "" {
		log.Fatal("ERROR ❌ DB_WRITE_DSN bos")
	}

	natsURL := strings.TrimSpace(os.Getenv("NATS_URL"))
	if natsURL == "" {
		natsURL = "nats://localhost:4222"
	}

	db, err := sql.Open("pgx", writeDSN)
	if err != nil {
		log.Fatalf("ERROR ❌ db open: %v", err)
	}
	defer db.Close()

	db.SetMaxOpenConns(5)
	db.SetMaxIdleConns(2)
	db.SetConnMaxLifetime(30 * time.Minute)

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		log.Fatalf("ERROR ❌ db ping: %v", err)
	}
	log.Println("OK ✅ DB baglandi")

	if err := ensureProjectionTables(ctx, db); err != nil {
		log.Fatalf("ERROR ❌ projection tablo hazirlama: %v", err)
	}
	log.Println("OK ✅ projection tablolar hazir")

	nc, err := nats.Connect(natsURL, nats.Name("pix2pi-user-created-consumer"))
	if err != nil {
		log.Fatalf("ERROR ❌ NATS baglanti: %v", err)
	}
	defer nc.Close()

	log.Println("OK ✅ NATS baglandi")

	_, err = nc.QueueSubscribe("pix2pi.user.created", "read-model-projection", func(msg *nats.Msg) {
		log.Printf("OK ✅ event alindi -> %s", string(msg.Data))

		evt, err := parseUserCreated(msg.Data)
		if err != nil {
			log.Printf("ERROR ❌ event parse: %v", err)
			return
		}

		msgCtx, msgCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer msgCancel()

		if err := applyUserCreated(msgCtx, db, evt); err != nil {
			log.Printf("ERROR ❌ read model update: %v", err)
			return
		}
	})
	if err != nil {
		log.Fatalf("ERROR ❌ subscribe: %v", err)
	}

	if err := nc.Flush(); err != nil {
		log.Fatalf("ERROR ❌ nats flush: %v", err)
	}
	if err := nc.LastError(); err != nil {
		log.Fatalf("ERROR ❌ nats last error: %v", err)
	}

	log.Println("OK ✅ pix2pi.user.created dinleniyor")

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	sig := <-sigCh
	log.Printf("INFO ▶ kapanis sinyali alindi -> %s", sig.String())

	_ = nc.Drain()
	log.Println("OK ✅ consumer kapandi")
}
