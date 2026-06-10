"use strict";

const http = require("http");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const childProcess = require("child_process");

const PORT = Number(process.env.PIX2PI_CUSTOMER_LOGIN_OTP_PORT || "9044");
const HOST = process.env.PIX2PI_CUSTOMER_LOGIN_OTP_HOST || "127.0.0.1";
const REPO = process.env.PIX2PI_REPO || "/root/pix2pi/pix2pi-SaaS";
const APP_DIR = process.env.PIX2PI_APPLICATION_DIR || path.join(REPO, "web/customer-register/data/applications");
const OUTBOX_DIR = process.env.PIX2PI_MAIL_OUTBOX_DIR || path.join(REPO, "var/mail-outbox");
const OTP_DIR = process.env.PIX2PI_OTP_DIR || path.join(REPO, "var/customer-login-otp");
const FROM = process.env.PIX2PI_MAIL_FROM || "no-reply@pix2pi.com.tr";
const MARKER = "PIX2PI_CUSTOMER_LOGIN_PASSWORD_CHECK_OTP_MAIL_MARKER";
const OTP_TTL_SECONDS = Number(process.env.PIX2PI_OTP_TTL_SECONDS || "60");
const OTP_TTL_LABEL = process.env.PIX2PI_OTP_TTL_LABEL || "60 saniye";

fs.mkdirSync(OUTBOX_DIR, { recursive: true });
fs.mkdirSync(OTP_DIR, { recursive: true });

function sendJson(res, status, payload) {
  const body = JSON.stringify({ marker: MARKER, ...payload }, null, 2);
  res.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
    "x-pix2pi-marker": MARKER
  });
  res.end(body);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = "";
    req.on("data", (chunk) => {
      raw += chunk;
      if (raw.length > 1024 * 128) {
        reject(new Error("BODY_TOO_LARGE"));
        req.destroy();
      }
    });
    req.on("end", () => resolve(raw));
    req.on("error", reject);
  });
}

function safeJson(raw) {
  try {
    return JSON.parse(raw || "{}");
  } catch {
    return {};
  }
}

function sha256(value) {
  return crypto.createHash("sha256").update(String(value), "utf8").digest("hex");
}

function sanitizeEmail(email) {
  return String(email || "").trim().toLowerCase();
}

function isValidEmail(email) {
  return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);
}

function collectStrings(obj, out = []) {
  if (Array.isArray(obj)) {
    for (const item of obj) collectStrings(item, out);
  } else if (obj && typeof obj === "object") {
    for (const value of Object.values(obj)) collectStrings(value, out);
  } else if (typeof obj === "string") {
    out.push(obj);
  }
  return out;
}

function getValueByPath(obj, pathParts) {
  let cur = obj;
  for (const p of pathParts) {
    if (!cur || typeof cur !== "object") return undefined;
    cur = cur[p];
  }
  return cur;
}

function collectPasswordValues(obj, out = []) {
  if (Array.isArray(obj)) {
    for (const item of obj) collectPasswordValues(item, out);
    return out;
  }

  if (obj && typeof obj === "object") {
    for (const [key, value] of Object.entries(obj)) {
      const kl = String(key).toLowerCase();

      if (typeof value === "string") {
        if (
          kl.includes("password") ||
          kl.includes("sifre") ||
          kl.includes("şifre")
        ) {
          out.push({ key, value });
        }
      } else if (value && typeof value === "object") {
        collectPasswordValues(value, out);
      }
    }
  }

  return out;
}

function accountStatusScore(data) {
  const text = JSON.stringify(data).toLowerCase();

  let score = 0;
  if (text.includes('"status":"active"') || text.includes('"status": "active"')) score += 30;
  if (text.includes('"approval_status":"approved"') || text.includes('"approval_status": "approved"')) score += 20;
  if (text.includes('"login_enabled":true') || text.includes('"customer_login_enabled":true')) score += 20;
  if (text.includes("duplicate_inactive")) score -= 100;
  if (text.includes('"is_active":false') || text.includes('"active":false')) score -= 50;

  const company =
    data.companyName ||
    data.company_name ||
    data.company ||
    data.businessName ||
    data.business_name ||
    "";

  if (typeof company === "string" && company.trim() && company.trim() !== "-") score += 10;

  return score;
}

function emailMatches(data, email) {
  const strings = collectStrings(data).map((s) => String(s).trim().toLowerCase());
  if (strings.includes(email)) return true;

  const aliases = data.email_aliases || data.emailAliases || data.previous_emails || [];
  if (Array.isArray(aliases)) {
    for (const a of aliases) {
      if (String(a).trim().toLowerCase() === email) return true;
    }
  }

  return false;
}

function loadAccounts(email) {
  const files = fs.readdirSync(APP_DIR)
    .filter((name) => name.endsWith(".json") && !name.startsWith(".backup."))
    .sort();

  const matches = [];

  for (const file of files) {
    const full = path.join(APP_DIR, file);

    try {
      const data = JSON.parse(fs.readFileSync(full, "utf8"));
      if (emailMatches(data, email)) {
        matches.push({
          file,
          path: full,
          data,
          score: accountStatusScore(data)
        });
      }
    } catch {
      continue;
    }
  }

  matches.sort((a, b) => b.score - a.score);
  return matches;
}

function verifyPassword(data, password) {
  const digest = sha256(password);
  const values = collectPasswordValues(data);

  for (const item of values) {
    const v = String(item.value || "");
    const vl = v.trim().toLowerCase();
    const key = String(item.key || "").toLowerCase();

    if (!v) continue;

    if (
      (key.includes("hash") || key.includes("sha256")) &&
      /^[a-f0-9]{64}$/.test(vl) &&
      vl === digest
    ) {
      return { ok: true, method: "sha256", key: item.key };
    }

    if (
      !key.includes("hash") &&
      !key.includes("sha256") &&
      v === password
    ) {
      return { ok: true, method: "plain-prototype", key: item.key };
    }
  }

  return { ok: false, method: "none" };
}

function generateOtp() {
  return crypto.randomInt(0, 1000000).toString().padStart(6, "0");
}

function otpHash(email, code, purpose) {
  return sha256(`${email}:${purpose}:${code}`);
}

function storeOtp(email, purpose, code, accountFile) {
  const safe = email.replace(/[^a-z0-9_.-]/gi, "_");
  const file = path.join(OTP_DIR, `${Date.now()}_${safe}_${purpose}.json`);
  const now = new Date();
  const expires = new Date(now.getTime() + OTP_TTL_SECONDS * 1000);

  const payload = {
    email,
    purpose,
    account_file: accountFile || null,
    otp_hash_sha256: otpHash(email, code, purpose),
    created_at: now.toISOString(),
    expires_at: expires.toISOString(),
    ttl_seconds: OTP_TTL_SECONDS,
    used: false,
    marker: MARKER
  };

  fs.writeFileSync(file, JSON.stringify(payload, null, 2) + "\n");
  return file;
}

function commandExists(cmd) {
  try {
    const r = childProcess.spawnSync("sh", ["-lc", `command -v ${cmd}`], { encoding: "utf8" });
    return r.status === 0 && r.stdout.trim();
  } catch {
    return "";
  }
}

function writeOutbox(to, subject, text) {
  const safe = String(to).replace(/[^a-z0-9_.@-]/gi, "_");
  const file = path.join(OUTBOX_DIR, `${Date.now()}_${safe}.eml`);

  const eml = [
    `From: ${FROM}`,
    `To: ${to}`,
    `Subject: ${subject}`,
    "MIME-Version: 1.0",
    "Content-Type: text/plain; charset=UTF-8",
    "",
    text
  ].join("\n");

  fs.writeFileSync(file, eml);
  return file;
}

function sendMail(to, subject, text) {
  const outboxPath = writeOutbox(to, subject, text);

  const sendmail = commandExists("sendmail") || (fs.existsSync("/usr/sbin/sendmail") ? "/usr/sbin/sendmail" : "");
  if (sendmail) {
    const eml = fs.readFileSync(outboxPath, "utf8");
    const r = childProcess.spawnSync(sendmail, ["-t"], {
      input: eml,
      encoding: "utf8",
      timeout: 15000
    });

    if (r.status === 0) {
      return { ok: true, method: "sendmail", outbox_path: outboxPath };
    }

    return {
      ok: false,
      method: "sendmail",
      error: (r.stderr || r.stdout || `sendmail exit ${r.status}`).slice(0, 500),
      outbox_path: outboxPath
    };
  }

  const msmtp = commandExists("msmtp");
  if (msmtp) {
    const eml = fs.readFileSync(outboxPath, "utf8");
    const r = childProcess.spawnSync(msmtp, ["-t"], {
      input: eml,
      encoding: "utf8",
      timeout: 15000
    });

    if (r.status === 0) {
      return { ok: true, method: "msmtp", outbox_path: outboxPath };
    }

    return {
      ok: false,
      method: "msmtp",
      error: (r.stderr || r.stdout || `msmtp exit ${r.status}`).slice(0, 500),
      outbox_path: outboxPath
    };
  }

  const mail = commandExists("mail") || commandExists("mailx");
  if (mail) {
    const r = childProcess.spawnSync(mail, ["-s", subject, to], {
      input: text,
      encoding: "utf8",
      timeout: 15000
    });

    if (r.status === 0) {
      return { ok: true, method: path.basename(mail), outbox_path: outboxPath };
    }

    return {
      ok: false,
      method: path.basename(mail),
      error: (r.stderr || r.stdout || `${mail} exit ${r.status}`).slice(0, 500),
      outbox_path: outboxPath
    };
  }

  return {
    ok: false,
    method: "outbox-only",
    error: "MAIL_TRANSPORT_NOT_FOUND: sendmail/msmtp/mail yok. SMTP veya local MTA kurulmalı.",
    outbox_path: outboxPath
  };
}

function mailBodyForLogin(code) {
  return [
    "Pix2pi müşteri giriş kodunuz:",
    "",
    code,
    "",
    "Bu kod " + OTP_TTL_LABEL + " geçerlidir.",
    "Bu işlemi siz başlatmadıysanız bu mesajı dikkate almayın."
  ].join("\n");
}

function mailBodyForForgot(code) {
  return [
    "Pix2pi şifre sıfırlama kodunuz:",
    "",
    code,
    "",
    "Bu kod " + OTP_TTL_LABEL + " geçerlidir.",
    "Bu kod ile şifre sıfırlama işlemini tamamlayabilirsiniz."
  ].join("\n");
}

async function handleRequestLoginCode(req, res) {
  const body = safeJson(await readBody(req));
  const email = sanitizeEmail(body.email || body.e_posta || body.eposta);
  const password = String(body.password || body.sifre || body["şifre"] || "");

  if (!isValidEmail(email)) {
    return sendJson(res, 400, { ok: false, error: "INVALID_EMAIL" });
  }

  if (!password) {
    return sendJson(res, 400, { ok: false, error: "PASSWORD_REQUIRED" });
  }

  const accounts = loadAccounts(email);

  if (!accounts.length) {
    return sendJson(res, 404, { ok: false, error: "ACCOUNT_NOT_FOUND" });
  }

  const account = accounts[0];

  if (account.score < 0) {
    return sendJson(res, 403, { ok: false, error: "ACCOUNT_INACTIVE_OR_DUPLICATE" });
  }

  const passwordCheck = verifyPassword(account.data, password);

  if (!passwordCheck.ok) {
    return sendJson(res, 401, {
      ok: false,
      error: "INVALID_PASSWORD",
      password_valid: false,
      mail_sent: false
    });
  }

  const code = generateOtp();
  const otpFile = storeOtp(email, "login", code, account.file);
  const delivery = sendMail(email, "Pix2pi giriş kodunuz", mailBodyForLogin(code));

  return sendJson(res, 200, {
    ok: true,
    purpose: "login",
    password_valid: true,
    otp_generated: true,
    otp_file: otpFile,
    mail_sent: !!delivery.ok,
    delivery
  });
}

async function handleForgotPasswordCode(req, res) {
  const body = safeJson(await readBody(req));
  const email = sanitizeEmail(body.email || body.e_posta || body.eposta);

  if (!isValidEmail(email)) {
    return sendJson(res, 400, { ok: false, error: "INVALID_EMAIL" });
  }

  const accounts = loadAccounts(email);

  if (!accounts.length) {
    return sendJson(res, 200, {
      ok: true,
      purpose: "forgot-password",
      generic: true,
      message: "Eğer kayıt varsa şifre sıfırlama kodu gönderilir.",
      mail_sent: false
    });
  }

  const account = accounts[0];

  if (account.score < 0) {
    return sendJson(res, 200, {
      ok: true,
      purpose: "forgot-password",
      generic: true,
      message: "Eğer kayıt varsa şifre sıfırlama kodu gönderilir.",
      mail_sent: false
    });
  }

  const code = generateOtp();
  const otpFile = storeOtp(email, "forgot-password", code, account.file);
  const delivery = sendMail(email, "Pix2pi şifre sıfırlama kodunuz", mailBodyForForgot(code));

  return sendJson(res, 200, {
    ok: true,
    purpose: "forgot-password",
    otp_generated: true,
    otp_file: otpFile,
    mail_sent: !!delivery.ok,
    delivery
  });
}

async function handleVerifyCode(req, res) {
  const body = safeJson(await readBody(req));
  const email = sanitizeEmail(body.email || body.e_posta || body.eposta);
  const code = String(body.code || body.kod || "").trim();
  const purpose = String(body.purpose || "login").trim();

  if (!isValidEmail(email) || !/^\d{6}$/.test(code)) {
    return sendJson(res, 400, { ok: false, error: "INVALID_EMAIL_OR_CODE" });
  }

  const expected = otpHash(email, code, purpose);
  const files = fs.readdirSync(OTP_DIR)
    .filter((name) => name.endsWith(".json"))
    .map((name) => path.join(OTP_DIR, name))
    .sort()
    .reverse();

  for (const file of files) {
    try {
      const data = JSON.parse(fs.readFileSync(file, "utf8"));
      if (
        data.email === email &&
        data.purpose === purpose &&
        data.otp_hash_sha256 === expected &&
        data.used === false &&
        new Date(data.expires_at).getTime() >= Date.now()
      ) {
        data.used = true;
        data.used_at = new Date().toISOString();
        fs.writeFileSync(file, JSON.stringify(data, null, 2) + "\n");
        return sendJson(res, 200, { ok: true, verified: true, purpose });
      }
    } catch {
      continue;
    }
  }

  return sendJson(res, 401, { ok: false, error: "INVALID_OR_EXPIRED_CODE" });
}

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, `http://${req.headers.host || "localhost"}`);
    const pathname = url.pathname.replace(/\/+$/, "") || "/";

    if (req.method === "GET" && (pathname === "/health" || pathname === "/")) {
      const sendmail = commandExists("sendmail") || (fs.existsSync("/usr/sbin/sendmail") ? "/usr/sbin/sendmail" : "");
      const msmtp = commandExists("msmtp");
      const mail = commandExists("mail") || commandExists("mailx");

      return sendJson(res, 200, {
        ok: true,
        service: "customer-login-otp-api",
        app_dir: APP_DIR,
        outbox_dir: OUTBOX_DIR,
        otp_dir: OTP_DIR,
        mail_transport: sendmail ? "sendmail" : msmtp ? "msmtp" : mail ? path.basename(mail) : "outbox-only"
      });
    }

    if (req.method !== "POST") {
      return sendJson(res, 405, { ok: false, error: "METHOD_NOT_ALLOWED" });
    }

    if (
      pathname === "/request-login-code" ||
      pathname === "/login/request-code" ||
      pathname === "/send-login-code"
    ) {
      return await handleRequestLoginCode(req, res);
    }

    if (
      pathname === "/forgot-password-code" ||
      pathname === "/forgot-password/request-code" ||
      pathname === "/forgot"
    ) {
      return await handleForgotPasswordCode(req, res);
    }

    if (
      pathname === "/verify-code" ||
      pathname === "/otp/verify"
    ) {
      return await handleVerifyCode(req, res);
    }

    return sendJson(res, 404, { ok: false, error: "NOT_FOUND", path: pathname });
  } catch (err) {
    return sendJson(res, 500, {
      ok: false,
      error: err && err.message ? err.message : "INTERNAL_ERROR"
    });
  }
});

server.listen(PORT, HOST, () => {
  console.log(`${MARKER} listening on ${HOST}:${PORT}`);
});
