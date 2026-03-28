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

  return { ...utils, onBack, onRefresh, user };
}

const getToggle = (name: string) =>
  screen.getByRole("switch", { name });

test("renders all three toggles with correct initial state", () => {
  renderEmailSettings();

  expect(getToggle("Weekly menu").getAttribute("aria-checked")).toBe("true");
  expect(getToggle("Order reminder").getAttribute("aria-checked")).toBe("true");
  expect(getToggle("Pickup reminder").getAttribute("aria-checked")).toBe("true");
  expect(getToggle("Order reminder").disabled).toBe(false);
});

test("renders with preferences off", () => {
  renderEmailSettings({
    receiveWeeklyMenu: false,
    receiveHaventOrderedReminder: false,
    receiveDayOfReminder: false,
  });

  expect(getToggle("Weekly menu").getAttribute("aria-checked")).toBe("false");
  expect(getToggle("Order reminder").getAttribute("aria-checked")).toBe("false");
  expect(getToggle("Pickup reminder").getAttribute("aria-checked")).toBe("false");
});

test("toggling off weekly menu auto-clears and disables order reminder", async () => {
  renderEmailSettings();

  const weeklyMenu = getToggle("Weekly menu");
  const orderReminder = getToggle("Order reminder");

  expect(weeklyMenu.getAttribute("aria-checked")).toBe("true");
  expect(orderReminder.getAttribute("aria-checked")).toBe("true");
  expect(orderReminder.disabled).toBe(false);

  // Turn off weekly menu
  await userEvent.click(weeklyMenu);

  expect(weeklyMenu.getAttribute("aria-checked")).toBe("false");
  expect(orderReminder.getAttribute("aria-checked")).toBe("false");
  expect(orderReminder.disabled).toBe(true);
});

test("toggling weekly menu back on re-enables order reminder (but stays off)", async () => {
  renderEmailSettings();

  const weeklyMenu = getToggle("Weekly menu");
  const orderReminder = getToggle("Order reminder");

  // Turn off then back on
  await userEvent.click(weeklyMenu);
  await userEvent.click(weeklyMenu);

  expect(weeklyMenu.getAttribute("aria-checked")).toBe("true");
  expect(orderReminder.getAttribute("aria-checked")).toBe("false"); // was auto-cleared, stays off
  expect(orderReminder.disabled).toBe(false); // re-enabled
});

test("pickup reminder toggles independently", async () => {
  renderEmailSettings();

  const pickup = getToggle("Pickup reminder");
  expect(pickup.getAttribute("aria-checked")).toBe("true");

  await userEvent.click(pickup);
  expect(pickup.getAttribute("aria-checked")).toBe("false");

  await userEvent.click(pickup);
  expect(pickup.getAttribute("aria-checked")).toBe("true");
});

test("back link calls onBack", async () => {
  const { onBack } = renderEmailSettings();

  await userEvent.click(screen.getByText(/Back to menu/));
  expect(onBack).toHaveBeenCalledTimes(1);
});

test("save button shows correct states", () => {
  renderEmailSettings();

  const button = screen.getByRole("button", { name: "Save Preferences" });
  expect(button).toBeTruthy();
  expect(button.disabled).toBe(false);
});
