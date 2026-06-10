"use strict";

const http = require("http");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const querystring = require("querystring");

const MARKER = "PIX2PI_CUSTOMER_REGISTER_SUBMIT_API_MARKER";
const HOST = process.env.HOST || "127.0.0.1";
const PORT = Number(process.env.PORT || "9036");
const APP_DIR = process.env.PIX2PI_CUSTOMER_APPLICATION_DIR || "/root/pix2pi/pix2pi-SaaS/web/customer-register/data/applications";

process.on("uncaughtException", (err) => {
  console.error("UNCAUGHT_EXCEPTION", err && err.stack ? err.stack : err);
});

process.on("unhandledRejection", (err) => {
  console.error("UNHANDLED_REJECTION", err && err.stack ? err.stack : err);
});

function send(res, status, obj) {
  const body = JSON.stringify({ marker: MARKER, ...obj }, null, 2);
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    "X-Pix2pi-Marker": MARKER
  });
  res.end(body);
}

function nowIso() {
  return new Date().toISOString();
}

function todayId() {
  const d = new Date();
  return [
    d.getFullYear(),
    String(d.getMonth() + 1).padStart(2, "0"),
    String(d.getDate()).padStart(2, "0")
  ].join("");
}

function newApplicationId() {
  return "CR-" + todayId() + "-" + crypto.randomBytes(4).toString("hex").toUpperCase();
}

function sha256(value) {
  return crypto.createHash("sha256").update(String(value || ""), "utf8").digest("hex");
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = "";
    req.on("data", (chunk) => {
      raw += chunk;
      if (raw.length > 1024 * 1024) {
        reject(new Error("BODY_TOO_LARGE"));
        req.destroy();
      }
    });
    req.on("end", () => resolve(raw));
    req.on("error", reject);
  });
}

function parseBody(req, raw) {
  const type = String(req.headers["content-type"] || "").toLowerCase();

  if (type.includes("application/json")) {
    if (!raw) return {};
    return JSON.parse(raw);
  }

  if (type.includes("application/x-www-form-urlencoded")) {
    return querystring.parse(raw);
  }

  if (!raw) return {};

  try {
    return JSON.parse(raw);
  } catch {
    return querystring.parse(raw);
  }
}

function pick(obj, aliases) {
  const lower = {};
  for (const [k, v] of Object.entries(obj || {})) {
    lower[String(k).toLowerCase()] = v;
  }

  for (const key of aliases) {
    if (obj[key] !== undefined && obj[key] !== null && String(obj[key]).trim() !== "") {
      return String(obj[key]).trim();
    }

    const v = lower[String(key).toLowerCase()];
    if (v !== undefined && v !== null && String(v).trim() !== "") {
      return String(v).trim();
    }
  }

  return "";
}

function normalize(body) {
  return {
    tax_number: pick(body, ["tax_number", "taxNo", "vergiNo", "vergi_no", "Vergi No"]),
    tax_office: pick(body, ["tax_office", "taxOffice", "vergiDairesi", "vergi_dairesi", "Vergi Dairesi"]),
    company_name: pick(body, ["company_name", "companyName", "firmName", "firmaAdi", "firma_adı", "Firmanızın Adı", "Firmanizin Adi", "company"]),
    address: pick(body, ["address", "adres", "Adres"]),
    district: pick(body, ["district", "ilce", "ilçe", "İlçe"]),
    city: pick(body, ["city", "il", "İl"]),
    phone: pick(body, ["phone", "tel", "telNo", "telefon", "Tel No"]),
    web_address: pick(body, ["web_address", "webAddress", "website", "web", "Web Adresi"]),
    mersis_no: pick(body, ["mersis_no", "mersisNo", "MERSIS No", "MERSİS No"]),
    trade_registry_no: pick(body, ["trade_registry_no", "tradeRegistryNo", "ticaretSicilNo", "Ticaret Sicil No"]),
    email: pick(body, ["email", "mail", "e_mail", "Mail", "E-posta"]),
    password: pick(body, ["password", "sifre", "şifre", "Sifre", "Şifre"]),
    password_confirm: pick(body, ["password_confirm", "passwordConfirm", "sifreTekrar", "şifreTekrar", "Sifre Tekrar", "Şifre Tekrar"]),
    dry_run: body.dry_run === true || body.dryRun === true || String(body.dry_run || body.dryRun || "").toLowerCase() === "true"
  };
}

function validate(data) {
  if (!data.company_name) return ["COMPANY_NAME_REQUIRED", "Firmanızın Adı alanı zorunlu."];
  if (!data.email) return ["EMAIL_REQUIRED", "Mail alanı zorunlu."];
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.email)) return ["INVALID_EMAIL", "Mail adresi geçerli değil."];
  if (!data.password) return ["PASSWORD_REQUIRED", "Şifre alanı zorunlu."];
  if (!data.password_confirm) return ["PASSWORD_CONFIRM_REQUIRED", "Şifre Tekrar alanı zorunlu."];
  if (data.password !== data.password_confirm) return ["PASSWORD_MISMATCH", "Şifre ve Şifre Tekrar aynı değil."];
  return null;
}

function ensureStorage() {
  fs.mkdirSync(APP_DIR, { recursive: true });
  const probe = path.join(APP_DIR, ".write-test-" + Date.now());
  fs.writeFileSync(probe, "ok");
  fs.unlinkSync(probe);
}

async function handleSubmit(req, res) {
  let raw = "";
  let parsed = {};

  try {
    raw = await readBody(req);
    parsed = parseBody(req, raw);
  } catch (err) {
    return send(res, 400, {
      ok: false,
      error: "BAD_REQUEST",
      message: "Kayıt isteği okunamadı.",
      detail: err.message
    });
  }

  const data = normalize(parsed);
  const validation = validate(data);

  if (validation) {
    return send(res, 400, {
      ok: false,
      error: validation[0],
      message: validation[1]
    });
  }

  try {
    ensureStorage();
  } catch (err) {
    return send(res, 500, {
      ok: false,
      error: "STORAGE_NOT_WRITABLE",
      message: "Başvuru kayıt dizinine yazılamıyor.",
      detail: err.message,
      app_dir: APP_DIR
    });
  }

  const id = newApplicationId();
  const file = path.join(APP_DIR, id + ".json");

  const record = {
    marker: MARKER,
    id,
    application_id: id,
    basvuru_id: id,
    status: "PENDING",
    current_status: "PENDING",
    approval_status: "PENDING",
    login_enabled: false,
    active: false,

    company: data.company_name,
    company_name: data.company_name,
    companyName: data.company_name,
    firm_name: data.company_name,

    email: data.email.toLowerCase(),
    mail: data.email.toLowerCase(),
    contact_email: data.email.toLowerCase(),

    tax_number: data.tax_number,
    tax_office: data.tax_office,
    address: data.address,
    district: data.district,
    city: data.city,
    phone: data.phone,
    web_address: data.web_address,
    mersis_no: data.mersis_no,
    trade_registry_no: data.trade_registry_no,

    password_hash: sha256(data.password),
    password_algo: "sha256",
    temp_password_present: false,

    source: "panel_customer_register",
    created_at: nowIso(),
    updated_at: nowIso()
  };

  if (data.dry_run) {
    return send(res, 200, {
      ok: true,
      dry_run: true,
      would_save: true,
      id,
      message: "Başvuru doğrulaması başarılı. Dry-run olduğu için dosya yazılmadı."
    });
  }

  try {
    fs.writeFileSync(file + ".tmp", JSON.stringify(record, null, 2), { mode: 0o640 });
    fs.renameSync(file + ".tmp", file);
  } catch (err) {
    return send(res, 500, {
      ok: false,
      error: "APPLICATION_SAVE_FAILED",
      message: "Başvuru dosyası kaydedilemedi.",
      detail: err.message,
      file
    });
  }

  return send(res, 201, {
    ok: true,
    id,
    application_id: id,
    status: "PENDING",
    file,
    message: "Başvuru kaydedildi. Onay süreci için bekleyiniz."
  });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, "http://" + (req.headers.host || HOST + ":" + PORT));
  const p = url.pathname;

  if (req.method === "GET" && (p === "/health" || p === "/customer-register/api/health")) {
    try {
      ensureStorage();
      return send(res, 200, {
        ok: true,
        service: "customer-register-submit-api",
        host: HOST,
        port: PORT,
        app_dir: APP_DIR,
        storage_writable: true
      });
    } catch (err) {
      return send(res, 500, {
        ok: false,
        service: "customer-register-submit-api",
        host: HOST,
        port: PORT,
        app_dir: APP_DIR,
        storage_writable: false,
        error: err.message
      });
    }
  }

  if (
    req.method === "POST" &&
    (
      p === "/submit" ||
      p === "/customer-register/api/submit" ||
      p === "/api/customer-register/submit" ||
      p === "/register" ||
      p === "/application"
    )
  ) {
    return handleSubmit(req, res);
  }

  return send(res, 404, {
    ok: false,
    error: "NOT_FOUND",
    message: "Kayıt API route bulunamadı.",
    path: p
  });
});

server.on("error", (err) => {
  console.error("SERVER_ERROR", err && err.stack ? err.stack : err);
  process.exit(1);
});

server.listen(PORT, HOST, () => {
  console.log(`${MARKER} listening on ${HOST}:${PORT} app_dir=${APP_DIR}`);
});
