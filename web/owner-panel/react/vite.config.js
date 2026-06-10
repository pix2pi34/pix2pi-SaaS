import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  base: "/owner-panel/react/",
  plugins: [react()],
  build: {
    outDir: "dist",
    emptyOutDir: true
  }
});
