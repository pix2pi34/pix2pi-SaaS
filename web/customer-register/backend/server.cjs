'use strict';

const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PORT = Number(process.env.CUSTOMER_REGISTER_API_PORT || 9024);
const DATA_DIR = process.env.CUSTOMER_REGISTER_DATA_DIR || path.join(__dirname, '..', 'data');
const JSONL_FILE = path.join(DATA_DIR, 'applications.jsonl');
const JSON_DIR = path.join(DATA_DIR, 'applications');

const RESEND_API_KEY = process.env.RESEND_API_KEY || '';
const ADMIN_EMAIL = process.env.PIX2PI_ADMIN_EMAIL || 'surucukursu58@gmail.com';
const FROM_EMAIL = process.env.PIX2PI_RESEND_FROM || 'Pix2pi <onboarding@pix2pi.com.tr>';
const PANEL_HOST = process.env.CUSTOMER_REGISTER_PANEL_HOST || 'panel.pix2pi.com.tr';

fs.mkdirSync(DATA_DIR, { recursive: true });
fs.mkdirSync(JSON_DIR, { recursive: true });

function sendJson(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
    'Cache-Control': 'no-store',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'X-Pix2pi-Marker': 'CUSTOMER_REGISTER_BUSINESS_BACKEND_MARKER'
  });
  res.end(body);
}

function clean(v) {
  return String(v || '').trim();
}

function isEmail(v) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(clean(v));
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', chunk => {
      data += chunk;
      if (data.length > 1024 * 1024) {
        reject(new Error('Body too large'));
        req.destroy();
      }
    });
    req.on('end', () => resolve(data));
    req.on('error', reject);
  });
}

function escapeHtml(s) {
  return String(s)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

function normalize(input) {
  return {
    taxNo: clean(input.taxNo || input.vergiNo),
    taxOffice: clean(input.taxOffice || input.vergiDairesi),
    companyName: clean(input.companyName || input.firmaAdi || input.companyTitle),
    address: clean(input.address || input.adres),
    district: clean(input.district || input.ilce),
    city: clean(input.city || input.il),
    phone: clean(input.phone || input.telNo),
    website: clean(input.website || input.webAdresi),
    mersisNo: clean(input.mersisNo),
    tradeRegistryNo: clean(input.tradeRegistryNo || input.ticaretSicilNo),
    email: clean(input.email || input.mail)
  };
}

function validate(app) {
  const errors = [];

  if (!/^[0-9]{10,11}$/.test(app.taxNo)) errors.push('Vergi No 10 veya 11 haneli olmalı');
  if (app.taxOffice.length < 2) errors.push('Vergi Dairesi zorunlu');
  if (app.companyName.length < 2) errors.push('Firmanızın Adı zorunlu');
  if (app.address.length < 5) errors.push('Adres zorunlu');
  if (app.district.length < 2) errors.push('İlçe zorunlu');
  if (app.city.length < 2) errors.push('İl zorunlu');
  if (app.mersisNo.length < 5) errors.push('MERSİS No zorunlu');
  if (!isEmail(app.email)) errors.push('Mail geçerli olmalı');

  // Yıldızlı alanlar opsiyoneldir:
  // phone, website, tradeRegistryNo

  return errors;
}

function makeApplication(app) {
  const now = new Date();
  const id = `CR-${now.toISOString().slice(0,10).replace(/-/g, '')}-${crypto.randomBytes(4).toString('hex').toUpperCase()}`;

  return {
    id,
    status: 'PENDING',
    tenantProvisioned: false,
    adminApprovalRequired: true,
    mailStatus: 'NOT_ATTEMPTED',
    source: 'customer-register-business-form-live',
    submittedAt: now.toISOString(),

    taxNo: app.taxNo,
    taxOffice: app.taxOffice,
    companyName: app.companyName,
    address: app.address,
    district: app.district,
    city: app.city,
    phone: app.phone,
    website: app.website,
    mersisNo: app.mersisNo,
    tradeRegistryNo: app.tradeRegistryNo,
    email: app.email,

    optionalFields: {
      phone: true,
      website: true,
      tradeRegistryNo: true
    }
  };
}

function persist(app) {
  fs.appendFileSync(JSONL_FILE, JSON.stringify(app) + '\n', 'utf8');
  fs.writeFileSync(path.join(JSON_DIR, `${app.id}.json`), JSON.stringify(app, null, 2), 'utf8');
}

function updateJson(app) {
  fs.writeFileSync(path.join(JSON_DIR, `${app.id}.json`), JSON.stringify(app, null, 2), 'utf8');
}

async function sendResendMail(to, subject, html, text) {
  if (!RESEND_API_KEY) {
    throw new Error('RESEND_API_KEY missing');
  }

  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${RESEND_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      from: FROM_EMAIL,
      to: [to],
      subject,
      html,
      text
    })
  });

  const raw = await response.text();
  let parsed = {};
  try { parsed = JSON.parse(raw || '{}'); } catch (_) { parsed = { raw }; }

  if (!response.ok) {
    throw new Error(`Resend HTTP ${response.status}: ${raw}`);
  }

  return {
    ok: true,
    statusCode: response.status,
    providerId: parsed.id || null
  };
}

function applicantHtml(app) {
  return `
  <div style="font-family:Arial,sans-serif;line-height:1.5">
    <h2>Pix2pi işletme başvurunuz alındı</h2>
    <p>Merhaba,</p>
    <p><b>${escapeHtml(app.companyName)}</b> için işletme kayıt başvurunuz alınmıştır.</p>
    <p>Başvuru No: <b>${app.id}</b></p>
    <p>Durum: <b>${app.status}</b></p>
    <p>Tenant hemen açılmadı. Admin onayı sonrası bilgilendirme yapılacaktır.</p>
    <p>Giriş ekranı: https://${PANEL_HOST}/customer-login/react/</p>
  </div>`;
}

function adminHtml(app) {
  return `
  <div style="font-family:Arial,sans-serif;line-height:1.5">
    <h2>Yeni Pix2pi işletme kayıt başvurusu</h2>
    <ul>
      <li>Başvuru No: <b>${app.id}</b></li>
      <li>Firma: ${escapeHtml(app.companyName)}</li>
      <li>Vergi No: ${escapeHtml(app.taxNo)}</li>
      <li>Vergi Dairesi: ${escapeHtml(app.taxOffice)}</li>
      <li>Adres: ${escapeHtml(app.address)}</li>
      <li>İlçe: ${escapeHtml(app.district)}</li>
      <li>İl: ${escapeHtml(app.city)}</li>
      <li>Tel No: ${escapeHtml(app.phone || 'Opsiyonel / boş')}</li>
      <li>Web Adresi: ${escapeHtml(app.website || 'Opsiyonel / boş')}</li>
      <li>MERSİS No: ${escapeHtml(app.mersisNo)}</li>
      <li>Ticaret Sicil No: ${escapeHtml(app.tradeRegistryNo || 'Opsiyonel / boş')}</li>
      <li>Mail: ${escapeHtml(app.email)}</li>
      <li>Durum: ${app.status}</li>
      <li>Tenant açıldı mı: ${app.tenantProvisioned ? 'Evet' : 'Hayır'}</li>
    </ul>
    <p>Admin onayı bekleniyor.</p>
  </div>`;
}

async function handleApplication(req, res) {
  let raw = '';
  try {
    raw = await readBody(req);
  } catch (err) {
    sendJson(res, 413, { ok: false, error: err.message });
    return;
  }

  let input = {};
  try {
    input = JSON.parse(raw || '{}');
  } catch (_) {
    sendJson(res, 400, { ok: false, error: 'JSON body geçersiz' });
    return;
  }

  const normalized = normalize(input);
  const errors = validate(normalized);

  if (errors.length) {
    sendJson(res, 422, {
      ok: false,
      errors,
      marker: 'CUSTOMER_REGISTER_BUSINESS_VALIDATION_FAILED'
    });
    return;
  }

  const app = makeApplication(normalized);
  persist(app);

  const responsePayload = {
    ok: true,
    application: {
      id: app.id,
      status: app.status,
      tenantProvisioned: app.tenantProvisioned,
      adminApprovalRequired: app.adminApprovalRequired,
      mailStatus: app.mailStatus
    },
    marker: 'CUSTOMER_REGISTER_BUSINESS_APPLICATION_CREATED'
  };

  if (RESEND_API_KEY) {
    try {
      const applicantMail = await sendResendMail(
        app.email,
        `Pix2pi başvurunuz alındı - ${app.id}`,
        applicantHtml(app),
        `Pix2pi başvurunuz alındı. Başvuru No: ${app.id}. Durum: ${app.status}. Tenant admin onayı bekliyor.`
      );

      const adminMail = await sendResendMail(
        ADMIN_EMAIL,
        `Yeni Pix2pi işletme başvurusu - ${app.id}`,
        adminHtml(app),
        `Yeni Pix2pi işletme başvurusu: ${app.id}. Firma: ${app.companyName}. Durum: ${app.status}.`
      );

      app.mailStatus = 'SENT';
      app.mails = { applicant: applicantMail, admin: adminMail };
      updateJson(app);

      responsePayload.application.mailStatus = 'SENT';
      responsePayload.mails = app.mails;
    } catch (err) {
      app.mailStatus = 'FAILED';
      app.mailError = err.message || String(err);
      updateJson(app);

      responsePayload.application.mailStatus = 'FAILED';
      responsePayload.mailError = app.mailError;
    }
  } else {
    app.mailStatus = 'SKIPPED_NO_RESEND_KEY';
    updateJson(app);
    responsePayload.application.mailStatus = app.mailStatus;
  }

  sendJson(res, 201, responsePayload);
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

  if (req.method === 'OPTIONS') {
    sendJson(res, 204, {});
    return;
  }

  if (req.method === 'GET' && url.pathname === '/health') {
    sendJson(res, 200, {
      ok: true,
      service: 'pix2pi-customer-register',
      status: 'healthy',
      marker: 'CUSTOMER_REGISTER_BUSINESS_BACKEND_MARKER',
      tenantAutoProvision: false,
      dataDir: DATA_DIR,
      mailReady: Boolean(RESEND_API_KEY)
    });
    return;
  }

  if (req.method === 'GET' && url.pathname === '/api/customer-register/health') {
    sendJson(res, 200, {
      ok: true,
      service: 'pix2pi-customer-register',
      status: 'healthy',
      marker: 'CUSTOMER_REGISTER_BUSINESS_API_HEALTH_MARKER',
      tenantAutoProvision: false
    });
    return;
  }

  if (req.method === 'POST' && url.pathname === '/api/customer-register/applications') {
    await handleApplication(req, res);
    return;
  }

  sendJson(res, 404, { ok: false, error: 'not found' });
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`pix2pi customer register business backend listening on 127.0.0.1:${PORT}`);
});
