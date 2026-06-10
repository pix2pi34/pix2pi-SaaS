<template>
  <main class="page" data-marker="PIX2PI_REGISTER_VUE3_APP_VUE_PAGE_MARKER">
    <section class="hero">
      <p class="eyebrow">Pix2pi SaaS ERP</p>
      <h1>İşletme Kaydı Başlat</h1>
      <p class="lead">
        Bilgilerinizi girin. Başvuru <b>PENDING</b> durumunda alınır; tenant hemen açılmaz.
      </p>
    </section>

    <form class="card" @submit.prevent="submit">
      <div class="note">
        <b>Not:</b> Yıldızlı (*) alanların doldurulması zorunlu değildir.
      </div>

      <div class="grid">
        <label>Vergi No<input required v-model="form.vergiNo" /></label>
        <label>Vergi Dairesi<input required v-model="form.vergiDairesi" /></label>
        <label>Firmanızın Adı<input required v-model="form.firmaAdi" /></label>
        <label>Adres<input required v-model="form.adres" /></label>
        <label>İlçe<input required v-model="form.ilce" /></label>
        <label>İl<input required v-model="form.il" /></label>
        <label>* Tel No<input v-model="form.telNo" /></label>
        <label>* Web Adresi<input v-model="form.webAdresi" /></label>
        <label>MERSİS No<input required v-model="form.mersisNo" /></label>
        <label>* Ticaret Sicil No<input v-model="form.ticaretSicilNo" /></label>
        <label>Mail<input required type="email" v-model="form.mail" /></label>
        <label>Şifre<input required type="password" minlength="6" v-model="form.sifre" /></label>
        <label>Şifre Tekrar<input required type="password" minlength="6" v-model="form.sifreTekrar" /></label>
      </div>

      <button class="submit" type="submit">Başvuruyu Gönder</button>

      <div v-if="message" :class="isError ? 'error' : 'success'">
        {{ message }}
      </div>
    </form>
  </main>
</template>

<script setup>
import { reactive, ref } from 'vue'

const form = reactive({
  vergiNo: '',
  vergiDairesi: '',
  firmaAdi: '',
  adres: '',
  ilce: '',
  il: '',
  telNo: '',
  webAdresi: '',
  mersisNo: '',
  ticaretSicilNo: '',
  mail: '',
  sifre: '',
  sifreTekrar: ''
})

const message = ref('')
const isError = ref(false)

async function submit() {
  if (form.sifre.length < 6) {
    message.value = 'Hata: Şifre en az 6 karakter olmalı.'
    isError.value = true
    return
  }

  if (form.sifre !== form.sifreTekrar) {
    message.value = 'Hata: Şifre ve Şifre Tekrar aynı olmalı.'
    isError.value = true
    return
  }

  message.value = 'Başvuru alındı. Durum: PENDING. Tenant admin onayı olmadan açılmayacak.'
  isError.value = false

  try {
    await fetch('/api/customer-register/applications', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(form)
    })
  } catch (_) {}
}
</script>
