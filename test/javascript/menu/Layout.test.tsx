import React from "react";
import { afterEach, expect, mock, test } from "bun:test";
import { cleanup, render } from "@testing-library/react";

import Layout from "menu/Layout";
import { SettingsContext } from "menu/Contexts";
import mockMenuJson from "./mockMenuJson";

afterEach(cleanup);

// Layout renders a loading state before the menu arrives, then the real
// content. Hooks called after the loading-state early return change the
// hook order between those renders, which React reports via console.error.
test("keeps hook order stable when menu loads after the loading state", () => {
  window.gon = { stripeApiKey: "no-such-key" };

  const originalConsoleError = console.error;
  const errors: string[] = [];
  console.error = (...args: unknown[]) => {
    errors.push(args.map(String).join(" "));
  };

  try {
    const { menu } = mockMenuJson({ user: false, order: false });
    const props = {
      handleCreateOrder: mock(() => Promise.resolve()),
      isEditingOrder: false,
      order: null,
      setIsEditingOrder: mock(() => {}),
      user: null,
    };

    const { rerender } = render(
      <SettingsContext.Provider value={{}}>
        <Layout {...props} menu={null} />
      </SettingsContext.Provider>
    );

    rerender(
      <SettingsContext.Provider value={{}}>
        <Layout {...props} menu={menu} />
      </SettingsContext.Provider>
    );

    const hookOrderErrors = errors.filter((e) =>
      e.includes("change in the order of Hooks")
    );
    expect(hookOrderErrors).toEqual([]);
  } finally {
    console.error = originalConsoleError;
  }
});

// error_events #2773, #2784: a menu with no pickup days yet must still render
test("renders a menu that has no pickup days yet", () => {
  window.gon = { stripeApiKey: "no-such-key" };

  const { menu } = mockMenuJson({ user: false, order: false });
  const emptyMenu = {
    ...menu,
    pickupDays: [],
    items: menu.items.map((item) => ({ ...item, pickupDays: [] })),
  };

  const { container } = render(
    <SettingsContext.Provider value={{}}>
      <Layout
        handleCreateOrder={mock(() => Promise.resolve())}
        isEditingOrder={false}
        order={null}
        setIsEditingOrder={mock(() => {})}
        user={null}
        menu={emptyMenu}
      />
    </SettingsContext.Provider>
  );

  expect(container.textContent).toContain(menu.name);
});
