import React from "react";
import { mock } from "bun:test";
import { render } from "@testing-library/react";

import Marketplace from "menu/Marketplace";
import mockMenuJson, { type MockMenuOptions } from "./mockMenuJson";
import stripeMock, { type StripeTokenResult } from "./stripeMock";
import { SettingsContext } from "menu/Contexts";
import type { MarketplaceOrderRequest } from "../../../app/javascript/types/api";

export default function renderMenu(menuJsonOptions?: MockMenuOptions) {
  window.gon = { stripeApiKey: "no-such-key" };
  window.Stripe = mock(() => stripeMock);

  stripeMock.createToken = mock(
    (): Promise<StripeTokenResult> =>
      Promise.resolve({
        token: {
          id: "test_id",
        },
      })
  );

  const onCreateOrder = mock((_order: MarketplaceOrderRequest) =>
    Promise.resolve()
  );

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
