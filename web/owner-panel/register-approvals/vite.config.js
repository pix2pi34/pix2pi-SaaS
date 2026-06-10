import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  base: "/owner-panel/register-approvals/",
  plugins: [react()],
  build: {
    outDir: "dist",
    emptyOutDir: true
  }
});
