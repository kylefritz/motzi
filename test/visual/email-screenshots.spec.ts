import { test, expect } from "@playwright/test";
import Anthropic from "@anthropic-ai/sdk";
import { readFileSync } from "fs";
import { join } from "path";

// Anthropic SDK throws at construction without ANTHROPIC_API_KEY, so defer
// until we know the key exists. CI doesn't run these specs (per CLAUDE.md);
// this lets local `bunx playwright test` skip cleanly when the key is unset.
const client = process.env.ANTHROPIC_API_KEY ? new Anthropic() : null;
const prompt = readFileSync(join(__dirname, "email-check-prompt.txt"), "utf-8");

const emails = [
  { mailer: "confirmation_mailer", action: "order_email" },
  { mailer: "confirmation_mailer", action: "credit_email" },
  { mailer: "menu_mailer", action: "weekly_menu_email" },
  { mailer: "reminder_mailer", action: "day_of_email" },
  { mailer: "reminder_mailer", action: "havent_ordered_email" },
  { mailer: "anomaly_mailer", action: "anomaly_report" },
];

async function assertEmailLooksGood(screenshot: Buffer, page: any): Promise<string> {
  // If the full-page screenshot exceeds the 8000px API limit, take a
  // viewport-height crop instead (checks the top portion of the email).
  let imageBuffer = screenshot;
  try {
    // Quick size check via PNG header — height is at bytes 20-23
    const height = screenshot.readUInt32BE(20);
    if (height > 7900) {
      imageBuffer = await page.screenshot({ fullPage: false });
    }
  } catch {
    // If header read fails, use original
  }

  const response = await client!.messages.create({
    model: "claude-haiku-4-5",
    max_tokens: 256,
    messages: [
      {
        role: "user",
        content: [
          {
            type: "image",
            source: {
              type: "base64",
              media_type: "image/png",
              data: imageBuffer.toString("base64"),
            },
          },
          { type: "text", text: prompt },
        ],
      },
    ],
  });

  const result =
    response.content[0].type === "text" ? response.content[0].text : "";
  return result.trim().toLowerCase();
}

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

    const result = await assertEmailLooksGood(screenshot, page);
    expect(result, `Visual check failed for ${mailer}/${action}`).toContain(
      "pass",
    );
  });
}
