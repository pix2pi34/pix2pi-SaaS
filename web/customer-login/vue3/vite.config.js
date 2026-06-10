import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";

export default defineConfig({
  base: "/customer-login/vue3/",
  plugins: [vue()],
  build: {
    outDir: "dist",
    emptyOutDir: true
  }
});
