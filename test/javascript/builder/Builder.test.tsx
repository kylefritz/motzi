import React from "react";
import { beforeEach, expect, mock, test } from "bun:test";
import { render, screen, fireEvent, within } from "@testing-library/react";
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
  menuItems: [
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
const postMock = mock((..._args: unknown[]) =>
  Promise.resolve({ data: menuResponse })
);
const patchMock = mock((..._args: unknown[]) =>
  Promise.resolve({ data: menuResponse })
);
const deleteMock = mock((..._args: unknown[]) =>
  Promise.resolve({ data: menuResponse })
);

mock.module("axios", () => ({
  default: {
    get: getMock,
    post: postMock,
    patch: patchMock,
    delete: deleteMock,
  },
}));

mock.module("../../app/javascript/lib/errorReporter", () => ({
  reportException: () => {},
  reportError: () => {},
  installGlobalErrorReporter: () => {},
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

beforeEach(() => {
  // The axios mocks are module-level, so clear recorded calls between tests
  // to keep "not called" assertions independent of test order.
  getMock.mockClear();
  postMock.mockClear();
  patchMock.mockClear();
  deleteMock.mockClear();
  window.confirm = mock(() => true);
});

async function renderBuilder() {
  const { default: MenuBuilder } = await import("builder/Builder");
  render(<MenuBuilder />);
  // Builder shows "Loading" until both GETs resolve.
  await screen.findByRole("heading", { name: "Pickup days" });
}

function pickupDayCard(label: string) {
  const list = screen.getAllByRole("list")[0];
  const card = within(list).getByText(label).closest('[role="listitem"]');
  if (!(card instanceof HTMLElement)) {
    throw new Error(`Expected pickup day card "${label}" to be present`);
  }
  return within(card);
}

test("edits menu items", async () => {
  await renderBuilder();

  // Clear all menu items.
  const confirmSpy = mock(() => true);
  window.confirm = confirmSpy;
  await userEvent.click(screen.getByRole("button", { name: /Clear all/i }));
  expect(confirmSpy).toHaveBeenCalled();
  expect(postMock).toHaveBeenCalledWith("/admin/menus/42/remove_menu_items.json");

  // Toggle marketplace on an item card.
  const card = within(await screen.findByTestId("menu-item-card-100"));

  await userEvent.click(card.getByLabelText("Marketplace"));
  expect(patchMock).toHaveBeenCalledWith("/admin/menu_items/10.json", {
    marketplace: false,
  });

  // Update sort order.
  const sortOrderInput = card
    .getByText("Sort Order")
    .closest("label")
    ?.querySelector("input");
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
  const limitInput = card
    .getByText("limit:")
    .closest("label")
    ?.querySelector("input");
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
  await userEvent.click(card.getByTitle("remove from menu"));
  expect(postMock).toHaveBeenCalledWith("/admin/menus/42/remove_menu_item.json", {
    itemId: 100,
  });
});

test("adds a pickup day", async () => {
  await renderBuilder();

  fireEvent.change(screen.getByLabelText("Pickup at:"), {
    target: { value: "2024-02-01T10:00" },
  });
  fireEvent.change(screen.getByLabelText("Order deadline at:"), {
    target: { value: "2024-01-31T10:00" },
  });
  await userEvent.click(screen.getByRole("button", { name: "Add pickup day" }));

  expect(postMock).toHaveBeenCalledWith("/admin/pickup_days.json", {
    pickupAt: "2024-02-01T10:00",
    orderDeadlineAt: "2024-01-31T10:00",
    menuId: "42",
  });
});

test("removes a pickup day only after confirming", async () => {
  await renderBuilder();

  const removeButton = pickupDayCard("Wed, Jan 10 at 10a").getByRole("button", {
    name: "x",
  });

  const declineSpy = mock(() => false);
  window.confirm = declineSpy;
  await userEvent.click(removeButton);
  expect(declineSpy).toHaveBeenCalled();
  expect(deleteMock).not.toHaveBeenCalled();

  window.confirm = mock(() => true);
  await userEvent.click(removeButton);
  expect(deleteMock).toHaveBeenCalledWith("/admin/pickup_days/1.json");
});

test("edits an existing pickup day", async () => {
  await renderBuilder();

  const card = pickupDayCard("Wed, Jan 10 at 10a");
  await userEvent.click(card.getByRole("button", { name: "Edit" }));

  const editPickupInput = await card.findByLabelText("Pickup at:");
  const editDeadlineInput = card.getByLabelText("Order deadline at:");
  fireEvent.change(editPickupInput, { target: { value: "2024-01-15T09:00" } });
  fireEvent.change(editDeadlineInput, { target: { value: "2024-01-14T09:00" } });
  await userEvent.click(card.getByRole("button", { name: "Save" }));

  expect(patchMock).toHaveBeenCalledWith("/admin/pickup_days/1.json", {
    pickupAt: "2024-01-15T09:00",
    orderDeadlineAt: "2024-01-14T09:00",
  });
  // Saving closes the editor once the PATCH resolves.
  expect(await card.findByRole("button", { name: "Edit" })).toBeTruthy();
});

test("opens the pickup day editor right after a menu reload", async () => {
  // Regression for #376: a mount-time reset effect in EditablePickupDay could
  // flush after this Edit click (the reload renders outside act) and close the
  // editor again. It only lost the race occasionally, so this is a tripwire.
  await renderBuilder();

  const card = pickupDayCard("Wed, Jan 10 at 10a");
  await userEvent.click(card.getByRole("button", { name: "x" }));
  expect(deleteMock).toHaveBeenCalledWith("/admin/pickup_days/1.json");

  await userEvent.click(card.getByRole("button", { name: "Edit" }));
  expect(await card.findByLabelText("Pickup at:")).toBeTruthy();
});

test("adds a menu item", async () => {
  await renderBuilder();

  const addButton = screen.getByRole("button", { name: "Add Item" });
  const addItemForm = addButton.closest("form");
  if (!addItemForm) {
    throw new Error("Expected Add Item form to be present");
  }
  fireEvent.change(within(addItemForm).getByRole("combobox"), {
    target: { value: "102" },
  });
  await userEvent.click(addButton);

  expect(postMock).toHaveBeenCalledWith(
    "/admin/menus/42/menu_item.json",
    expect.objectContaining({
      itemId: 102,
      subscriber: true,
      marketplace: true,
      pickupDayIds: [1, 2],
    })
  );
});

test("copy from menu defaults are wired up", async () => {
  await renderBuilder();

  // Scope queries to the copy-from section to avoid picking up other inputs.
  const copySection = screen.getByText("Copy from menu").closest("section");
  if (!copySection) {
    throw new Error("Expected copy-from section to be present");
  }
  const copyForm = within(copySection);

  // The menu selector should exist and be required.
  expect(copyForm.getByRole("combobox", { name: "Menu:" })).toBeTruthy();

  // All note copy checkboxes should be present and default checked.
  for (const name of ["Subscriber", "Menu", "Day of"]) {
    const checkbox = copyForm.getByRole("checkbox", { name }) as HTMLInputElement;
    expect(checkbox.checked).toBe(true);
  }

  // The helper hint should be visible so the behavior is clear to admins.
  expect(
    copyForm.getByText(/Copying .* override an existing note/i)
  ).toBeTruthy();
});
