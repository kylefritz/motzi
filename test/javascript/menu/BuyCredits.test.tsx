import React from "react";
import { expect, test } from "bun:test";
import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import Subscription from "menu/Subscription";
import { SettingsContext } from "menu/Contexts";
import { mockSubscriberMenuJson } from "./mockMenuJson";

const setStripeKey = () => {
  window.gon = { stripeApiKey: "no-such-key" };
};

test("buy credits", async () => {
  const user = userEvent.setup();
  setStripeKey();

  const { user: subscriber, bundles } = mockSubscriberMenuJson();

  const { container } = render(
    <SettingsContext.Provider
      value={{ bundles, enablePayWhatYouCan: true, showCredits: true }}
    >
      <Subscription user={subscriber} />
    </SettingsContext.Provider>
  );

  const subscriberInfo = container.querySelectorAll(".subscriber-info");
  expect(subscriberInfo[0].textContent).toEqual(subscriber.name);
  expect(parseInt(subscriberInfo[1].textContent)).toEqual(subscriber.credits);

  await act(async () => {
    await user.click(screen.getByRole("button", { name: "Buy more" }));
  });

  const choiceButtons = screen.getAllByRole("button", { name: /credits/ });
  expect(choiceButtons).toHaveLength(bundles.length);
  expect(choiceButtons[0].textContent).toEqual(
    "Weekly26 credits at $6.50 ea$169.00"
  );

  const headings = screen.getAllByRole("heading", { level: 6 });
  expect(headings).toHaveLength(2);
  expect(headings[0].textContent).toEqual("6-Month");

  await act(async () => {
    await user.click(choiceButtons[0]);
  });

  expect(screen.getByText("Pay by credit card")).toBeTruthy();
  expect(screen.getByLabelText("Price")).toBeTruthy();
  expect(screen.getByTestId("payment-element")).toBeTruthy();

  expect(
    screen.getByRole("button", {
      name: "Charge credit card $169.00 for 26 credits",
    })
  ).toBeTruthy();
});

test("no payWhatYouCan", async () => {
  const user = userEvent.setup();
  setStripeKey();

  const { user: subscriber, bundles } = mockSubscriberMenuJson();
  render(
    <SettingsContext.Provider
      value={{ bundles, enablePayWhatYouCan: false, showCredits: true }}
    >
      <Subscription user={subscriber} />
    </SettingsContext.Provider>
  );

  await act(async () => {
    await user.click(screen.getByRole("button", { name: "Buy more" }));
  });

  const choiceButtons = screen.getAllByRole("button", { name: /credits/ });
  await act(async () => {
    await user.click(choiceButtons[0]);
  });

  expect(screen.getByText("Pay by credit card")).toBeTruthy();
  expect(screen.queryByLabelText("Price")).toBeNull();
  expect(screen.getByTestId("payment-element")).toBeTruthy();
});
