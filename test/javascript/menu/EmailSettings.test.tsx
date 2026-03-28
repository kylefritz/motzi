import React from "react";
import { expect, mock, test, beforeEach } from "bun:test";
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

test("renders all three checkboxes with correct initial state", () => {
  renderEmailSettings();

  const weeklyMenu = screen.getByLabelText("Weekly menu email");
  const haventOrdered = screen.getByLabelText(
    /Haven.t ordered.* reminder/
  );
  const dayOf = screen.getByLabelText("Day-of pickup reminder");

  expect(weeklyMenu.checked).toBe(true);
  expect(haventOrdered.checked).toBe(true);
  expect(dayOf.checked).toBe(true);
  expect(haventOrdered.disabled).toBe(false);
});

test("renders with preferences off", () => {
  renderEmailSettings({
    receiveWeeklyMenu: false,
    receiveHaventOrderedReminder: false,
    receiveDayOfReminder: false,
  });

  expect(screen.getByLabelText("Weekly menu email").checked).toBe(false);
  expect(screen.getByLabelText(/Haven.t ordered/).checked).toBe(false);
  expect(screen.getByLabelText("Day-of pickup reminder").checked).toBe(false);
});

test("toggling off weekly menu auto-clears and disables haven't ordered", async () => {
  renderEmailSettings();

  const weeklyMenu = screen.getByLabelText("Weekly menu email");
  const haventOrdered = screen.getByLabelText(/Haven.t ordered/);

  // Both start checked
  expect(weeklyMenu.checked).toBe(true);
  expect(haventOrdered.checked).toBe(true);
  expect(haventOrdered.disabled).toBe(false);

  // Turn off weekly menu
  await userEvent.click(weeklyMenu);

  expect(weeklyMenu.checked).toBe(false);
  expect(haventOrdered.checked).toBe(false);
  expect(haventOrdered.disabled).toBe(true);
  expect(
    screen.getByText("Only available when weekly menu email is on")
  ).toBeTruthy();
});

test("toggling weekly menu back on re-enables haven't ordered (but stays unchecked)", async () => {
  renderEmailSettings();

  const weeklyMenu = screen.getByLabelText("Weekly menu email");
  const haventOrdered = screen.getByLabelText(/Haven.t ordered/);

  // Turn off then back on
  await userEvent.click(weeklyMenu);
  await userEvent.click(weeklyMenu);

  expect(weeklyMenu.checked).toBe(true);
  expect(haventOrdered.checked).toBe(false); // was auto-cleared, stays off
  expect(haventOrdered.disabled).toBe(false); // re-enabled
});

test("day-of reminder toggles independently", async () => {
  renderEmailSettings();

  const dayOf = screen.getByLabelText("Day-of pickup reminder");
  expect(dayOf.checked).toBe(true);

  await userEvent.click(dayOf);
  expect(dayOf.checked).toBe(false);

  await userEvent.click(dayOf);
  expect(dayOf.checked).toBe(true);
});

test("back link calls onBack", async () => {
  const { onBack } = renderEmailSettings();

  await userEvent.click(screen.getByText(/Back to menu/));
  expect(onBack).toHaveBeenCalledTimes(1);
});

test("save button shows correct states", () => {
  renderEmailSettings();

  const button = screen.getByRole("button", { name: "Save" });
  expect(button).toBeTruthy();
  expect(button.disabled).toBe(false);
});
