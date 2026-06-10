# Pix2pi Public API Developer Docs

Version: `v1`

Base URL: `https://api.pix2pi.com.tr`

## Sandbox

Sandbox ortamında production veri erişimi kapalıdır. Sandbox namespace formatı `sandbox:{tenant_id}:{app_id}`.

## API Key

API key secret yalnızca üretildiği anda gösterilir. Kalıcı saklama alanında sadece `sha256` hash tutulur.

## Quota

Quota `tenant_id + app_id + key_id + environment + scope + window` boyutlarında uygulanır.

## App Auth

App auth doğrulaması tenant, app, key, environment ve effective scope uyumunu kontrol eder.

## Endpoint Registry

Runtime endpoint registry üzerinden üretilecektir.
