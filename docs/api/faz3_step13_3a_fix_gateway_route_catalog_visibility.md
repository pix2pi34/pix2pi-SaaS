# FAZ 3 / STEP 13.3A-FIX — Gateway Route Catalog Visibility Fix

## Amaç

Canlı `/internal/routes` çıktısında ERP Runtime endpoint görünürlüğünü sağlamak.

## Problem

Endpoint canlı çalışıyordu ancak `/internal/routes` katalog çıktısında görünmüyordu.

## Endpoint

POST `/api/v1/erp/runtime/flows`

## Yapılan Düzeltme

`cmd/api-gateway/gateway_routes.go` içine protected catalog kaydı eklendi:

- Method: POST
- Path: `/api/v1/erp/runtime/flows`
- Scope: protected
- Auth: jwt+tenant
- Description: erp runtime flow create

## Not

Bu düzeltme endpoint çalışma davranışını değiştirmez; sadece route catalog / observability görünürlüğünü tamamlar.
