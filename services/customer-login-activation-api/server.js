const http = require("http");
const https = require("https");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

const HOST = process.env.HOST || "127.0.0.1";
const PORT = Number(process.env.PORT || "9039");

const APPLICATIONS_DIR = process.env.APPLICATIONS_DIR || "/root/pix2pi/pix2pi-SaaS/web/customer-register/data/applications";
const LOGIN_ACCOUNTS_DIR = process.env.LOGIN_ACCOUNTS_DIR || "/root/pix2pi/pix2pi-SaaS/web/customer-login/data/accounts";
const MAIL_CODES_DIR = process.env.MAIL_CODES_DIR || "/root/pix2pi/pix2pi-SaaS/web/customer-login/data/mail-codes";

const RESEND_API_KEY = process.env.RESEND_API_KEY || "";
const FROM_EMAIL = process.env.FROM_EMAIL || "Pix2pi <no-reply@pix2pi.com.tr>";
const MAIL_PROVIDER = process.env.MAIL_PROVIDER || "resend";
const REAL_MAIL_ENABLED = String(process.env.REAL_MAIL_ENABLED || "false").toLowerCase() === "true";
const OTP_TTL_MINUTES = Number(process.env.OTP_TTL_MINUTES || "10");

const MARKER = "CUSTOMER_LOGIN_ACTIVATION_API_MARKER";
const ACTIVE_MARKER = "CUSTOMER_LOGIN_ACTIVE_ACCOUNT_MARKER";
const MAIL_MARKER = "CUSTOMER_LOGIN_REAL_MAIL_CODE_MARKER";
const VERIFY_MARKER = "CUSTOMER_LOGIN_MAIL_CODE_VERIFY_MARKER";
const HANDOFF_MARKER = "REGISTER_APPROVAL_HANDOFF_MARKER";

function nowIso() {
  return new Date().toISOString();
}

function normalizeEmail(email) {
  return String(email || "").trim().toLowerCase();
}

function sha(value) {
  return crypto.createHash("sha256").update(String(value)).digest("hex");
}

function codeHash(salt, code) {
  return sha(`${salt}:${String(code).trim()}`);
}

function sendJson(res, status, payload, extraHeaders = {}) {
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    "X-Pix2pi-Customer-Login-Activation": MARKER,
    ...extraHeaders
  });
  res.end(JSON.stringify(payload, null, 2));
}

function pick(...values) {
  for (const value of values) {
    if (value !== undefined && value !== null && String(value).trim() !== "") {
      return String(value).trim();
    }
  }
  return "";
}

function slug(value) {
  return String(value || "")
    .trim()
    .toLowerCase()
    .replace(/ı/g, "i")
    .replace(/ğ/g, "g")
    .replace(/ü/g, "u")
    .replace(/ş/g, "s")
    .replace(/ö/g, "o")
    .replace(/ç/g, "c")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 42) || "tenant";
}

function readJsonSafe(file) {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return null;
  }
}

function writeJsonAtomic(file, data) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const tmp = `${file}.tmp.${process.pid}.${Date.now()}`;
  fs.writeFileSync(tmp, JSON.stringify(data, null, 2) + "\n", "utf8");
  fs.renameSync(tmp, file);
}

function accountFile(email) {
  return path.join(LOGIN_ACCOUNTS_DIR, `${sha(normalizeEmail(email))}.json`);
}

function mailCodeFile(email) {
  return path.join(MAIL_CODES_DIR, `${sha(normalizeEmail(email))}.json`);
}

function getAccount(email) {
  const file = accountFile(email);
  if (!fs.existsSync(file)) return null;
  return readJsonSafe(file);
}

function getStatus(app) {
  return String(app.status || app.application_status || app.registration_status || "").toUpperCase();
}

function appEmails(app) {
  return [
    app.email,
    app.owner_email,
    app.ownerEmail,
    app.user_email,
    app.userEmail,
    app.contact_email,
    app.contactEmail,
    app.contact && app.contact.email,
    app.user && app.user.email,
    app.owner && app.owner.email,
    app.company && app.company.email
  ].map(normalizeEmail).filter(Boolean);
}

function findApplication(email) {
  const target = normalizeEmail(email);
  fs.mkdirSync(APPLICATIONS_DIR, { recursive: true });

  const matches = [];

  for (const file of fs.readdirSync(APPLICATIONS_DIR)) {
    if (!file.endsWith(".json") || file.startsWith(".backup.")) continue;

    const full = path.join(APPLICATIONS_DIR, file);
    const app = readJsonSafe(full);
    if (!app) continue;

    if (!appEmails(app).includes(target)) continue;

    const stat = fs.statSync(full);
    matches.push({
      file,
      full,
      app,
      status: getStatus(app),
      sort: Date.parse(pick(app.updated_at, app.activated_at, app.approved_at, app.created_at)) || stat.mtimeMs
    });
  }

  matches.sort((a, b) => b.sort - a.sort);
  return matches[0] || null;
}

function buildAccount(email, app, sourceFile) {
  const companyName = pick(app.company_name, app.companyName, app.firma_adi, app.company && app.company.name, "Pix2pi Müşteri");
  const ownerName = pick(app.owner_name, app.ownerName, app.yetkili_ad_soyad, app.user && app.user.name, "Owner Admin");
  const tenantSlug = slug(companyName);
  const tenantId = pick(app.tenant_id, app.tenantId, `tenant_${tenantSlug}_${sha(email).slice(0, 8)}`);

  return {
    marker: ACTIVE_MARKER,
    email: normalizeEmail(email),
    status: "ACTIVE",
    login_allowed: true,
    mail_code_allowed: true,
    tenant_id: tenantId,
    tenant_slug: tenantSlug,
    tenant_name: companyName,
    owner_name: ownerName,
    role: "OWNER_ADMIN",
    source_application_file: sourceFile || "",
    source_application_id: pick(app.application_id, app.id, sourceFile || ""),
    source_status: getStatus(app),
    activated_at: nowIso(),
    activated_by: "PIX2PI_OWNER_ADMIN",
    tenant_create_real_create: false,
    tenant_create_mode: "REAL_EMAIL_LOGIN_ACCOUNT_ACTIVATION",
    handoff_marker: HANDOFF_MARKER
  };
}

function activate(email) {
  const normalized = normalizeEmail(email);
  const found = findApplication(normalized);

  if (!found) {
    return {
      ok: false,
      marker: MARKER,
      code: "APPLICATION_NOT_FOUND",
      email: normalized,
      message: "Bu e-posta için kayıt başvurusu bulunamadı."
    };
  }

  if (!["APPROVED", "ACTIVE"].includes(found.status)) {
    return {
      ok: false,
      marker: MARKER,
      code: "APPLICATION_NOT_APPROVED",
      email: normalized,
      status: found.status,
      message: "Mail kodu açmak için başvuru önce Phoenix tarafından onaylanmalı."
    };
  }

  const account = buildAccount(normalized, found.app, found.file);
  writeJsonAtomic(accountFile(normalized), account);

  const app = {
    ...found.app,
    email: normalized,
    status: "ACTIVE",
    application_status: "ACTIVE",
    updated_at: nowIso(),
    login_activation: {
      marker: ACTIVE_MARKER,
      status: "ACTIVE",
      login_allowed: true,
      mail_code_allowed: true,
      account_file: accountFile(normalized),
      activated_at: account.activated_at,
      tenant_create_real_create: false,
      handoff_marker: HANDOFF_MARKER
    }
  };

  app.audit_trail = Array.isArray(found.app.audit_trail) ? found.app.audit_trail : [];
  app.audit_trail.push({
    at: nowIso(),
    actor: "PIX2PI_OWNER_ADMIN",
    action: "ACTIVATE_REAL_EMAIL_LOGIN_ACCOUNT",
    from_status: found.status,
    to_status: "ACTIVE",
    login_allowed: true,
    mail_code_allowed: true,
    tenant_create_real_create: false
  });

  fs.copyFileSync(found.full, path.join(APPLICATIONS_DIR, `.backup.${found.file}.${Date.now()}`));
  writeJsonAtomic(found.full, app);

  return {
    ok: true,
    marker: MARKER,
    active_marker: ACTIVE_MARKER,
    email: normalized,
    code: "CUSTOMER_LOGIN_ACTIVATED",
    status: "ACTIVE",
    login_allowed: true,
    mail_code_allowed: true,
    tenant_create_real_create: false,
    tenant_id: account.tenant_id
  };
}

function randomOtp() {
  return String(crypto.randomInt(100000, 1000000));
}

function resendRequest(payload) {
  return new Promise((resolve) => {
    const body = JSON.stringify(payload);

    const req = https.request(
      {
        hostname: "api.resend.com",
        path: "/emails",
        method: "POST",
        headers: {
          "Authorization": `Bearer ${RESEND_API_KEY}`,
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(body)
        },
        timeout: 15000
      },
      (res) => {
        let data = "";

        res.on("data", (chunk) => {
          data += chunk;
        });

        res.on("end", () => {
          let parsed = {};
          try {
            parsed = JSON.parse(data || "{}");
          } catch {
            parsed = { raw: data };
          }

          resolve({
            ok: res.statusCode >= 200 && res.statusCode < 300,
            statusCode: res.statusCode,
            data: parsed
          });
        });
      }
    );

    req.on("error", (error) => {
      resolve({
        ok: false,
        statusCode: 0,
        data: { error: error.message }
      });
    });

    req.on("timeout", () => {
      req.destroy();
      resolve({
        ok: false,
        statusCode: 0,
        data: { error: "RESEND_TIMEOUT" }
      });
    });

    req.write(body);
    req.end();
  });
}

async function sendRealMailCode(email) {
  const normalized = normalizeEmail(email);
  const account = getAccount(normalized);

  if (!account || account.status !== "ACTIVE" || account.login_allowed !== true) {
    return {
      ok: false,
      marker: MAIL_MARKER,
      code: "LOGIN_ACCOUNT_NOT_ACTIVE",
      email: normalized,
      message: "Bu e-posta için aktif müşteri hesabı yok."
    };
  }

  if (!REAL_MAIL_ENABLED || MAIL_PROVIDER !== "resend") {
    return {
      ok: false,
      marker: MAIL_MARKER,
      code: "REAL_MAIL_NOT_CONFIGURED",
      email: normalized,
      real_mail_enabled: REAL_MAIL_ENABLED,
      mail_provider: MAIL_PROVIDER,
      message: "Gerçek mail yapılandırılmamış."
    };
  }

  if (!RESEND_API_KEY) {
    return {
      ok: false,
      marker: MAIL_MARKER,
      code: "RESEND_API_KEY_MISSING",
      email: normalized,
      message: "RESEND_API_KEY eksik."
    };
  }

  const otp = randomOtp();
  const salt = crypto.randomBytes(16).toString("hex");
  const expiresAt = new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000).toISOString();

  const subject = `Pix2pi giriş kodunuz: ${otp}`;
  const text = `Pix2pi giriş kodunuz: ${otp}\n\nBu kod ${OTP_TTL_MINUTES} dakika geçerlidir.`;
  const html = `
    <div style="font-family:Arial,sans-serif;line-height:1.6;color:#101828">
      <h2>Pix2pi giriş kodunuz</h2>
      <p>Giriş işlemini tamamlamak için aşağıdaki kodu kullanın:</p>
      <div style="font-size:32px;font-weight:800;letter-spacing:6px;background:#eef4ff;border:1px solid #b2ccff;border-radius:14px;padding:18px;text-align:center;color:#175cd3">${otp}</div>
      <p>Bu kod <strong>${OTP_TTL_MINUTES} dakika</strong> geçerlidir.</p>
    </div>
  `;

  const providerResponse = await resendRequest({
    from: FROM_EMAIL,
    to: [normalized],
    subject,
    html,
    text,
    tags: [
      { name: "app", value: "pix2pi" },
      { name: "kind", value: "login_otp" }
    ]
  });

  const record = {
    marker: MAIL_MARKER,
    email: normalized,
    status: providerResponse.ok ? "SENT_REAL_EMAIL" : "SEND_FAILED",
    provider: "resend",
    provider_status_code: providerResponse.statusCode,
    provider_id: providerResponse.data && providerResponse.data.id ? providerResponse.data.id : "",
    provider_error: providerResponse.ok ? null : providerResponse.data,
    code_hash: codeHash(salt, otp),
    salt,
    raw_code_stored: false,
    attempts: 0,
    max_attempts: 5,
    sent_at: nowIso(),
    expires_at: expiresAt,
    sender: FROM_EMAIL,
    tenant_id: account.tenant_id,
    account_marker: account.marker
  };

  writeJsonAtomic(mailCodeFile(normalized), record);

  if (!providerResponse.ok) {
    return {
      ok: false,
      marker: MAIL_MARKER,
      code: "REAL_MAIL_SEND_FAILED",
      email: normalized,
      real_mail: false,
      provider: "resend",
      provider_status_code: providerResponse.statusCode,
      provider_error: providerResponse.data,
      message: "Gerçek mail gönderilemedi."
    };
  }

  return {
    ok: true,
    marker: MAIL_MARKER,
    code: "MAIL_CODE_SENT_REAL",
    email: normalized,
    mail_code_sent: true,
    real_mail: true,
    provider: "resend",
    provider_id: record.provider_id,
    expires_at: expiresAt,
    sender: FROM_EMAIL,
    tenant_id: account.tenant_id,
    message: "Giriş kodu e-posta adresinize gönderildi."
  };
}

function verifyMailCode(email, code) {
  const normalized = normalizeEmail(email);
  const file = mailCodeFile(normalized);

  if (!fs.existsSync(file)) {
    return {
      ok: false,
      marker: VERIFY_MARKER,
      code: "MAIL_CODE_NOT_FOUND",
      email: normalized,
      verified: false,
      message: "Aktif giriş kodu bulunamadı."
    };
  }

  const record = readJsonSafe(file);

  if (!record || record.status !== "SENT_REAL_EMAIL") {
    return {
      ok: false,
      marker: VERIFY_MARKER,
      code: "MAIL_CODE_NOT_ACTIVE",
      email: normalized,
      verified: false,
      message: "Giriş kodu aktif değil."
    };
  }

  if (Date.now() > Date.parse(record.expires_at || "")) {
    record.status = "EXPIRED";
    record.expired_at = nowIso();
    writeJsonAtomic(file, record);

    return {
      ok: false,
      marker: VERIFY_MARKER,
      code: "MAIL_CODE_EXPIRED",
      email: normalized,
      verified: false,
      message: "Giriş kodunun süresi doldu."
    };
  }

  record.attempts = Number(record.attempts || 0) + 1;

  if (record.attempts > Number(record.max_attempts || 5)) {
    record.status = "LOCKED";
    record.locked_at = nowIso();
    writeJsonAtomic(file, record);

    return {
      ok: false,
      marker: VERIFY_MARKER,
      code: "MAIL_CODE_LOCKED",
      email: normalized,
      verified: false,
      message: "Çok fazla hatalı deneme yapıldı."
    };
  }

  const verified = codeHash(record.salt, code) === record.code_hash;

  if (!verified) {
    record.last_failed_at = nowIso();
    writeJsonAtomic(file, record);

    return {
      ok: false,
      marker: VERIFY_MARKER,
      code: "MAIL_CODE_INVALID",
      email: normalized,
      verified: false,
      attempts: record.attempts,
      message: "Giriş kodu hatalı."
    };
  }

  record.status = "VERIFIED";
  record.verified_at = nowIso();
  writeJsonAtomic(file, record);

  const sessionId = crypto.randomBytes(24).toString("hex");

  return {
    ok: true,
    marker: VERIFY_MARKER,
    code: "LOGIN_VERIFIED",
    email: normalized,
    verified: true,
    real_mail: true,
    tenant_id: record.tenant_id,
    session_id: sessionId,
    message: "Giriş başarılı."
  };
}

function status(email) {
  const normalized = normalizeEmail(email);
  const account = getAccount(normalized);

  if (account && account.status === "ACTIVE") {
    return {
      ok: true,
      marker: MARKER,
      active_marker: ACTIVE_MARKER,
      email: normalized,
      found: true,
      status: "ACTIVE",
      code: "CUSTOMER_LOGIN_ACTIVE",
      login_allowed: true,
      mail_code_allowed: true,
      real_mail_enabled: REAL_MAIL_ENABLED,
      mail_provider: MAIL_PROVIDER,
      resend_key_present: !!RESEND_API_KEY,
      tenant_id: account.tenant_id,
      message: "Müşteri hesabı aktif. Gerçek mail kodu gönderilebilir."
    };
  }

  const app = findApplication(normalized);

  if (app) {
    const appStatus = getStatus(app.app);
    return {
      ok: true,
      marker: MARKER,
      email: normalized,
      found: true,
      status: appStatus,
      code: appStatus === "APPROVED" ? "APPROVED_ACTIVATION_REQUIRED" : "APPLICATION_PENDING",
      login_allowed: false,
      mail_code_allowed: false,
      real_mail_enabled: REAL_MAIL_ENABLED,
      mail_provider: MAIL_PROVIDER,
      message: appStatus === "APPROVED"
        ? "Başvuru onaylı ama login aktivasyonu yapılmamış."
        : "Başvuru Pix2pi onayı bekliyor."
    };
  }

  return {
    ok: true,
    marker: MARKER,
    email: normalized,
    found: false,
    status: "NOT_FOUND",
    code: "NOT_REGISTERED",
    login_allowed: false,
    mail_code_allowed: false,
    real_mail_enabled: REAL_MAIL_ENABLED,
    mail_provider: MAIL_PROVIDER,
    message: "Bu e-posta için aktif müşteri hesabı bulunamadı."
  };
}

function parseBody(req) {
  return new Promise((resolve) => {
    let body = "";

    req.on("data", (chunk) => {
      body += chunk;
      if (body.length > 1024 * 1024) req.destroy();
    });

    req.on("end", () => {
      if (!body) return resolve({});
      try {
        resolve(JSON.parse(body));
      } catch {
        resolve({});
      }
    });
  });
}

const server = http.createServer(async (req, res) => {
  try {
    const parsed = new URL(req.url, `http://${req.headers.host || "127.0.0.1"}`);
    const pathname = parsed.pathname.replace(/\/+$/, "") || "/";

    if (req.method === "GET" && pathname === "/health") {
      return sendJson(res, 200, {
        ok: true,
        marker: MARKER,
        active_marker: ACTIVE_MARKER,
        mail_marker: MAIL_MARKER,
        verify_marker: VERIFY_MARKER,
        status: "ok",
        port: PORT,
        mail_provider: MAIL_PROVIDER,
        real_mail_enabled: REAL_MAIL_ENABLED,
        resend_key_present: !!RESEND_API_KEY,
        from_email: FROM_EMAIL
      });
    }

    if (req.method === "GET" && pathname === "/status") {
      return sendJson(res, 200, status(parsed.searchParams.get("email") || ""));
    }

    if (req.method === "POST" && pathname === "/activate") {
      const body = await parseBody(req);
      return sendJson(res, 200, activate(body.email || parsed.searchParams.get("email") || ""));
    }

    if (req.method === "POST" && pathname === "/send-mail-code") {
      const body = await parseBody(req);
      return sendJson(res, 200, await sendRealMailCode(body.email || parsed.searchParams.get("email") || ""));
    }

    if (req.method === "POST" && pathname === "/verify-mail-code") {
      const body = await parseBody(req);
      const result = verifyMailCode(body.email || "", body.code || "");

      const headers = {};
      if (result.ok && result.session_id) {
        headers["Set-Cookie"] = `pix2pi_customer_session=${result.session_id}; Path=/; Max-Age=86400; HttpOnly; Secure; SameSite=Lax`;
      }

      return sendJson(res, 200, result, headers);
    }

    return sendJson(res, 404, {
      ok: false,
      marker: MARKER,
      error: "NOT_FOUND"
    });
  } catch (error) {
    return sendJson(res, 500, {
      ok: false,
      marker: MARKER,
      error: error.message || "INTERNAL_ERROR"
    });
  }
});

server.listen(PORT, HOST, () => {
  console.log(`${MARKER} ${MAIL_MARKER} ${VERIFY_MARKER} listening on ${HOST}:${PORT}`);
});
