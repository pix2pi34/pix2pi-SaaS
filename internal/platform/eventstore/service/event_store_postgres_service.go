package service

import (
	"database/sql"
	"fmt"
	"os"
	"regexp"
	"sort"
	"strings"
	"time"

	_ "github.com/lib/pq"

	eventstoredomain "github.com/divrigili/pix2pi-SaaS/internal/platform/eventstore/domain"
)

type PostgresEventStoreService struct {
	db        *sql.DB
	tableName string
}

func envFirst(keys ...string) string {
	for _, key := range keys {
		deger := strings.TrimSpace(os.Getenv(key))
		if deger != "" {
			return deger
		}
	}
	return ""
}

func guvenliTableName(tableName string) (string, error) {
	if tableName == "" {
		tableName = "event_store_records"
	}

	uygunMu, err := regexp.MatchString(`^[a-zA-Z_][a-zA-Z0-9_]*$`, tableName)
	if err != nil {
		return "", err
	}
	if !uygunMu {
		return "", fmt.Errorf("gecersiz table name")
	}

	return tableName, nil
}

func NewPostgresEventStoreService(
	dsn string,
	tableName string,
) (*PostgresEventStoreService, error) {
	if strings.TrimSpace(dsn) == "" {
		return nil, fmt.Errorf("dsn zorunlu")
	}

	temizTableName, err := guvenliTableName(tableName)
	if err != nil {
		return nil, err
	}

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, err
	}

	if err := db.Ping(); err != nil {
		_ = db.Close()
		return nil, err
	}

	return &PostgresEventStoreService{
		db:        db,
		tableName: temizTableName,
	}, nil
}

func NewPostgresEventStoreServiceFromEnv(
	tableName string,
) (*PostgresEventStoreService, error) {
	host := envFirst("EVENT_STORE_PG_HOST", "DB_HOST", "POSTGRES_HOST")
	if host == "" {
		host = "127.0.0.1"
	}

	port := envFirst("EVENT_STORE_PG_PORT", "DB_PORT", "POSTGRES_PORT")
	if port == "" {
		port = "5433"
	}

	user := envFirst("EVENT_STORE_PG_USER", "DB_USER", "POSTGRES_USER")
	if user == "" {
		user = "postgres"
	}

	password := envFirst("EVENT_STORE_PG_PASSWORD", "DB_PASSWORD", "POSTGRES_PASSWORD")
	if password == "" {
		password = "postgres" // local dev fallback — override with EVENT_STORE_PG_PASSWORD in production
	}

	dbname := envFirst("EVENT_STORE_PG_DBNAME", "DB_NAME", "POSTGRES_DB")
	if dbname == "" {
		dbname = "postgres"
	}

	sslmode := envFirst("EVENT_STORE_PG_SSLMODE", "DB_SSLMODE")
	if sslmode == "" {
		sslmode = "disable" // set EVENT_STORE_PG_SSLMODE=require in production
	}

	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		host,
		port,
		user,
		password,
		dbname,
		sslmode,
	)

	return NewPostgresEventStoreService(dsn, tableName)
}

func (s *PostgresEventStoreService) Close() error {
	if s == nil || s.db == nil {
		return nil
	}
	return s.db.Close()
}

func (s *PostgresEventStoreService) TableName() string {
	return s.tableName
}

func (s *PostgresEventStoreService) EnsureSchema() error {
	createTableSQL := fmt.Sprintf(`
CREATE TABLE IF NOT EXISTS %s (
	store_id TEXT PRIMARY KEY,
	event_id TEXT NOT NULL UNIQUE,
	tenant_id TEXT NOT NULL,
	tenant_uuid TEXT NOT NULL,
	topic TEXT NOT NULL,
	payload TEXT NOT NULL,
	sozlesme_adi TEXT NOT NULL DEFAULT '',
	sozlesme_versiyonu INTEGER NOT NULL DEFAULT 0,
	correlation_id TEXT NOT NULL,
	causation_id TEXT NOT NULL DEFAULT '',
	idempotency_key TEXT NOT NULL,
	source_service TEXT NOT NULL,
	version INTEGER NOT NULL DEFAULT 1,
	durum TEXT NOT NULL,
	retry_count INTEGER NOT NULL DEFAULT 0,
	max_retry INTEGER NOT NULL DEFAULT 3,
	replay_count INTEGER NOT NULL DEFAULT 0,
	son_hata TEXT NOT NULL DEFAULT '',
	dlq_nedeni TEXT NOT NULL DEFAULT '',
	olusturma_tarihi TIMESTAMPTZ NOT NULL,
	guncelleme_tarihi TIMESTAMPTZ NOT NULL,
	islenme_tarihi TIMESTAMPTZ NULL,
	son_retry_tarihi TIMESTAMPTZ NULL,
	son_replay_tarihi TIMESTAMPTZ NULL,
	dlq_tarihi TIMESTAMPTZ NULL
);`, s.tableName)

	_, err := s.db.Exec(createTableSQL)
	if err != nil {
		return err
	}

	indexSQL1 := fmt.Sprintf(
		`CREATE UNIQUE INDEX IF NOT EXISTS %s ON %s (tenant_id, topic, idempotency_key);`,
		s.tableName+"_tenant_topic_idempotency_uidx",
		s.tableName,
	)
	_, err = s.db.Exec(indexSQL1)
	if err != nil {
		return err
	}

	indexSQL2 := fmt.Sprintf(
		`CREATE INDEX IF NOT EXISTS %s ON %s (tenant_id, topic, durum);`,
		s.tableName+"_tenant_topic_durum_idx",
		s.tableName,
	)
	_, err = s.db.Exec(indexSQL2)
	if err != nil {
		return err
	}

	indexSQL3 := fmt.Sprintf(
		`CREATE INDEX IF NOT EXISTS %s ON %s (olusturma_tarihi);`,
		s.tableName+"_olusturma_tarihi_idx",
		s.tableName,
	)
	_, err = s.db.Exec(indexSQL3)
	if err != nil {
		return err
	}

	return nil
}

func (s *PostgresEventStoreService) TestIcinTemizle() error {
	_, err := s.db.Exec(fmt.Sprintf(`DELETE FROM %s`, s.tableName))
	return err
}

func (s *PostgresEventStoreService) EventVarMi(eventID string) bool {
	if strings.TrimSpace(eventID) == "" {
		return false
	}

	var varMi bool
	err := s.db.QueryRow(
		fmt.Sprintf(`SELECT EXISTS(SELECT 1 FROM %s WHERE event_id = $1)`, s.tableName),
		eventID,
	).Scan(&varMi)
	if err != nil {
		return false
	}

	return varMi
}

func (s *PostgresEventStoreService) IdempotencyKaydiVarMi(
	tenantID string,
	topic string,
	idempotencyKey string,
) bool {
	if tenantID == "" || topic == "" || idempotencyKey == "" {
		return false
	}

	var varMi bool
	err := s.db.QueryRow(
		fmt.Sprintf(
			`SELECT EXISTS(
				SELECT 1
				FROM %s
				WHERE tenant_id = $1
				  AND topic = $2
				  AND idempotency_key = $3
			)`,
			s.tableName,
		),
		tenantID,
		topic,
		idempotencyKey,
	).Scan(&varMi)
	if err != nil {
		return false
	}

	return varMi
}

func postgresSelectColumns() string {
	return `
store_id,
event_id,
tenant_id,
tenant_uuid,
topic,
payload,
sozlesme_adi,
sozlesme_versiyonu,
correlation_id,
causation_id,
idempotency_key,
source_service,
version,
durum,
retry_count,
max_retry,
replay_count,
son_hata,
dlq_nedeni,
olusturma_tarihi,
guncelleme_tarihi,
islenme_tarihi,
son_retry_tarihi,
son_replay_tarihi,
dlq_tarihi
`
}

func scanEventStoreRecord(
	scanner interface {
		Scan(dest ...any) error
	},
) (eventstoredomain.EventStoreRecord, error) {
	var kayit eventstoredomain.EventStoreRecord
	var islenmeTarihi sql.NullTime
	var sonRetryTarihi sql.NullTime
	var sonReplayTarihi sql.NullTime
	var dlqTarihi sql.NullTime

	err := scanner.Scan(
		&kayit.StoreID,
		&kayit.EventID,
		&kayit.TenantID,
		&kayit.TenantUUID,
		&kayit.Topic,
		&kayit.Payload,
		&kayit.SozlesmeAdi,
		&kayit.SozlesmeVersiyonu,
		&kayit.CorrelationID,
		&kayit.CausationID,
		&kayit.IdempotencyKey,
		&kayit.SourceService,
		&kayit.Version,
		&kayit.Durum,
		&kayit.RetryCount,
		&kayit.MaxRetry,
		&kayit.ReplayCount,
		&kayit.SonHata,
		&kayit.DlqNedeni,
		&kayit.OlusturmaTarihi,
		&kayit.GuncellemeTarihi,
		&islenmeTarihi,
		&sonRetryTarihi,
		&sonReplayTarihi,
		&dlqTarihi,
	)
	if err != nil {
		return eventstoredomain.EventStoreRecord{}, err
	}

	if islenmeTarihi.Valid {
		kayit.IslenmeTarihi = islenmeTarihi.Time
	}
	if sonRetryTarihi.Valid {
		kayit.SonRetryTarihi = sonRetryTarihi.Time
	}
	if sonReplayTarihi.Valid {
		kayit.SonReplayTarihi = sonReplayTarihi.Time
	}
	if dlqTarihi.Valid {
		kayit.DlqTarihi = dlqTarihi.Time
	}

	return kayit, nil
}

func (s *PostgresEventStoreService) Kaydet(
	kayit eventstoredomain.EventStoreRecord,
) error {
	if err := validatePostgresEventStoreKaydetInput(kayit); err != nil {
		return err
	}

	metadataStandartla(&kayit)

	if s.EventVarMi(kayit.EventID) {
		return fmt.Errorf("duplicate event id")
	}
	if s.IdempotencyKaydiVarMi(kayit.TenantID, kayit.Topic, kayit.IdempotencyKey) {
		return fmt.Errorf("duplicate idempotency key")
	}

	if kayit.MaxRetry == 0 {
		kayit.MaxRetry = 3
	}
	if kayit.Durum == "" {
		kayit.Durum = eventstoredomain.EventStoreDurumBekliyor
	}
	if kayit.OlusturmaTarihi.IsZero() {
		kayit.OlusturmaTarihi = time.Now()
	}
	if kayit.GuncellemeTarihi.IsZero() {
		kayit.GuncellemeTarihi = kayit.OlusturmaTarihi
	}

	insertSQL := fmt.Sprintf(`
INSERT INTO %s (
	store_id,
	event_id,
	tenant_id,
	tenant_uuid,
	topic,
	payload,
	sozlesme_adi,
	sozlesme_versiyonu,
	correlation_id,
	causation_id,
	idempotency_key,
	source_service,
	version,
	durum,
	retry_count,
	max_retry,
	replay_count,
	son_hata,
	dlq_nedeni,
	olusturma_tarihi,
	guncelleme_tarihi,
	islenme_tarihi,
	son_retry_tarihi,
	son_replay_tarihi,
	dlq_tarihi
) VALUES (
	$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,
	$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,
	$21,$22,$23,$24,$25
)`, s.tableName)

	_, err := s.db.Exec(
		insertSQL,
		kayit.StoreID,
		kayit.EventID,
		kayit.TenantID,
		kayit.TenantUUID,
		kayit.Topic,
		kayit.Payload,
		kayit.SozlesmeAdi,
		kayit.SozlesmeVersiyonu,
		kayit.CorrelationID,
		kayit.CausationID,
		kayit.IdempotencyKey,
		kayit.SourceService,
		kayit.Version,
		kayit.Durum,
		kayit.RetryCount,
		kayit.MaxRetry,
		kayit.ReplayCount,
		kayit.SonHata,
		kayit.DlqNedeni,
		kayit.OlusturmaTarihi,
		kayit.GuncellemeTarihi,
		nullTimeOrNil(kayit.IslenmeTarihi),
		nullTimeOrNil(kayit.SonRetryTarihi),
		nullTimeOrNil(kayit.SonReplayTarihi),
		nullTimeOrNil(kayit.DlqTarihi),
	)
	if err != nil {
		return err
	}

	return nil
}

func nullTimeOrNil(t time.Time) any {
	if t.IsZero() {
		return nil
	}
	return t
}

func (s *PostgresEventStoreService) EventIDIleGetir(
	eventID string,
) (eventstoredomain.EventStoreRecord, error) {
	query := fmt.Sprintf(
		`SELECT %s FROM %s WHERE event_id = $1`,
		postgresSelectColumns(),
		s.tableName,
	)

	row := s.db.QueryRow(query, eventID)
	return scanEventStoreRecord(row)
}

func (s *PostgresEventStoreService) DurumGuncelle(
	eventID string,
	durum string,
) error {
	_, err := s.db.Exec(
		fmt.Sprintf(
			`UPDATE %s
			 SET durum = $2,
			     guncelleme_tarihi = NOW()
			 WHERE event_id = $1`,
			s.tableName,
		),
		eventID,
		durum,
	)
	return err
}

func (s *PostgresEventStoreService) RetryGuncelle(
	eventID string,
	retryCount int,
	sonHata string,
	zaman time.Time,
) error {
	_, err := s.db.Exec(
		fmt.Sprintf(
			`UPDATE %s
			 SET retry_count = $2,
			     son_hata = $3,
			     son_retry_tarihi = $4,
			     durum = $5,
			     guncelleme_tarihi = $4
			 WHERE event_id = $1`,
			s.tableName,
		),
		eventID,
		retryCount,
		sonHata,
		zaman,
		eventstoredomain.EventStoreDurumTekrar,
	)
	return err
}

func (s *PostgresEventStoreService) IslendiOlarakIsaretle(
	eventID string,
	zaman time.Time,
) error {
	_, err := s.db.Exec(
		fmt.Sprintf(
			`UPDATE %s
			 SET durum = $2,
			     islenme_tarihi = $3,
			     guncelleme_tarihi = $3
			 WHERE event_id = $1`,
			s.tableName,
		),
		eventID,
		eventstoredomain.EventStoreDurumIslendi,
		zaman,
	)
	return err
}

func (s *PostgresEventStoreService) DlqOlarakIsaretle(
	eventID string,
	retryCount int,
	neden string,
	zaman time.Time,
) error {
	_, err := s.db.Exec(
		fmt.Sprintf(
			`UPDATE %s
			 SET retry_count = $2,
			     dlq_nedeni = $3,
			     durum = $4,
			     dlq_tarihi = $5,
			     guncelleme_tarihi = $5
			 WHERE event_id = $1`,
			s.tableName,
		),
		eventID,
		retryCount,
		neden,
		eventstoredomain.EventStoreDurumDlq,
		zaman,
	)
	return err
}

func (s *PostgresEventStoreService) YenidenKuyrugaAlOlarakIsaretle(
	eventID string,
	zaman time.Time,
) error {
	_, err := s.db.Exec(
		fmt.Sprintf(
			`UPDATE %s
			 SET durum = $2,
			     retry_count = 0,
			     son_hata = '',
			     dlq_nedeni = '',
			     guncelleme_tarihi = $3
			 WHERE event_id = $1`,
			s.tableName,
		),
		eventID,
		eventstoredomain.EventStoreDurumBekliyor,
		zaman,
	)
	return err
}

func (s *PostgresEventStoreService) ReplayGuncelle(
	eventID string,
	zaman time.Time,
) error {
	_, err := s.db.Exec(
		fmt.Sprintf(
			`UPDATE %s
			 SET replay_count = replay_count + 1,
			     retry_count = 0,
			     son_hata = '',
			     dlq_nedeni = '',
			     durum = $2,
			     son_replay_tarihi = $3,
			     guncelleme_tarihi = $3
			 WHERE event_id = $1`,
			s.tableName,
		),
		eventID,
		eventstoredomain.EventStoreDurumBekliyor,
		zaman,
	)
	return err
}

func (s *PostgresEventStoreService) listele(
	query string,
	args ...any,
) ([]eventstoredomain.EventStoreRecord, error) {
	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	sonuc := make([]eventstoredomain.EventStoreRecord, 0)

	for rows.Next() {
		kayit, err := scanEventStoreRecord(rows)
		if err != nil {
			return nil, err
		}
		sonuc = append(sonuc, kayit)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	sort.Slice(sonuc, func(i, j int) bool {
		return sonuc[i].OlusturmaTarihi.Before(sonuc[j].OlusturmaTarihi)
	})

	return sonuc, nil
}

func (s *PostgresEventStoreService) TumKayitlariListele() []eventstoredomain.EventStoreRecord {
	sonuc, err := s.listele(
		fmt.Sprintf(
			`SELECT %s FROM %s ORDER BY olusturma_tarihi ASC`,
			postgresSelectColumns(),
			s.tableName,
		),
	)
	if err != nil {
		return []eventstoredomain.EventStoreRecord{}
	}
	return sonuc
}

func (s *PostgresEventStoreService) TenantKayitlariniListele(
	tenantID string,
) []eventstoredomain.EventStoreRecord {
	sonuc, err := s.listele(
		fmt.Sprintf(
			`SELECT %s FROM %s
			 WHERE tenant_id = $1
			 ORDER BY olusturma_tarihi ASC`,
			postgresSelectColumns(),
			s.tableName,
		),
		tenantID,
	)
	if err != nil {
		return []eventstoredomain.EventStoreRecord{}
	}
	return sonuc
}

func (s *PostgresEventStoreService) TopicKayitlariniListele(
	topic string,
) []eventstoredomain.EventStoreRecord {
	sonuc, err := s.listele(
		fmt.Sprintf(
			`SELECT %s FROM %s
			 WHERE topic = $1
			 ORDER BY olusturma_tarihi ASC`,
			postgresSelectColumns(),
			s.tableName,
		),
		topic,
	)
	if err != nil {
		return []eventstoredomain.EventStoreRecord{}
	}
	return sonuc
}

func (s *PostgresEventStoreService) TenantTopicKayitlariniListele(
	tenantID string,
	topic string,
) []eventstoredomain.EventStoreRecord {
	sonuc, err := s.listele(
		fmt.Sprintf(
			`SELECT %s FROM %s
			 WHERE tenant_id = $1
			   AND topic = $2
			 ORDER BY olusturma_tarihi ASC`,
			postgresSelectColumns(),
			s.tableName,
		),
		tenantID,
		topic,
	)
	if err != nil {
		return []eventstoredomain.EventStoreRecord{}
	}
	return sonuc
}
