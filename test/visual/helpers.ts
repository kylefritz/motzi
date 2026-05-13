import Anthropic from "@anthropic-ai/sdk";
import type { Page } from "@playwright/test";

// Anthropic SDK throws at construction without ANTHROPIC_API_KEY, so defer
// until we know the key exists. CI doesn't run these specs (per CLAUDE.md);
// this lets local `bunx playwright test` skip cleanly when the key is unset.
export const client = process.env.ANTHROPIC_API_KEY ? new Anthropic() : null;

// PNG full-page screenshots can exceed the Anthropic 8000px image limit.
// Detect via the PNG header (height is bytes 20-23) and fall back to a
// viewport-height crop of the top portion.
export async function cropIfTooTall(screenshot: Buffer, page: Page): Promise<Buffer> {
  try {
    const height = screenshot.readUInt32BE(20);
    if (height > 7900) {
      return await page.screenshot({ fullPage: false });
    }
  } catch {
    // Header read failed; use original
  }
  return screenshot;
}

export async function reviewScreenshot(imageBuffer: Buffer, prompt: string): Promise<string> {
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
  return response.content[0].type === "text" ? response.content[0].text : "";
}
