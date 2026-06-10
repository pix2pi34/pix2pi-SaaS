package dbrouter

import (
	"context"
	"log"

	"gorm.io/gorm"
)

type ctxKey string

const txKey ctxKey = "tx_active"

var writeDB *gorm.DB
var readDB *gorm.DB

func Init(w *gorm.DB, r *gorm.DB) {
	writeDB = w
	readDB = r
}

func WithTransaction(ctx context.Context) context.Context {
	return context.WithValue(ctx, txKey, true)
}

func isTx(ctx context.Context) bool {
	val := ctx.Value(txKey)
	if v, ok := val.(bool); ok {
		return v
	}
	return false
}

func GetWriteDB() *gorm.DB {
	return writeDB
}

func GetReadDB(ctx context.Context) *gorm.DB {
	// 🔥 TX varsa zorla primary
	if isTx(ctx) {
		log.Println("DEBUG ▶ TX MODE → force PRIMARY")
		return writeDB
	}

	// normal read → replica
	if readDB != nil {
		log.Println("DEBUG ▶ READ ROUTER → replica aktif")
		return readDB
	}

	log.Println("WARN ⚠️ readDB nil → fallback primary")
	return writeDB
}
