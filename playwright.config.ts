import { defineConfig, devices } from "@playwright/test";

require("dotenv").config();

export default defineConfig({
  testDir: "./test/visual",
  outputDir: "./test/visual/screenshots",
  // In CI, retry once: a failure re-screenshots and re-asks Haiku, so a single
  // noisy judgment doesn't fail the monthly run (max 12 extra Haiku calls).
  retries: process.env.CI ? 1 : 0,
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL || "http://localhost:3000",
  },
  projects: [
    {
      name: "mobile",
      use: {
        ...devices["iPhone 14"],
        browserName: "chromium",
      },
    },
    {
      name: "desktop",
      use: {
        browserName: "chromium",
        viewport: { width: 1280, height: 800 },
      },
    },
  ],
});
