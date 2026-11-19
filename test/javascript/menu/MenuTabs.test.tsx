import React from "react";
import { afterEach, expect, mock, test } from "bun:test";
import { act, cleanup, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import MenuTabs, { hashOpensHoliday, menuSlug } from "menu/MenuTabs";
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

const selected = (name: RegExp) =>
  screen.getByRole("tab", { name }).getAttribute("aria-selected");

afterEach(() => {
  cleanup();
  window.history.replaceState({}, "", "/menu");
});

test("hashOpensHoliday matches #holiday and words of the menu name", () => {
  const name = "Thanksgiving Pre-Order 2026";
  expect(menuSlug(name)).toBe("thanksgiving-pre-order-2026");
  expect(hashOpensHoliday("#thanksgiving", name)).toBe(true);
  expect(hashOpensHoliday("#Thanksgiving-2026", name)).toBe(true);
  expect(hashOpensHoliday("#thanksgiving%20pre-order", name)).toBe(true);
  expect(hashOpensHoliday("#holiday", name)).toBe(true);
  expect(hashOpensHoliday("#passover", name)).toBe(false);
  expect(hashOpensHoliday("#thanks", name)).toBe(false);
  expect(hashOpensHoliday("", name)).toBe(false);
  expect(hashOpensHoliday("#%E0%A4%A", name)).toBe(false);
});

test("the regular menu opens first without a hash", () => {
  renderMenuTabs();
  expect(selected(/Passover/)).toBe("false");
});

test("/menu#passover deep-links to the holiday menu", () => {
  window.history.replaceState({}, "", "/menu?uid=abc#passover");
  renderMenuTabs();
  expect(selected(/Passover/)).toBe("true");
});

test("an unrelated hash leaves the regular menu open", () => {
  window.history.replaceState({}, "", "/menu#thanksgiving");
  renderMenuTabs();
  expect(selected(/Passover/)).toBe("false");
});

test("switching tabs keeps the hash (and the query) in step", async () => {
  const user = userEvent.setup();
  window.history.replaceState({}, "", "/menu?uid=abc");
  renderMenuTabs();

  await user.click(screen.getByRole("tab", { name: /Passover/ }));
  expect(selected(/Passover/)).toBe("true");
  expect(location.hash).toBe("#passover-pre-order");
  expect(location.search).toBe("?uid=abc");

  await user.click(screen.getAllByRole("tab")[0]);
  expect(selected(/Passover/)).toBe("false");
  expect(location.hash).toBe("");
  expect(location.search).toBe("?uid=abc");
});

test("a hash change while the page is open switches tabs", () => {
  renderMenuTabs();
  act(() => {
    window.location.hash = "#holiday";
    window.dispatchEvent(new window.Event("hashchange"));
  });
  expect(selected(/Passover/)).toBe("true");

  act(() => {
    window.history.replaceState({}, "", "/menu");
    window.dispatchEvent(new window.Event("hashchange"));
  });
  expect(selected(/Passover/)).toBe("false");
});

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
