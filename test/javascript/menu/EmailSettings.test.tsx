import React from "react";
import { expect, mock, test } from "bun:test";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import EmailSettings from "menu/EmailSettings";
import { SettingsContext } from "menu/Contexts";
import mockMenuJson from "./mockMenuJson";

function renderEmailSettings(userOverrides = {}) {
  const data = mockMenuJson();
  const user = { ...data.user, ...userOverrides };
  const onBack = mock(() => {});
  const onRefresh = mock(() => {});

  const utils = render(
    <SettingsContext.Provider value={{ onRefresh }}>
      <EmailSettings user={user} onBack={onBack} />
    </SettingsContext.Provider>
  );

  return { ...utils, onBack, onRefresh };
}

const getToggle = (name: string) =>
  screen.getByRole("switch", { name });

test("renders toggles matching user preferences", () => {
  renderEmailSettings({
    receiveWeeklyMenu: true,
    receiveHaventOrderedReminder: false,
    receiveDayOfReminder: true,
  });

  expect(getToggle("Weekly menu").getAttribute("aria-checked")).toBe("true");
  expect(getToggle("Order reminder").getAttribute("aria-checked")).toBe("false");
  expect(getToggle("Pickup reminder").getAttribute("aria-checked")).toBe("true");
});

test("toggling off weekly menu auto-clears and disables order reminder", async () => {
  renderEmailSettings();

  const weeklyMenu = getToggle("Weekly menu");
  const orderReminder = getToggle("Order reminder");

  await userEvent.click(weeklyMenu);
  expect(weeklyMenu.getAttribute("aria-checked")).toBe("false");
  expect(orderReminder.getAttribute("aria-checked")).toBe("false");
  expect(orderReminder.disabled).toBe(true);

  // toggling back on re-enables but doesn't re-check
  await userEvent.click(weeklyMenu);
  expect(orderReminder.getAttribute("aria-checked")).toBe("false");
  expect(orderReminder.disabled).toBe(false);
});

test("back link calls onBack", async () => {
  const { onBack } = renderEmailSettings();
  await userEvent.click(screen.getByText(/Back to menu/));
  expect(onBack).toHaveBeenCalledTimes(1);
});
