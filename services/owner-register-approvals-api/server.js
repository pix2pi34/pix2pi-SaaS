"use strict";

const http = require("http");
const fs = require("fs");
const path = require("path");

const MARKER = "OWNER_REGISTER_APPROVALS_ADMIN_MARKER";
const COMPANIES_MARKER = "PIX2PI_OWNER_APPROVALS_COMPANIES_MARKER";
const HOST = process.env.HOST || "127.0.0.1";
const PORT = Number(process.env.PORT || "9037");
const APP_DIR = process.env.PIX2PI_CUSTOMER_APPLICATION_DIR || "/root/pix2pi/pix2pi-SaaS/web/customer-register/data/applications";

function send(res, status, obj) {
  const body = JSON.stringify({ marker: MARKER, ...obj }, null, 2);
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    "X-Pix2pi-Marker": MARKER
  });
  res.end(body);
}

function safeReadJson(file) {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (err) {
    return null;
  }
}

function listApplications() {
  fs.mkdirSync(APP_DIR, { recursive: true });

  return fs.readdirSync(APP_DIR)
    .filter(name => /^CR-.*\.json$/.test(name))
    .sort()
    .map(name => {
      const file = path.join(APP_DIR, name);
      const data = safeReadJson(file) || {};
      const status = data.status || data.current_status || data.approval_status || "PENDING";

      return {
        id: data.id || data.application_id || name.replace(/\.json$/, ""),
        application_id: data.application_id || data.id || name.replace(/\.json$/, ""),
        file: name,
        company: data.company || data.company_name || data.companyName || data.firm_name || "-",
        email: data.email || data.mail || data.contact_email || "-",
        status,
        active: data.active === true || status === "APPROVED",
        login_enabled: data.login_enabled === true,
        created_at: data.created_at || null,
        updated_at: data.updated_at || null
      };
    });
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = "";
    req.on("data", chunk => {
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

function fileForId(id) {
  const clean = String(id || "").replace(/[^A-Za-z0-9_-]/g, "");
  if (!clean) return null;
  return path.join(APP_DIR, clean + ".json");
}

async function updateStatus(req, res) {
  let body = {};
  try {
    const raw = await readBody(req);
    body = raw ? JSON.parse(raw) : {};
  } catch {
    return send(res, 400, { ok: false, error: "INVALID_JSON" });
  }

  const id = body.id || body.application_id;
  const action = String(body.action || body.status || "").toUpperCase();

  if (!id) return send(res, 400, { ok: false, error: "ID_REQUIRED" });
  if (!["APPROVED", "REJECTED", "PENDING"].includes(action)) {
    return send(res, 400, { ok: false, error: "INVALID_STATUS" });
  }

  const file = fileForId(id);
  if (!file || !fs.existsSync(file)) {
    return send(res, 404, { ok: false, error: "APPLICATION_NOT_FOUND", id });
  }

  const data = safeReadJson(file) || {};
  data.status = action;
  data.current_status = action;
  data.approval_status = action;
  data.active = action === "APPROVED";
  data.login_enabled = action === "APPROVED";
  data.updated_at = new Date().toISOString();

  fs.writeFileSync(file + ".tmp", JSON.stringify(data, null, 2), { mode: 0o640 });
  fs.renameSync(file + ".tmp", file);

  return send(res, 200, {
    ok: true,
    id,
    status: action,
    file
  });
}

async function deleteApplication(req, res) {
  let body = {};
  try {
    const raw = await readBody(req);
    body = raw ? JSON.parse(raw) : {};
  } catch {
    return send(res, 400, { ok: false, error: "INVALID_JSON" });
  }

  const id = body.id || body.application_id;
  if (!id) return send(res, 400, { ok: false, error: "ID_REQUIRED" });

  const file = fileForId(id);
  if (!file || !fs.existsSync(file)) {
    return send(res, 404, { ok: false, error: "APPLICATION_NOT_FOUND", id });
  }

  fs.unlinkSync(file);

  return send(res, 200, {
    ok: true,
    deleted: true,
    id
  });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, "http://" + (req.headers.host || HOST + ":" + PORT));
  const p = url.pathname;

  if (req.method === "GET" && (p === "/health" || p === "/owner-panel/register-approvals/api/health")) {
    fs.mkdirSync(APP_DIR, { recursive: true });
    return send(res, 200, {
      ok: true,
      service: "owner-register-approvals-api",
      companies_marker: COMPANIES_MARKER,
      app_dir: APP_DIR,
      count: listApplications().length
    });
  }

  if (req.method === "GET" && (p === "/applications" || p === "/owner-panel/register-approvals/api/applications")) {
    const applications = listApplications();
    return send(res, 200, {
      ok: true,
      companies_marker: COMPANIES_MARKER,
      count: applications.length,
      applications
    });
  }

  if (req.method === "POST" && (p === "/status" || p === "/owner-panel/register-approvals/api/status")) {
    return updateStatus(req, res);
  }

  if (req.method === "POST" && (p === "/delete" || p === "/owner-panel/register-approvals/api/delete")) {
    return deleteApplication(req, res);
  }

  return send(res, 404, {
    ok: false,
    error: "NOT_FOUND",
    path: p
  });
});

server.on("error", err => {
  console.error("SERVER_ERROR", err && err.stack ? err.stack : err);
  process.exit(1);
});

server.listen(PORT, HOST, () => {
  console.log(`${MARKER} ${COMPANIES_MARKER} listening on ${HOST}:${PORT}`);
});
