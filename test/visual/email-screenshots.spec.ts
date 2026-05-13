import { test, expect } from "@playwright/test";
import { readFileSync } from "fs";
import { join } from "path";
import { client, cropIfTooTall, reviewScreenshot } from "./helpers";

const prompt = readFileSync(join(__dirname, "email-check-prompt.txt"), "utf-8");

const emails = [
  { mailer: "confirmation_mailer", action: "order_email" },
  { mailer: "confirmation_mailer", action: "credit_email" },
  { mailer: "menu_mailer", action: "weekly_menu_email" },
  { mailer: "reminder_mailer", action: "day_of_email" },
  { mailer: "reminder_mailer", action: "havent_ordered_email" },
  { mailer: "anomaly_mailer", action: "anomaly_report" },
];

for (const { mailer, action } of emails) {
  test(`${mailer}/${action}`, async ({ page }, testInfo) => {
    test.skip(!client, "ANTHROPIC_API_KEY not set — skipping visual review");
    const url = `/rails/mailers/${mailer}/${action}?part=text%2Fhtml`;
    await page.goto(url);
    await page.waitForLoadState("networkidle");

    const screenshotPath = `test/visual/screenshots/${mailer}--${action}--${testInfo.project.name}.png`;
    const screenshot = await page.screenshot({
      path: screenshotPath,
      fullPage: true,
    });

    const cropped = await cropIfTooTall(screenshot, page);
    const result = (await reviewScreenshot(cropped, prompt)).trim().toLowerCase();
    expect(result, `Visual check failed for ${mailer}/${action}`).toContain("pass");
  });
}
