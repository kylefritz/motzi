import React from "react";
import { expect, mock, test } from "bun:test";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import MenuTabs from "menu/MenuTabs";
import { SettingsContext } from "menu/Contexts";
import mockMenuJson from "./mockMenuJson";

const emptyOrder = {
  id: 999,
  comments: null,
  items: [],
  stripeReceiptUrl: null,
  stripeChargeAmount: null,
};

function renderMenuTabs({
  holidayOrder = null,
  initialTab,
  regularMenu = true,
}: { holidayOrder?: any; initialTab?: string; regularMenu?: boolean } = {}) {
  const data = mockMenuJson({ order: false });
  const holidayData = mockMenuJson({ order: false });
  holidayData.menu.name = "Passover Pre-Order";

  return render(
    <SettingsContext.Provider
      value={{ showCredits: true, bundles: data.bundles }}
    >
      <MenuTabs
        bundles={data.bundles}
        handleCreateHolidayOrder={mock(() => Promise.resolve())}
        handleCreateRegularOrder={mock(() => Promise.resolve())}
        holidayMenu={holidayData.menu}
        holidayOrder={holidayOrder}
        isEditingOrder={false}
        regularMenu={regularMenu ? data.menu : null}
        regularOrder={null}
        setIsEditingOrder={mock(() => {})}
        user={data.user}
        initialTab={initialTab}
      />
    </SettingsContext.Provider>
  );
}

test("holiday badge is visible before placing order", () => {
  renderMenuTabs();
  expect(screen.getByText("Holiday")).toBeTruthy();
});

test("holiday badge stays visible after placing order", () => {
  renderMenuTabs({ holidayOrder: emptyOrder });
  expect(screen.getByText("Holiday")).toBeTruthy();
});

test("?tab=email opens Email Settings even when a holiday menu is open", async () => {
  const user = userEvent.setup();
  renderMenuTabs({ initialTab: "email" });
  expect(screen.getByText("Email Settings")).toBeTruthy();
  expect(screen.queryByRole("tablist")).toBeNull();

  // back returns to the menus
  await user.click(screen.getByText(/Back to menu/));
  expect(screen.getByRole("tablist")).toBeTruthy();
  expect(screen.queryByText("Email Settings")).toBeNull();
});

test("?tab=email wins when the holiday menu is the only menu", () => {
  renderMenuTabs({ initialTab: "email", regularMenu: false });
  expect(screen.getByText("Email Settings")).toBeTruthy();
});

test("without ?tab=email the menus show as before", () => {
  renderMenuTabs();
  expect(screen.getByRole("tablist")).toBeTruthy();
  expect(screen.queryByText("Email Settings")).toBeNull();
});
