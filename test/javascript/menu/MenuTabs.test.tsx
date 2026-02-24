import React from "react";
import { expect, mock, test } from "bun:test";
import { render, screen } from "@testing-library/react";

import MenuTabs from "menu/MenuTabs";
import { SettingsContext } from "menu/Contexts";
import mockMenuJson from "./mockMenuJson";

const emptyOrder = {
  id: 999,
  skip: false,
  comments: null,
  items: [],
  stripeReceiptUrl: null,
  stripeChargeAmount: null,
};

function renderMenuTabs({
  holidayOrder = null,
}: { holidayOrder?: any } = {}) {
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
        regularMenu={data.menu}
        regularOrder={null}
        setIsEditingOrder={mock(() => {})}
        user={data.user}
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
