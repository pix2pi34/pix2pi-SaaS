package domain

import "time"

type BackupRecord struct {
	BackupID        string
	TenantID        string
	TenantUUID      string
	FilePath        string
	Content         string
	OlusturmaTarihi time.Time
}
