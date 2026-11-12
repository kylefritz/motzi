import { test, expect } from "@playwright/test";
import Anthropic from "@anthropic-ai/sdk";
import { readFileSync } from "fs";
import { join } from "path";

const client = new Anthropic();
const prompt = readFileSync(join(__dirname, "email-check-prompt.txt"), "utf-8");

const emails = [
  { mailer: "confirmation_mailer", action: "order_email" },
  { mailer: "confirmation_mailer", action: "credit_email" },
  { mailer: "menu_mailer", action: "weekly_menu_email" },
  { mailer: "reminder_mailer", action: "day_of_email" },
  { mailer: "reminder_mailer", action: "havent_ordered_email" },
  { mailer: "anomaly_mailer", action: "anomaly_report" },
];

async function assertEmailLooksGood(
  screenshot: Buffer,
  page: any
): Promise<string> {
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

  const response = await client.messages.create({
    model: "claude-haiku-5-5",
    // Haiku 5.5 thinks before answering; thinking counts toward max_tokens.
    max_tokens: 2048,
    output_config: { effort: "low" },
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

  // The reply can open with a thinking block, so find the text by type.
  const result = response.content
    .map((block) => (block.type === "text" ? block.text : ""))
    .join("");
  return result.trim().toLowerCase();
}

for (const { mailer, action } of emails) {
  test(`${mailer}/${action}`, async ({ page }, testInfo) => {
    const url = `/rails/mailers/${mailer}/${action}?part=text%2Fhtml`;
    await page.goto(url);
    await page.waitForLoadState("networkidle");

    const screenshotPath = `test/visual/screenshots/${mailer}--${action}--${testInfo.project.name}.png`;
    const screenshot = await page.screenshot({
      path: screenshotPath,
      fullPage: true,
    });

    const result = await assertEmailLooksGood(screenshot, page);
    // The prompt asks for "pass" or "fail: <reason>". Match the verdict at the
    // start: toContain("pass") also accepted "fail: the Passover heading overlaps".
    expect(result, `Visual check failed for ${mailer}/${action}`).toMatch(
      /^pass\b/
    );
  });
}
