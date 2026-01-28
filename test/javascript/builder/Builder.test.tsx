import React from "react";
import { expect, mock, test } from "bun:test";
import { render, screen, waitFor, fireEvent, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

const menuResponse = {
  id: 42,
  orderingDeadlineText: "Order by Tuesday",
  leadtimeHours: 27,
  recentMenus: [
    { id: 41, name: "week1", weekId: "24w01", pickupDaysLabel: "Wed, Fri" },
    { id: 40, name: "week0", weekId: "23w52", pickupDaysLabel: "Thu" },
  ],
  pickupDays: [
    {
      id: 1,
      pickupAt: "2024-01-10T10:00:00Z",
      orderDeadlineAt: "2024-01-09T10:00:00Z",
      deadlineText: "Wed 10am",
    },
    {
      id: 2,
      pickupAt: "2024-01-12T10:00:00Z",
      orderDeadlineAt: "2024-01-11T10:00:00Z",
      deadlineText: "Fri 10am",
    },
  ],
  items: [
    {
      menuItemId: 10,
      itemId: 100,
      name: "Sourdough",
      description: "Tangy loaf",
      price: 5,
      credits: 1,
      image: null,
      subscriber: true,
      marketplace: true,
      sortOrder: 1,
      pickupDays: [
        {
          id: 501,
          pickupAt: "2024-01-10T10:00:00Z",
          orderDeadlineAt: "2024-01-09T10:00:00Z",
          deadlineText: "Wed 10am",
          limit: 10,
        },
      ],
    },
    {
      menuItemId: 11,
      itemId: 101,
      name: "Baguette",
      description: "Classic",
      price: 4,
      credits: 1,
      image: null,
      subscriber: false,
      marketplace: true,
      sortOrder: null,
      pickupDays: [],
    },
  ],
};

const itemsResponse = {
  items: [
    { id: 100, name: "Sourdough", description: "Tangy loaf", imagePath: null },
    { id: 101, name: "Baguette", description: "Classic", imagePath: null },
    { id: 102, name: "Ciabatta", description: "Chewy", imagePath: null },
  ],
};

const getMock = mock((url) => {
  if (url === "/admin/items.json") {
    return Promise.resolve({ data: itemsResponse });
  }
  if (String(url).includes("menu_builder.json")) {
    return Promise.resolve({ data: menuResponse });
  }
  return Promise.reject(new Error(`Unexpected GET ${url}`));
});
const postMock = mock(() => Promise.resolve({ data: menuResponse }));
const patchMock = mock(() => Promise.resolve({ data: menuResponse }));
const deleteMock = mock(() => Promise.resolve({ data: menuResponse }));

mock.module("axios", () => ({
  default: {
    get: getMock,
    post: postMock,
    patch: patchMock,
    delete: deleteMock,
  },
}));

const captureException = mock(() => {});
mock.module("@sentry/browser", () => ({
  captureException,
}));

if (!window.matchMedia) {
  window.matchMedia = () => ({
    matches: false,
    media: "",
    addListener: () => {},
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => false,
  });
}

window.history.pushState({}, "", "/admin/menus/42");

test("edits menu items", async () => {
  const { default: MenuBuilder } = await import("builder/Builder");

  render(<MenuBuilder />);

  // Wait for the builder to load.
  await waitFor(() => expect(screen.getByText("Menu Items")).toBeTruthy());

  // Clear all menu items.
  const confirmSpy = mock(() => true);
  window.confirm = confirmSpy;
  await userEvent.click(screen.getByRole("button", { name: /Clear all/i }));
  expect(confirmSpy).toHaveBeenCalled();
  expect(postMock).toHaveBeenCalledWith("/admin/menus/42/remove_items.json");

  // Toggle marketplace on an item card.
  const sourdoughCard = screen
    .getByText("Sourdough")
    .closest(".MuiCard-root");
  if (!sourdoughCard) {
    throw new Error("Expected Sourdough card to be present");
  }
  const card = within(sourdoughCard);

  const marketplaceCheckbox = card.getByLabelText("Marketplace");
  await userEvent.click(marketplaceCheckbox);
  expect(patchMock).toHaveBeenCalledWith("/admin/menu_items/10.json", {
    marketplace: false,
  });

  // Update sort order.
  const sortOrderLabel = card.getByText("Sort Order").closest("label");
  const sortOrderInput = sortOrderLabel?.querySelector("input");
  if (!sortOrderInput) {
    throw new Error("Expected Sort Order input to be present");
  }
  fireEvent.change(sortOrderInput, {
    target: { value: "3", valueAsNumber: 3 },
  });
  expect(patchMock).toHaveBeenCalledWith("/admin/menu_items/10.json", {
    sortOrder: 3,
  });

  // Update per-pickup-day limit.
  const limitLabel = card.getByText("limit:").closest("label");
  const limitInput = limitLabel?.querySelector("input");
  if (!limitInput) {
    throw new Error("Expected limit input to be present");
  }
  fireEvent.change(limitInput, { target: { value: "12" } });
  await userEvent.click(card.getByRole("button", { name: "Save" }));
  expect(patchMock).toHaveBeenCalledWith(
    "/admin/menu_item_pickup_days/501.json",
    { limit: 12 }
  );

  // Remove an item from the menu.
  const removeButton = card.getByTitle("remove from menu");
  await userEvent.click(removeButton);
  expect(postMock).toHaveBeenCalledWith("/admin/menus/42/remove_item.json", {
    itemId: 100,
  });
});

test("adds pickup days and items", async () => {
  const { default: MenuBuilder } = await import("builder/Builder");

  render(<MenuBuilder />);

  // Wait for pickup days section to load.
  await waitFor(() => expect(screen.getByText("Pickup days")).toBeTruthy());

  // Add a pickup day.
  const pickupInput = screen.getByLabelText("Pickup at:");
  const deadlineInput = screen.getByLabelText("Order deadline at:");
  fireEvent.change(pickupInput, { target: { value: "2024-02-01T10:00" } });
  fireEvent.change(deadlineInput, { target: { value: "2024-01-31T10:00" } });

  await userEvent.click(
    screen.getByRole("button", { name: "Add pickup day" })
  );
  expect(postMock).toHaveBeenCalledWith("/admin/pickup_days.json", {
    pickupAt: "2024-02-01T10:00",
    orderDeadlineAt: "2024-01-31T10:00",
    menuId: "42",
  });

  // Remove a pickup day.
  const pickupRemoveButtons = screen.getAllByRole("button", { name: "x" });
  await userEvent.click(pickupRemoveButtons[0]);
  expect(deleteMock).toHaveBeenCalledWith("/admin/pickup_days/1.json");

  // Edit an existing pickup day.
  const firstPickupDay = screen.getByText("Wed 10am").closest("li");
  if (!firstPickupDay) {
    throw new Error("Expected first pickup day row to be present");
  }
  const pickupDayRow = within(firstPickupDay);
  await userEvent.click(pickupDayRow.getByRole("button", { name: "Edit" }));
  const editPickupInput = pickupDayRow.getByLabelText("Pickup at:");
  const editDeadlineInput = pickupDayRow.getByLabelText("Order deadline at:");
  fireEvent.change(editPickupInput, { target: { value: "2024-01-15T09:00" } });
  fireEvent.change(editDeadlineInput, { target: { value: "2024-01-14T09:00" } });
  await userEvent.click(pickupDayRow.getByRole("button", { name: "Save" }));
  expect(patchMock).toHaveBeenCalledWith("/admin/pickup_days/1.json", {
    pickupAt: "2024-01-15T09:00",
    orderDeadlineAt: "2024-01-14T09:00",
  });

  // Add a menu item.
  const addItemForm = screen
    .getByRole("button", { name: "Add Item" })
    .closest("form");
  if (!addItemForm) {
    throw new Error("Expected Add Item form to be present");
  }
  const select = within(addItemForm).getByRole("combobox");
  fireEvent.change(select, { target: { value: "102" } });

  await userEvent.click(screen.getByRole("button", { name: "Add Item" }));
  const addItemCall = postMock.mock.calls.find(
    ([url]) => url === "/admin/menus/42/item.json"
  );
  expect(addItemCall).toBeTruthy();
  expect(addItemCall?.[1]).toMatchObject({
    itemId: 102,
    subscriber: true,
    marketplace: true,
    pickupDayIds: [1, 2],
  });
});
