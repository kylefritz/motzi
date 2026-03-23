import { test } from "@playwright/test";

const emails = [
  { mailer: "confirmation_mailer", action: "order_email" },
  { mailer: "confirmation_mailer", action: "credit_email" },
  { mailer: "menu_mailer", action: "weekly_menu_email" },
  { mailer: "reminder_mailer", action: "day_of_email" },
  { mailer: "reminder_mailer", action: "havent_ordered_email" },
  { mailer: "anomaly_mailer", action: "anomaly_report" },
];

for (const { mailer, action } of emails) {
  test(`${mailer}/${action}`, async ({ page }) => {
    // Rails mailer previews wrap the email in an iframe — navigate to the
    // raw HTML part directly via the ?part query param
    const url = `/rails/mailers/${mailer}/${action}?part=text%2Fhtml`;
    await page.goto(url);
    await page.waitForLoadState("networkidle");

    await page.screenshot({
      path: `test/visual/screenshots/${mailer}--${action}.png`,
      fullPage: true,
    });
  });
}
