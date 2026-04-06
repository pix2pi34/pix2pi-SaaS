package domain

import "gorm.io/gorm"

type Account struct {
	gorm.Model
	Name string
}
