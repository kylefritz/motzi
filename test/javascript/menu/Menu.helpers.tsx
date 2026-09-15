import React from "react";
import { mock } from "bun:test";
import { render } from "@testing-library/react";

import Menu from "menu/Menu";
import mockMenuJson from "./mockMenuJson";
import { SettingsContext } from "menu/Contexts";

export default function renderMenu(mockMenuJsonOptions) {
  window.gon = { stripeApiKey: "no-such-key" };
  // Menu calls onCreateOrder(...).finally(...), so the mock must return a promise.
  const onCreateOrder = mock(() => Promise.resolve());
  const data = mockMenuJson(mockMenuJsonOptions);
  const { bundles } = data;
  const utils = render(
    <SettingsContext.Provider value={{ showCredits: true, bundles }}>
      <Menu {...data} onCreateOrder={onCreateOrder} />
    </SettingsContext.Provider>
  );

  return { ...utils, onCreateOrder, data };
}
