#!/bin/bash

BASE=~/pix2pi/pix2pi-SaaS/internal/erp

mkdir -p $BASE/core/kernel/ufk/domain
mkdir -p $BASE/core/kernel/ufk/application
mkdir -p $BASE/core/kernel/ufk/engine
mkdir -p $BASE/core/kernel/ufk/service
mkdir -p $BASE/core/kernel/ufk/ports
mkdir -p $BASE/core/kernel/ufk/infra

mkdir -p $BASE/core/finance
mkdir -p $BASE/core/tax
mkdir -p $BASE/core/audit
mkdir -p $BASE/core/reconciliation
mkdir -p $BASE/core/intelligence

mkdir -p $BASE/business/sales
mkdir -p $BASE/business/purchase
mkdir -p $BASE/business/inventory
mkdir -p $BASE/business/payments
mkdir -p $BASE/business/pos
mkdir -p $BASE/business/banking
mkdir -p $BASE/business/marketplace

mkdir -p $BASE/operations/reporting
mkdir -p $BASE/operations/export
mkdir -p $BASE/operations/ebelge
mkdir -p $BASE/operations/declaration
mkdir -p $BASE/operations/accountant
mkdir -p $BASE/operations/dashboards

mkdir -p $BASE/shared/contracts
mkdir -p $BASE/shared/enums
mkdir -p $BASE/shared/errors
mkdir -p $BASE/shared/helpers
mkdir -p $BASE/shared/money
mkdir -p $BASE/shared/idgen

echo "ERP structure created successfully"
