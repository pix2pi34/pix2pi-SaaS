import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  base: '/customer-register/react/',
  plugins: [react()]
})
