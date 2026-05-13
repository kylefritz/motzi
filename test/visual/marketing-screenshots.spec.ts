import { test, expect } from "@playwright/test";
import { readFileSync } from "fs";
import { join } from "path";
import { client, cropIfTooTall, reviewScreenshot } from "./helpers";

const prompt = readFileSync(join(__dirname, "marketing-check-prompt.txt"), "utf-8");

const pages = [
  { name: "home", path: "/" },
  { name: "about", path: "/about" },
  { name: "subscribe", path: "/subscribe" },
  { name: "contact", path: "/contact" },
];

for (const { name, path } of pages) {
  test(name, async ({ page }, testInfo) => {
    test.skip(!client, "ANTHROPIC_API_KEY not set — skipping visual review");
    await page.goto(path);
    await page.waitForLoadState("networkidle");

    const screenshotPath = `test/visual/screenshots/marketing-${name}-${testInfo.project.name}.png`;
    const screenshot = await page.screenshot({
      path: screenshotPath,
      fullPage: true,
    });

    const cropped = await cropIfTooTall(screenshot, page);
    const result = (await reviewScreenshot(cropped, prompt)).trim();
    expect(
      result.toLowerCase(),
      `Visual check failed for ${path} (${testInfo.project.name})\n${result}`,
    ).not.toContain("status: broken");
  });
}
