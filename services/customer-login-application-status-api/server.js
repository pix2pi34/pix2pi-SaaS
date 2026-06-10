const http = require("http");
const fs = require("fs");
const path = require("path");

const HOST = process.env.HOST || "127.0.0.1";
const PORT = Number(process.env.PORT || "9038");
const DATA_DIR = process.env.APPLICATIONS_DIR || "/root/pix2pi/pix2pi-SaaS/web/customer-register/data/applications";

const MARKER = "CUSTOMER_LOGIN_APPROVAL_STATUS_BRIDGE_MARKER";
const OWNER_MARKER = "OWNER_REGISTER_APPROVALS_ADMIN_MARKER";
const HANDOFF_MARKER = "REGISTER_APPROVAL_HANDOFF_MARKER";

function sendJson(res, status, payload) {
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    "X-Pix2pi-Customer-Login-Approval-Bridge": MARKER
  });
  res.end(body);
}

function normalizeEmail(email) {
  return String(email || "").trim().toLowerCase();
}

function pick(...values) {
  for (const value of values) {
    if (value !== undefined && value !== null && String(value).trim() !== "") {
      return value;
    }
  }
  return "";
}

function getStatus(app) {
  return String(
    app.status ||
    app.application_status ||
    app.registration_status ||
    "PENDING"
  ).trim().toUpperCase();
}

function getEmailCandidates(app) {
  const values = [
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
  ];

  return values
    .map(normalizeEmail)
    .filter(Boolean);
}

function getCreatedAt(app, stat) {
  const raw = pick(app.updated_at, app.updatedAt, app.approved_at, app.rejected_at, app.created_at, app.createdAt);
  const parsed = raw ? Date.parse(raw) : 0;
  if (!Number.isNaN(parsed) && parsed > 0) return parsed;
  return stat ? stat.mtimeMs : 0;
}

function safePublicResponse(email, code, status, message, extra = {}) {
  return {
    ok: true,
    marker: MARKER,
    owner_marker: OWNER_MARKER,
    handoff_marker: HANDOFF_MARKER,
    email,
    found: code !== "NOT_REGISTERED",
    code,
    status,
    login_allowed: false,
    tenant_created: false,
    tenant_create_real_create: false,
    message,
    ...extra
  };
}

function findApplicationByEmail(email) {
  fs.mkdirSync(DATA_DIR, { recursive: true });

  const target = normalizeEmail(email);
  if (!target || !target.includes("@")) {
    return null;
  }

  const matches = [];

  const files = fs
    .readdirSync(DATA_DIR)
    .filter((file) => file.endsWith(".json"))
    .filter((file) => !file.startsWith(".backup."));

  for (const file of files) {
    const fullPath = path.join(DATA_DIR, file);

    try {
      const stat = fs.statSync(fullPath);
      const app = JSON.parse(fs.readFileSync(fullPath, "utf8"));
      const emails = getEmailCandidates(app);

      if (!emails.includes(target)) continue;

      matches.push({
        file,
        status: getStatus(app),
        createdSort: getCreatedAt(app, stat),
        app
      });
    } catch {
      // Broken application file should not break customer login status.
    }
  }

  if (!matches.length) return null;

  const priority = {
    APPROVED: 100,
    PENDING: 80,
    REJECTED: 60
  };

  matches.sort((a, b) => {
    const pa = priority[a.status] || 0;
    const pb = priority[b.status] || 0;
    if (pa !== pb) return pb - pa;
    return b.createdSort - a.createdSort;
  });

  return matches[0];
}

function statusForEmail(email) {
  const normalized = normalizeEmail(email);
  const match = findApplicationByEmail(normalized);

  if (!match) {
    return safePublicResponse(
      normalized,
      "NOT_REGISTERED",
      "NOT_FOUND",
      "Bu e-posta için aktif müşteri hesabı veya kayıt başvurusu bulunamadı."
    );
  }

  if (match.status === "APPROVED") {
    return safePublicResponse(
      normalized,
      "APPROVED_ACTIVATION_PENDING",
      "APPROVED",
      "Başvurunuz Pix2pi tarafından onaylandı. Hesap/tenant aktivasyonu hazırlanıyor. Giriş henüz aktif değil.",
      {
        customer_login_message: "Başvurunuz onaylandı. Pix2pi aktivasyon/tenant açılışı tamamlanınca giriş açılacak.",
        next_step: "TENANT_CREATE_HANDOFF_PENDING"
      }
    );
  }

  if (match.status === "PENDING") {
    return safePublicResponse(
      normalized,
      "APPLICATION_PENDING",
      "PENDING",
      "Kayıt başvurunuz Pix2pi onayı bekliyor. Onay verilmeden giriş açılmaz.",
      {
        customer_login_message: "Başvurunuz alındı. Pix2pi onayı bekleniyor."
      }
    );
  }

  if (match.status === "REJECTED") {
    return safePublicResponse(
      normalized,
      "APPLICATION_REJECTED",
      "REJECTED",
      "Kayıt başvurunuz reddedilmiş görünüyor. Destek ile iletişime geçebilirsiniz.",
      {
        customer_login_message: "Başvurunuz reddedildi. Destek ile iletişime geçiniz."
      }
    );
  }

  return safePublicResponse(
    normalized,
    "APPLICATION_STATUS_UNKNOWN",
    match.status,
    "Kayıt başvurunuz bulundu fakat giriş henüz aktif değil.",
    {
      customer_login_message: "Başvurunuz bulundu. Pix2pi aktivasyon süreci bekleniyor."
    }
  );
}

const server = http.createServer((req, res) => {
  try {
    const parsed = new URL(req.url, `http://${req.headers.host || "127.0.0.1"}`);
    const pathname = parsed.pathname.replace(/\/+$/, "") || "/";

    if (req.method === "OPTIONS") {
      res.writeHead(204, {
        "Access-Control-Allow-Methods": "GET,OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
        "Cache-Control": "no-store"
      });
      return res.end();
    }

    if (req.method === "GET" && pathname === "/health") {
      return sendJson(res, 200, {
        ok: true,
        marker: MARKER,
        owner_marker: OWNER_MARKER,
        handoff_marker: HANDOFF_MARKER,
        status: "ok",
        data_dir: DATA_DIR,
        port: PORT
      });
    }

    if (req.method === "GET" && pathname === "/status") {
      const email = parsed.searchParams.get("email") || "";
      return sendJson(res, 200, statusForEmail(email));
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
  console.log(`${MARKER} listening on ${HOST}:${PORT}`);
});
