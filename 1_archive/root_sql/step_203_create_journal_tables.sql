CREATE TABLE IF NOT EXISTS journal_entries (
    id SERIAL PRIMARY KEY,
    event_id TEXT,
    tenant_id TEXT,
    belge_tipi TEXT,
    aciklama TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS journal_lines (
    id SERIAL PRIMARY KEY,
    journal_entry_id INT NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
    hesap_kodu TEXT NOT NULL,
    hesap_adi TEXT NOT NULL,
    borc NUMERIC(18,2) DEFAULT 0,
    alacak NUMERIC(18,2) DEFAULT 0
);
