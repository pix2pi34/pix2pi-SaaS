package kernel

import "time"

type KernelKV struct {
	ID        uint   `gorm:"primaryKey"`
	K         string `gorm:"size:190;uniqueIndex;not null"`
	V         string `gorm:"type:text;not null"`
	CreatedAt time.Time
	UpdatedAt time.Time
}
