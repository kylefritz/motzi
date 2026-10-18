import React from "react";
import { expect, mock, test } from "bun:test";
import {
  act,
  render,
  screen,
  waitFor,
  fireEvent,
} from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import { SettingsContext } from "menu/Contexts";
import mockMenuJson from "../menu/mockMenuJson";
import stripeMock, { elementsMock, elementsOptions } from "../menu/stripeMock";
import type { CreditPurchaseRequest } from "../../../app/javascript/types/api";

const menuResponse = mockMenuJson();

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

const getMock = mock(() => Promise.resolve({ data: menuResponse }));
const receiptResponse = () =>
  Promise.resolve({
    data: { creditItem: { stripeReceiptUrl: "/receipt", id: 1 } } as unknown,
  });
const postMock = mock((_url: string, _data: CreditPurchaseRequest) =>
  receiptResponse()
);

mock.module("axios", () => ({
  default: {
    get: getMock,
    post: (url: string, data: CreditPurchaseRequest) => postMock(url, data),
  },
}));

// Picks the 6-credit bundle with a 10% tip and fills in the card.
async function chooseBundleAndFillCard() {
  const user = userEvent.setup();
  window.gon = { stripeApiKey: "test-key" };

  const subscriber = menuResponse.user!;
  const bundles = menuResponse.bundles;
  const onRefresh = mock(() => {});
  const { default: Buy } = await import("buy/App");

  render(
    <SettingsContext.Provider
      value={{ bundles, enablePayWhatYouCan: true, onRefresh }}
    >
      <Buy user={subscriber} />
    </SettingsContext.Provider>
  );

  await act(async () => {
    await user.click(screen.getByRole("button", { name: /\$46\.00/ }));
  });
  await act(async () => {
    await user.click(screen.getByRole("button", { name: "10%" }));
  });
  await act(async () => {
    fireEvent.change(screen.getByTestId("payment-element"), {
      target: { value: "4111" },
    });
  });

  const pay = async () => {
    await act(async () => {
      await user.click(
        screen.getByRole("button", { name: /Charge credit card/ })
      );
      await flushPromises();
    });
  };
  return { user, onRefresh, pay };
}

// Three levels up — test/javascript/buy → repo root. The previous 2-up path
// resolved to a nonexistent file, so this mock silently never intercepted.
mock.module("../../../app/javascript/lib/errorReporter", () => ({
  reportException: () => {},
  reportError: () => {},
  installGlobalErrorReporter: () => {},
}));

test("loads user and bundles from menu", async () => {
  window.history.pushState({}, "", "/buy?uid=test-uid");
  const { default: Buy } = await import("buy/App");

  render(
    <SettingsContext.Provider value={{}}>
      <Buy />
    </SettingsContext.Provider>
  );

  expect(
    screen.getByText("Loading user for subscription renewal...")
  ).toBeTruthy();

  await act(async () => {
    await flushPromises();
  });

  await waitFor(() => expect(screen.getByText("Buy credits")).toBeTruthy());

  expect(getMock).toHaveBeenCalledWith("/menu.json", {
    params: { uid: "test-uid" },
  });
  expect(
    screen.getAllByRole("button", { name: /Weekly/ }).length
  ).toBeGreaterThan(0);
});

test("submits credit purchase with tip and shows receipt", async () => {
  const user = userEvent.setup();
  window.gon = { stripeApiKey: "test-key" };

  const subscriber = menuResponse.user!;
  const bundles = menuResponse.bundles;
  const onRefresh = mock(() => {});
  const { default: Buy } = await import("buy/App");

  render(
    <SettingsContext.Provider
      value={{ bundles, enablePayWhatYouCan: true, onRefresh }}
    >
      <Buy user={subscriber} />
    </SettingsContext.Provider>
  );

  await act(async () => {
    await user.click(screen.getByRole("button", { name: /\$46\.00/ }));
  });
  await act(async () => {
    await user.click(screen.getByRole("button", { name: "10%" }));
  });

  await act(async () => {
    fireEvent.change(screen.getByTestId("payment-element"), {
      target: { value: "4111" },
    });
  });

  await act(async () => {
    await user.click(
      screen.getByRole("button", { name: /Charge credit card/ })
    );
    await flushPromises();
  });

  await waitFor(() => expect(postMock).toHaveBeenCalled());

  const payload = postMock.mock.calls[0][1];
  expect(payload.uid).toBe(subscriber.hashid);
  expect(payload.credits).toBe(6);
  expect(payload.breadsPerWeek).toBe(0.5);
  expect(payload.confirmationTokenId).toBe("ctoken_test");
  expect(payload.paymentIntentId).toBeUndefined();
  expect(payload.price).toBeCloseTo(50.6, 2);

  await waitFor(() =>
    expect(screen.getByText("Here's your receipt")).toBeTruthy()
  );
  expect(onRefresh).toHaveBeenCalled();
});

test("the card form is a deferred-intent Payment Element for the total", async () => {
  await chooseBundleAndFillCard();
  expect(elementsOptions.current).toEqual({
    mode: "payment",
    amount: 5060,
    currency: "usd",
    paymentMethodTypes: ["card"],
  });
  expect(screen.getByTestId("express-checkout")).toBeTruthy();
});

test("a card needing 3D Secure is authenticated, then the payment intent is posted", async () => {
  postMock.mockClear();
  postMock.mockImplementationOnce(() =>
    Promise.resolve({
      data: { requiresAction: true, clientSecret: "pi_test_3ds_secret" },
    })
  );
  const { pay, onRefresh } = await chooseBundleAndFillCard();
  await pay();

  await waitFor(() => expect(postMock).toHaveBeenCalledTimes(2));
  expect(stripeMock.handleNextAction).toHaveBeenCalledWith({
    clientSecret: "pi_test_3ds_secret",
  });
  const [first, second] = postMock.mock.calls.map(([, data]) => data);
  expect(first.confirmationTokenId).toBe("ctoken_test");
  expect(second.paymentIntentId).toBe("pi_test_3ds");
  expect(second.confirmationTokenId).toBeUndefined();
  expect(second.credits).toBe(6);

  await waitFor(() =>
    expect(screen.getByText("Here's your receipt")).toBeTruthy()
  );
  expect(onRefresh).toHaveBeenCalled();
});

test("a failed 3D Secure check shows Stripe's message and doesn't post again", async () => {
  postMock.mockClear();
  postMock.mockImplementationOnce(() =>
    Promise.resolve({
      data: { requiresAction: true, clientSecret: "pi_test_3ds_secret" },
    })
  );
  stripeMock.handleNextAction.mockImplementation(() =>
    Promise.resolve({
      error: { message: "We are unable to authenticate your payment method." },
    })
  );
  const { pay } = await chooseBundleAndFillCard();
  await pay();

  await waitFor(() =>
    expect(
      screen.getByText("We are unable to authenticate your payment method.")
    ).toBeTruthy()
  );
  expect(postMock).toHaveBeenCalledTimes(1);
});

test("card errors from Stripe.js are shown without posting", async () => {
  postMock.mockClear();
  elementsMock.submit.mockImplementation(() =>
    Promise.resolve({ error: { message: "Your card number is incomplete." } })
  );
  const { pay } = await chooseBundleAndFillCard();
  await pay();

  await waitFor(() =>
    expect(screen.getByText("Your card number is incomplete.")).toBeTruthy()
  );
  expect(stripeMock.createConfirmationToken).not.toHaveBeenCalled();
  expect(postMock).not.toHaveBeenCalled();
});
