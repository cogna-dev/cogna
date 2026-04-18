import { defineConfig } from 'vite'

export default defineConfig({
  build: {
    lib: {
      entry: new URL('./src/index.ts', import.meta.url).pathname,
      formats: ['es'],
      fileName: 'index',
    },
    outDir: 'dist',
    sourcemap: true,
    emptyOutDir: false,
    rollupOptions: {
      output: {
        preserveModules: true,
        preserveModulesRoot: 'src',
        entryFileNames: (chunkInfo) => {
          if (chunkInfo.name === 'runtime/sdk') {
            return 'runtime/sdk.runtime.js'
          }
          return '[name].js'
        },
      },
    },
  },
})
