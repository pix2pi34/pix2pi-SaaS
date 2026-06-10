import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  base: "/customer-login/react/",
  plugins: [react()],
  build: {
    outDir: "dist",
    emptyOutDir: true
  }
});
