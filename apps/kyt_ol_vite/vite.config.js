import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  base: "./",
  build: {
    outDir: "../../pix2pi_www/Kyt_ol",
    emptyOutDir: false
  }
});
