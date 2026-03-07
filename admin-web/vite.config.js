import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  // Chemins relatifs pour que le build fonctionne en prod (admin.dudugroup.sn)
  base: './',
  server: {
    port: 3001,
    open: true
  }
})

