<script setup>
import { ref } from "vue";

const email = ref("");
const password = ref("123");
const code = ref("");
const step = ref("password");
const loading = ref(false);
const message = ref({ type: "ok", text: "" });

async function postJSON(url, payload) {
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok || !data.ok) {
    throw new Error(data.message || "İşlem başarısız.");
  }

  return data;
}

async function requestCode() {
  loading.value = true;
  message.value = { type: "ok", text: "" };

  try {
    const data = await postJSON("/auth-api/request-login-code", {
      email: email.value,
      password: password.value,
      ui: "vue3"
    });

    step.value = "code";
    message.value = { type: "ok", text: data.message };
  } catch (error) {
    message.value = { type: "err", text: error.message };
  } finally {
    loading.value = false;
  }
}

async function verifyCode() {
  loading.value = true;
  message.value = { type: "ok", text: "" };

  try {
    const data = await postJSON("/auth-api/verify-login-code", {
      email: email.value,
      code: code.value,
      ui: "vue3"
    });

    message.value = { type: "ok", text: "Kod doğru. Panel açılıyor..." };
    setTimeout(() => { window.location.href = data.redirect || "/owner-panel/vue3/"; }, 500);
  } catch (error) {
    message.value = { type: "err", text: error.message };
  } finally {
    loading.value = false;
  }
}
</script>

<template>
  <main class="page">
    <section class="shell">
      <div class="brand">
        <div class="logo">PIX2PI</div>
        <h1>Müşteri Girişi</h1>
        <p>E-posta adresinizle giriş yapın veya işletme kaydı başlatın.</p>
      </div>

      <form v-if="step === 'password'" class="card" @submit.prevent="requestCode">
        <div class="step"><span>1</span> E-posta ve şifre</div>

        <label>
          E-posta
          <input v-model="email" type="email" autocomplete="email" placeholder="ornek@mail.com" />
        </label>

        <label>
          Şifre
          <input v-model="password" type="password" autocomplete="current-password" />
        </label>

        <div class="actions">
          <button class="primary" :disabled="loading">
            {{ loading ? "Kod gönderiliyor..." : "Mail Kodu Gönder" }}
          </button>

          <button class="secondary" type="button" @click="window.location.href = '/customer-register/vue3/'">
            Kayıt Ol
          </button>
        </div>

        <div v-if="message.text" :class="`message ${message.type}`">{{ message.text }}</div>
      </form>

      <form v-else class="card" @submit.prevent="verifyCode">
        <div class="step"><span>2</span> Mail kodu doğrulama</div>

        <label>
          Mail Kodu
          <input v-model="code" inputmode="numeric" placeholder="6 haneli kod" autofocus />
        </label>

        <button class="primary" :disabled="loading">
          {{ loading ? "Kontrol ediliyor..." : "Kodu Doğrula ve Giriş Yap" }}
        </button>

        <button type="button" class="link" @click="step = 'password'">E-postayı değiştir</button>

        <div v-if="message.text" :class="`message ${message.type}`">{{ message.text }}</div>
      </form>

      <div class="note">Test şifresi: 123 · Gönderen: no-reply@pix2pi.com.tr</div>
    </section>
  </main>
</template>
