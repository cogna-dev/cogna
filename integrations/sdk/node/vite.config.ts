import { defineConfig } from 'vite'

export default defineConfig({
  build: {
    outDir: 'dist',
    sourcemap: true,
    emptyOutDir: false,
    rollupOptions: {
      preserveEntrySignatures: 'strict',
      input: new URL('./src/index.ts', import.meta.url).pathname,
      output: [
        {
          format: 'es',
          dir: 'dist',
          preserveModules: true,
          preserveModulesRoot: 'src',
          entryFileNames: (chunkInfo) => {
            if (chunkInfo.name === 'runtime/sdk') {
              return 'runtime/sdk.runtime.js'
            }
            return '[name].js'
          },
        },
        {
          format: 'cjs',
          dir: 'dist/cjs',
          exports: 'named',
          preserveModules: true,
          preserveModulesRoot: 'src',
          entryFileNames: (chunkInfo) => {
            if (chunkInfo.name === 'runtime/sdk') {
              return 'runtime/sdk.runtime.js'
            }
            return '[name].js'
          },
        },
      ],
    },
  },
})
