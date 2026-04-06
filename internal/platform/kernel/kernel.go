package kernel

import (
	"log"
	"os"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type DBManager struct {
	Write *gorm.DB
	Read  *gorm.DB
}

var DB *DBManager

func InitDB() {
	writeDSN := os.Getenv("DB_WRITE_DSN")
	readDSN := os.Getenv("DB_READ_DSN")

	if writeDSN == "" {
		log.Fatal("DB_WRITE_DSN bos")
	}

	if readDSN == "" {
		log.Println("READ DB yok, write DB kullanilacak")
		readDSN = writeDSN
	}

	writeDB, err := gorm.Open(postgres.Open(writeDSN), &gorm.Config{})
	if err != nil {
		log.Fatal("Write DB baglanamadi:", err)
	}

	readDB, err := gorm.Open(postgres.Open(readDSN), &gorm.Config{})
	if err != nil {
		log.Fatal("Read DB baglanamadi:", err)
	}

	DB = &DBManager{
		Write: writeDB,
		Read:  readDB,
	}

	log.Println("OK ✅ DB Manager init")
}

// helper
func GetWriteDB() *gorm.DB {
	if DB == nil {
		return nil
	}
	return DB.Write
}

func GetReadDB() *gorm.DB {
	if DB == nil {
		return nil
	}
	return DB.Read
}
