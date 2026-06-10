<script setup>
import { ref, onMounted } from 'vue';

const role = ref('misafir');

onMounted(() => {
  const params = new URLSearchParams(window.location.search);
  role.value = params.get('role') || 'misafir';
});

const logout = () => {
  window.location.href = '/customer-login/vue3/';
};
</script>

<template>
  <div v-if="role === 'kasiyer'" class="pos-screen">
    <header class="pos-header">
      <h2>PiX2Pi POS (Satış Ekranı) - Kasiyer Aktif [VUE3]</h2>
      <button class="danger-btn" @click="logout">Vardiya Bitir (Çıkış)</button>
    </header>
    <div class="pos-content">
      <div class="barcode-scanner">Barkod Okutunuz...</div>
      <div class="cart-total">Toplam: 0.00 TL</div>
    </div>
  </div>

  <div v-else class="dashboard">
    <aside class="sidebar">
      <div class="logo">PIX2PI PANEL VUE3</div>
      <nav>
        <ul>
          <li class="active">Gösterge Paneli</li>
          <li v-if="['holding_yonetim', 'bolge_yonetim', 'ilce_yonetim', 'sube_yonetim', 'patron'].includes(role)">Şubeler / İşletmeler</li>
          <li v-if="['holding_yonetim', 'muhasebe', 'patron'].includes(role)">Finans ve Muhasebe</li>
          <li>Stok ve Depo</li>
          <li>Personel Yönetimi</li>
        </ul>
      </nav>
    </aside>
    <main class="main-content">
      <header class="topbar">
        <div class="user-info">Aktif Rol: <strong>{{ role.toUpperCase() }}</strong></div>
        <button class="outline-btn" @click="logout">Güvenli Çıkış</button>
      </header>
      <div class="content-area">
        <h1>Sisteme Hoş Geldiniz</h1>
        <div class="widgets">
          <div class="widget">
            <h3>Günlük Ciro</h3>
            <p class="value">₺124,500</p>
          </div>
          <div class="widget">
            <h3>Aktif İşletmeler</h3>
            <p class="value">42</p>
          </div>
          <div class="widget">
            <h3>Sistem Durumu</h3>
            <p class="value success">Online</p>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>
