import { defineConfig, devices } from "@playwright/test";

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
        // Use Chromium instead of WebKit — faster, already installed
        browserName: "chromium",
      },
    },
  ],
});
