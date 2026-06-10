# Move Live Web To Oldweb Except Login/Register Audit

## Request

Move live web files/pages into oldweb under pix2pi-SaaS, except login and register pages.

## Source

/var/www/pix2pi/live

## Target

/root/pix2pi/pix2pi-SaaS/oldweb/live

## Protected Live Items

- /var/www/pix2pi/live/customer-login
- /var/www/pix2pi/live/customer-register

## Moved Count

MOVED_COUNT=8

## Kept Count

KEPT_COUNT=2

## Before Count

BEFORE_COUNT=10

## Oldweb Live Count

OLDWEB_COUNT=8

## Moved Items

```
assets -> /root/pix2pi/pix2pi-SaaS/oldweb/live/assets
customer-panel -> /root/pix2pi/pix2pi-SaaS/oldweb/live/customer-panel
faz1 -> /root/pix2pi/pix2pi-SaaS/oldweb/live/faz1
faz3 -> /root/pix2pi/pix2pi-SaaS/oldweb/live/faz3
faz4r -> /root/pix2pi/pix2pi-SaaS/oldweb/live/faz4r
index.html -> /root/pix2pi/pix2pi-SaaS/oldweb/live/index.html
localization-ek2 -> /root/pix2pi/pix2pi-SaaS/oldweb/live/localization-ek2
owner-panel -> /root/pix2pi/pix2pi-SaaS/oldweb/live/owner-panel
```

## Kept Items

```
KORUNDU: customer-login
KORUNDU: customer-register
```

## Remaining Live Items

```
customer-login
customer-register
```

## Oldweb Live Items

```
assets
customer-panel
faz1
faz3
faz4r
index.html
localization-ek2
owner-panel
```

## Tests

- Repo exists: PASS
- Live dir exists: PASS
- customer-login preserved: PASS
- customer-register preserved: PASS
- only login/register remain under live: PASS
- oldweb/live exists: PASS
- backup created: PASS

## Counts

- PASS_COUNT=12
- FAIL_COUNT=0
- WARN_COUNT=0
