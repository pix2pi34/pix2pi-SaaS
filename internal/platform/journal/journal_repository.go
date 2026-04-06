package journal

import (
	"database/sql"
)

type Repository struct {
	db *sql.DB
}

func NewRepository(db *sql.DB) *Repository {
	return &Repository{db: db}
}

func (r *Repository) Save(entry JournalEntry) error {

	var entryID int

	err := r.db.QueryRow(`
		INSERT INTO journal_entries (event_id, tenant_id, belge_tipi, aciklama)
		VALUES ($1,$2,$3,$4)
		RETURNING id
	`,
		entry.EventID,
		entry.TenantID,
		entry.BelgeTipi,
		entry.Aciklama,
	).Scan(&entryID)

	if err != nil {
		return err
	}

	// 🔴 CRITICAL FIX: değer kopyalayarak insert
	for i := range entry.Lines {

		l := entry.Lines[i] // <-- COPY (çok kritik)

		_, err := r.db.Exec(`
			INSERT INTO journal_lines (journal_entry_id, hesap_kodu, hesap_adi, borc, alacak)
			VALUES ($1,$2,$3,$4,$5)
		`,
			entryID,
			l.HesapKodu,
			l.HesapAdi,
			l.Borc,
			l.Alacak,
		)

		if err != nil {
			return err
		}
	}

	return nil
}
