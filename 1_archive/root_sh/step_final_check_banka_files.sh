#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

echo "=== BANKA MODUL DOSYA KONTROL ==="

ls -lah internal/erp/core/banka/domain/erp_banka_hesap.go
ls -lah internal/erp/core/banka/domain/erp_banka_hareket.go
ls -lah internal/erp/core/banka/service/erp_banka_service.go
ls -lah cmd/erp/core/ufk/erp_ufk_main.go
ls -lah step_8_run_banka_engine.sh

echo
echo "=== BANKA MODUL ICERIK KONTROL ==="

grep -n "type BankaHesap struct" internal/erp/core/banka/domain/erp_banka_hesap.go
grep -n "type BankaHareket struct" internal/erp/core/banka/domain/erp_banka_hareket.go
grep -n "type BankaService struct" internal/erp/core/banka/service/erp_banka_service.go
grep -n "func NewBankaService" internal/erp/core/banka/service/erp_banka_service.go
grep -n "func (s \\*BankaService) BankaHesapOlustur" internal/erp/core/banka/service/erp_banka_service.go
grep -n "func (s \\*BankaService) BankaHareketEkle" internal/erp/core/banka/service/erp_banka_service.go
grep -n "func (s \\*BankaService) BakiyeHesapla" internal/erp/core/banka/service/erp_banka_service.go
grep -n "OK ✅ banka engine calisti" cmd/erp/core/ufk/erp_ufk_main.go

echo
echo "OK ✅ banka modulu final dosya kontrolu tamam"
