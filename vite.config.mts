import react from "@vitejs/plugin-react";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vite";
import RubyPlugin from "vite-plugin-ruby";

const packs = (dir: string) =>
  fileURLToPath(new URL(`./app/javascript/packs/${dir}`, import.meta.url));

export default defineConfig({
  plugins: [react(), RubyPlugin()],
  resolve: {
    // Mirrors the `paths` in tsconfig.json.
    alias: {
      menu: packs("menu"),
      credits: packs("credits"),
      buy: packs("buy"),
      builder: packs("builder"),
    },
  },
  build: {
    sourcemap: true,
  },
});
