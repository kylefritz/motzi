import React from "react";
import { expect, mock, test } from "bun:test";
import { act, render, screen, waitFor, fireEvent } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import { SettingsContext } from "menu/Contexts";
import mockMenuJson from "../menu/mockMenuJson";

const menuResponse = mockMenuJson();

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

const getMock = mock(() => Promise.resolve({ data: menuResponse }));
const postMock = mock(() =>
  Promise.resolve({
    data: { creditItem: { stripeReceiptUrl: "/receipt", id: 1 } },
  })
);

mock.module("axios", () => ({
  default: {
    get: getMock,
    post: postMock,
  },
}));

const setUser = mock(() => {});
const configureScope = mock((cb) => cb({ setUser }));
const captureException = mock(() => {});
mock.module("@sentry/browser", () => ({
  configureScope,
  captureException,
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
  window.gon = { stripeApiKey: "test-key" };

  const user = menuResponse.user!;
  const bundles = menuResponse.bundles;
  const onRefresh = mock(() => {});
  const { default: Buy } = await import("buy/App");

  render(
    <SettingsContext.Provider
      value={{ bundles, enablePayWhatYouCan: true, onRefresh }}
    >
      <Buy user={user} />
    </SettingsContext.Provider>
  );

  await act(async () => {
    await userEvent.click(screen.getByRole("button", { name: /\$46\.00/ }));
  });
  await act(async () => {
    await userEvent.click(screen.getByRole("button", { name: "10%" }));
  });

  await act(async () => {
    fireEvent.change(screen.getByTestId("card-element"), {
      target: { value: "4111" },
    });
  });

  await act(async () => {
    await userEvent.click(
      screen.getByRole("button", { name: /Charge credit card/ })
    );
    await flushPromises();
  });

  await waitFor(() => expect(postMock).toHaveBeenCalled());

  const payload = postMock.mock.calls[0][1];
  expect(payload.uid).toBe(user.hashid);
  expect(payload.credits).toBe(6);
  expect(payload.breadsPerWeek).toBe(0.5);
  expect(payload.token).toBe("test_id");
  expect(payload.price).toBeCloseTo(50.6, 2);

  await waitFor(() =>
    expect(screen.getByText("Here's your receipt")).toBeTruthy()
  );
  expect(onRefresh).toHaveBeenCalled();
});
