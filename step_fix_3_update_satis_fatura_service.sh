#!/bin/bash
set -e

cd ~/pix2pi/pix2pi-SaaS

sed -i 's/s\.cariHesapService\.GetAccount(/s.cariHesapService.CariHesapGetir(/g' \
  internal/erp/core/satis/service/erp_satis_fatura_service.go

echo "OK ✅ satis fatura service metod adi duzeltildi"
