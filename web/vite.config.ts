import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig(({ mode }) => ({
  // GitHub Pages serves this repository below /CMMS-Cable/.
  base: mode === 'github-pages' ? '/CMMS-Cable/' : '/',
  plugins: [vue()],
  build: {
    rolldownOptions: {
      output: {
        manualChunks(id) {
          const echartsPath = id.includes('/node_modules/echarts/') ? id.split('/node_modules/echarts/')[1] : id.split('\\node_modules\\echarts\\')[1]?.replaceAll('\\', '/')
          if (echartsPath?.startsWith('lib/chart/')) return 'echarts-charts'
          if (echartsPath?.startsWith('lib/component/')) return 'echarts-components'
          if (echartsPath?.startsWith('lib/')) return 'echarts-core'
          if (id.includes('/node_modules/zrender/') || id.includes('\\node_modules\\zrender\\')) return 'zrender'
        },
      },
    },
  },
}))
