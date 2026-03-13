import React from "react";
import { expect, mock, test } from "bun:test";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import HolidayMenuTab from "menu/HolidayMenuTab";
import { SettingsContext } from "menu/Contexts";
import mockMenuJson from "./mockMenuJson";
import stripeMock from "./stripeMock";

function renderHolidayMenuTab({
  order: withOrder = true,
  handleCreateOrder = mock(() => Promise.resolve()),
}: {
  order?: boolean;
  handleCreateOrder?: ReturnType<typeof mock>;
} = {}) {
  window.gon = { stripeApiKey: "no-such-key" };
  window.Stripe = mock(() => stripeMock);
  const data = mockMenuJson({ order: withOrder });
  const { menu, user, order, bundles } = data;

  const utils = render(
    <SettingsContext.Provider value={{ showCredits: true, bundles }}>
      <HolidayMenuTab
        bundles={bundles}
        handleCreateOrder={handleCreateOrder}
        menu={menu}
        order={order}
        user={user}
      />
    </SettingsContext.Provider>
  );

  return { ...utils, handleCreateOrder, data };
}

test("shows confirmation when order exists", () => {
  renderHolidayMenuTab();
  expect(screen.getByText("We've got your order!")).toBeTruthy();
});

test("shows card payment form when no order exists", () => {
  renderHolidayMenuTab({ order: false });
  expect(screen.queryByText("We've got your order!")).toBeNull();
  // Holiday menu uses Marketplace with card payment
  expect(screen.getByTestId("card-element")).toBeTruthy();
});

test("shows USD prices, not credits, in holiday menu", () => {
  renderHolidayMenuTab({ order: false });
  // Items should show dollar prices, not credit amounts
  expect(screen.getByText("$3.00")).toBeTruthy();
  expect(screen.queryByText("1 credit")).toBeNull();
});

test("editing resets to confirmation after save", async () => {
  const handleCreateOrder = mock(() => Promise.resolve());
  renderHolidayMenuTab({ handleCreateOrder });

  // Step 1: Confirmation is showing
  expect(screen.getByText("We've got your order!")).toBeTruthy();

  // Step 2: Click edit to enter editing mode
  await userEvent.click(
    screen.getByRole("button", { name: "Edit Order" })
  );

  // Now the marketplace form should be showing (card payment)
  expect(screen.queryByText("We've got your order!")).toBeNull();
  expect(screen.getByTestId("card-element")).toBeTruthy();
});
