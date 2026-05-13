import { test, expect } from "@playwright/test";
import Anthropic from "@anthropic-ai/sdk";
import { readFileSync } from "fs";
import { join } from "path";

const client = new Anthropic();
const prompt = readFileSync(join(__dirname, "marketing-check-prompt.txt"), "utf-8");

const pages = [
  { name: "home", path: "/" },
  { name: "about", path: "/about" },
  { name: "subscribe", path: "/subscribe" },
  { name: "contact", path: "/contact" },
];

async function assertPageLooksGood(screenshot: Buffer, page: any): Promise<string> {
  // If the full-page screenshot exceeds the 8000px API limit, take a
  // viewport-height crop instead (checks the top portion of the page).
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
  return result.trim();
}

for (const { name, path } of pages) {
  test(name, async ({ page }, testInfo) => {
    await page.goto(path);
    await page.waitForLoadState("networkidle");

    const screenshotPath = `test/visual/screenshots/marketing-${name}-${testInfo.project.name}.png`;
    const screenshot = await page.screenshot({
      path: screenshotPath,
      fullPage: true,
    });

    const result = await assertPageLooksGood(screenshot, page);
    expect(
      result.toLowerCase(),
      `Visual check failed for ${path} (${testInfo.project.name})\n${result}`,
    ).not.toContain("status: broken");
  });
}
