import React from "react";
import { expect, mock, test } from "bun:test";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import Subscription, { humanizeBreadsPerWeek } from "menu/Subscription";
import { SettingsContext } from "menu/Contexts";
import mockMenuJson from "./mockMenuJson";
import stripeMock from "./stripeMock";

const setStripeKey = () => {
  window.gon = { stripeApiKey: "no-such-key" };
};

test("buy credits", async () => {
  setStripeKey();
  window.Stripe = mock(() => stripeMock);

  const { user: subscriber, bundles } = mockMenuJson();

  const { container } = render(
    <SettingsContext.Provider value={{ bundles, enablePayWhatYouCan: true }}>
      <Subscription user={subscriber} />
    </SettingsContext.Provider>
  );

  const subscriberInfo = container.querySelectorAll(".subscriber-info");
  expect(subscriberInfo[0].textContent).toEqual(subscriber.name);
  expect(parseInt(subscriberInfo[1].textContent)).toEqual(subscriber.credits);

  await userEvent.click(screen.getByRole("button", { name: "Buy more" }));

  const choiceButtons = screen.getAllByRole("button", { name: /credits/ });
  expect(choiceButtons).toHaveLength(bundles.length);
  expect(choiceButtons[0].textContent).toEqual(
    "Weekly26 credits at $6.50 ea$169.00"
  );

  const headings = screen.getAllByRole("heading", { level: 6 });
  expect(headings).toHaveLength(2);
  expect(headings[0].textContent).toEqual("6-Month");

  await userEvent.click(choiceButtons[0]);

  expect(screen.getByText("Pay by credit card")).toBeTruthy();
  expect(screen.getByLabelText("Price")).toBeTruthy();
  expect(screen.getByTestId("card-element")).toBeTruthy();

  expect(
    screen.getByRole("button", {
      name: "Charge credit card $169.00 for 26 credits",
    })
  ).toBeTruthy();
});

test("no payWhatYouCan", async () => {
  setStripeKey();
  window.Stripe = mock(() => stripeMock);

  const { user: subscriber, bundles } = mockMenuJson();
  render(
    <SettingsContext.Provider value={{ bundles, enablePayWhatYouCan: false }}>
      <Subscription user={subscriber} />
    </SettingsContext.Provider>
  );

  await userEvent.click(screen.getByRole("button", { name: "Buy more" }));

  const choiceButtons = screen.getAllByRole("button", { name: /credits/ });
  await userEvent.click(choiceButtons[0]);

  expect(screen.getByText("Pay by credit card")).toBeTruthy();
  expect(screen.queryByLabelText("Price")).toBeNull();
  expect(screen.getByTestId("card-element")).toBeTruthy();
});

test("humanizeBreadsPerWeek", () => {
  expect(humanizeBreadsPerWeek(0.5)).toEqual("Every other week");
  expect(humanizeBreadsPerWeek(1.0)).toEqual("Every week");
  expect(humanizeBreadsPerWeek(2.0)).toEqual("Two breads per week");
  expect(humanizeBreadsPerWeek(3.0)).toEqual("Three breads per week");
  expect(humanizeBreadsPerWeek(5.3)).toEqual("5.3 breads per week");
});
