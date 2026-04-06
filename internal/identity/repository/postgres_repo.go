package repository

import (
	"fmt"
	"regexp"

	"github.com/divrigili/pix2pi-SaaS/internal/identity/domain"
	"github.com/divrigili/pix2pi-SaaS/internal/platform/kernel"
	"gorm.io/gorm"
)

var onlyDigits = regexp.MustCompile(`^\d+$`)

type PostgresRepo struct {
	db *gorm.DB
}

func NewPostgresRepo(db *gorm.DB) *PostgresRepo {
	return &PostgresRepo{db: db}
}

func (r *PostgresRepo) ensureTenant(tx *gorm.DB, tenantID string) (string, error) {
	if tenantID == "" || !onlyDigits.MatchString(tenantID) {
		return "", fmt.Errorf("invalid tenant id")
	}

	schema := "tenant_" + tenantID

	if err := tx.Exec(fmt.Sprintf(`CREATE SCHEMA IF NOT EXISTS "%s"`, schema)).Error; err != nil {
		return "", err
	}

	if err := tx.Exec(fmt.Sprintf(`SET LOCAL search_path TO "%s", public`, schema)).Error; err != nil {
		return "", err
	}

	// tenant schema içinde tablo migrate
	if err := tx.AutoMigrate(&domain.User{}); err != nil {
		return "", err
	}

	return schema, nil
}

func (r *PostgresRepo) CreateUser(kctx kernel.Context, email string, name string) error {
	return r.db.Transaction(func(tx *gorm.DB) error {

		_, err := r.ensureTenant(tx, kctx.TenantID())
		if err != nil {
			return err
		}

		u := domain.User{
			Email: email,
			Name:  name,
		}

		return tx.Create(&u).Error
	})
}

func (r *PostgresRepo) ListUsers(kctx kernel.Context) ([]domain.User, error) {
	var users []domain.User

	err := r.db.Transaction(func(tx *gorm.DB) error {

		_, err := r.ensureTenant(tx, kctx.TenantID())
		if err != nil {
			return err
		}

		return tx.Find(&users).Error
	})

	return users, err
}
