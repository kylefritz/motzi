import React from "react";
import { afterEach, expect, mock, test } from "bun:test";
import { cleanup, render } from "@testing-library/react";

import Layout from "menu/Layout";
import { SettingsContext } from "menu/Contexts";
import mockMenuJson from "./mockMenuJson";
import stripeMock from "./stripeMock";

afterEach(cleanup);

// Layout renders a loading state before the menu arrives, then the real
// content. Hooks called after the loading-state early return change the
// hook order between those renders, which React reports via console.error.
test("keeps hook order stable when menu loads after the loading state", () => {
  window.gon = { stripeApiKey: "no-such-key" };
  window.Stripe = mock(() => stripeMock);

  const originalConsoleError = console.error;
  const errors: string[] = [];
  console.error = (...args: unknown[]) => {
    errors.push(args.map(String).join(" "));
  };

  try {
    const { menu, bundles } = mockMenuJson({ user: false, order: false });
    const props = {
      bundles,
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
  window.Stripe = mock(() => stripeMock);

  const { menu, bundles } = mockMenuJson({ user: false, order: false });
  const emptyMenu = {
    ...menu,
    pickupDays: [],
    items: menu.items.map((item) => ({ ...item, pickupDays: [] })),
  };

  const { container } = render(
    <SettingsContext.Provider value={{}}>
      <Layout
        bundles={bundles}
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
