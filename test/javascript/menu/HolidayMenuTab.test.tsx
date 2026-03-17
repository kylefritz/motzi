import React from "react";
import { expect, mock, test } from "bun:test";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import HolidayMenuTab from "menu/HolidayMenuTab";
import { SettingsContext } from "menu/Contexts";
import mockMenuJson from "./mockMenuJson";

function renderHolidayMenuTab({
  order: withOrder = true,
  handleCreateOrder = mock(() => Promise.resolve()),
}: {
  order?: boolean;
  handleCreateOrder?: ReturnType<typeof mock>;
} = {}) {
  window.gon = { stripeApiKey: "no-such-key" };
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

test("shows menu form when no order exists", () => {
  renderHolidayMenuTab({ order: false });
  expect(screen.queryByText("We've got your order!")).toBeNull();
  expect(screen.getByRole("button", { name: "Submit Order" })).toBeTruthy();
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

  // Now the menu form should be showing instead of confirmation
  expect(screen.queryByText("We've got your order!")).toBeNull();
  expect(
    screen.getByRole("button", { name: "Update Order" })
  ).toBeTruthy();

  // Step 3: Submit the form
  await userEvent.click(
    screen.getByRole("button", { name: "Update Order" })
  );

  // Step 4: handleCreateOrder was called, and after it resolves,
  // isEditingOrder resets to false so confirmation reappears
  await waitFor(() => {
    expect(handleCreateOrder).toHaveBeenCalledTimes(1);
    expect(screen.getByText("We've got your order!")).toBeTruthy();
  });
});
