import { defineConfig, devices } from "@playwright/test";

require("dotenv").config();

export default defineConfig({
  testDir: "./test/visual",
  outputDir: "./test/visual/screenshots",
  use: {
    baseURL: "http://localhost:3000",
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
