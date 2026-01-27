import React from "react";
import { mock } from "bun:test";
import { render } from "@testing-library/react";

import Marketplace from "menu/Marketplace";
import mockMenuJson from "./mockMenuJson";
import stripeMock from "./stripeMock";
import { SettingsContext } from "menu/Contexts";

export default function renderMenu(menuJsonOptions) {
  window.gon = { stripeApiKey: "no-such-key" };
  window.Stripe = mock(() => stripeMock);

  stripeMock.createToken = mock(() =>
    Promise.resolve({
      token: {
        id: "test_id",
      },
    })
  );

  const onCreateOrder = mock(() => Promise.resolve());

  const utils = render(
    <SettingsContext.Provider value={{}}>
      <Marketplace
        {...mockMenuJson(menuJsonOptions)}
        onCreateOrder={onCreateOrder}
      />
    </SettingsContext.Provider>
  );

  return { ...utils, onCreateOrder };
}
