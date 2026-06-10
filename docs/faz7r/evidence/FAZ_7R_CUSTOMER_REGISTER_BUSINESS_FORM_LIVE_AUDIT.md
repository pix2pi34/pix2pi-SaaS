# FAZ 7-R — Customer Register Business Form Live Audit

Date: 2026-05-16T22:06:24+03:00

## Scope

- React source: /root/pix2pi/pix2pi-SaaS/web/customer-register/react
- Vue3 source: /root/pix2pi/pix2pi-SaaS/web/customer-register/vue3
- Backend: /root/pix2pi/pix2pi-SaaS/web/customer-register/backend/server.cjs
- Live React: https://panel.pix2pi.com.tr/customer-register/react/
- Live Vue3: https://panel.pix2pi.com.tr/customer-register/vue3/
- API Health: https://panel.pix2pi.com.tr/api/customer-register/health
- Data dir: /root/pix2pi/pix2pi-SaaS/web/customer-register/data

## Form Fields

Required:
- Vergi No
- Vergi Dairesi
- Firmanızın Adı
- Adres
- İlçe
- İl
- MERSİS No
- Mail

Optional starred fields:
- Tel No
- Web Adresi
- Ticaret Sicil No

## Test Results

- React HTTP: 200
- Vue3 HTTP: 200
- API HTTP: 200
- POST HTTP: 201
- Application ID: CR-20260516-C8EB09F9
- Application Status: PENDING
- Tenant Provisioned: false
- Mail Status: SENT

## Counters

- PASS_COUNT=33
- FAIL_COUNT=0
- WARN_COUNT=0

## Final Status

FINAL_STATUS=PASS
