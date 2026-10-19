import { expect, mock, test } from "bun:test";
import { act, fireEvent, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import renderMenu from "./MarketPlace.helpers";
import { now } from "../support/clock";
import type { MenuItem } from "../../../app/javascript/types/api";

const pickupDays = () => [
  {
    id: 1,
    pickupAt: now().plus({ hours: 24 }).toISO()!,
    orderDeadlineAt: now().plus({ hours: 12 }).toISO()!,
    remaining: 100,
  },
];

const item = (overrides: Partial<MenuItem>): MenuItem => ({
  id: 1,
  name: "Classic",
  description: "",
  price: 8,
  credits: 1,
  image: null,
  subscriber: true,
  marketplace: true,
  payWhatYouCan: true,
  pickupDays: pickupDays(),
  ...overrides,
});

const mixedItems = () => [
  item({ id: 1, name: "Classic", price: 8 }),
  item({ id: 2, name: "Pizza", price: 30, payWhatYouCan: false }),
];

async function addToCart(
  user: ReturnType<typeof userEvent.setup>,
  itemId: number
) {
  await user.click(screen.getByTestId(`pickup-day-${itemId}-1`));
  await user.click(screen.getByTestId(`add-to-cart-${itemId}`));
}

test("item cards carry no pay what you can or fixed price badges", () => {
  renderMenu({ order: false, user: false, items: mixedItems() });

  const classic = screen.getByTestId("item-1");
  const pizza = screen.getByTestId("item-2");
  expect(classic.textContent).not.toContain("Pay what you can");
  expect(pizza.textContent).not.toContain("Fixed price");
});

test("an all pay-what-you-can cart shows no breakdown", async () => {
  const user = userEvent.setup();
  renderMenu({ order: false, user: false, items: mixedItems() });

  await addToCart(user, 1);
  await waitFor(() =>
    expect((screen.getByLabelText("Price") as HTMLInputElement).value).toBe("8")
  );
  expect(screen.queryByTestId("price-breakdown")).toBeNull();
});

test("mixed cart looks like any cart until the price dips under the fixed total", async () => {
  const user = userEvent.setup();
  const originalAlert = window.alert;
  const alertSpy = mock(() => {});
  window.alert = alertSpy;
  const { onCreateOrder } = renderMenu({
    order: false,
    user: false,
    items: mixedItems(),
  });

  await addToCart(user, 2);
  await addToCart(user, 1);

  // defaults to the suggested total, not $0
  const priceInput = screen.getByLabelText<HTMLInputElement>("Price");
  await waitFor(() => expect(priceInput.value).toBe("38"));

  // no breakdown or pricing labels: the cart looks like it did before #419
  expect(screen.queryByTestId("price-breakdown")).toBeNull();
  expect(screen.queryByText(/fixed price|fixed total/i)).toBeNull();
  expect(screen.queryByTestId("below-minimum")).toBeNull();

  // under the minimum: inline message and a disabled pay button
  fireEvent.change(priceInput, { target: { value: "20" } });
  fireEvent.blur(priceInput, { target: { value: "20" } });

  const message = await screen.findByTestId("below-minimum");
  expect(message.textContent).toContain("at least $30.00");
  const payButton = screen.getByRole<HTMLButtonElement>("button", {
    name: "Enter at least $30.00",
  });
  expect(payButton.disabled).toBe(true);

  // $0 doesn't sneak through as a free "Submit Order" either
  fireEvent.change(priceInput, { target: { value: "0" } });
  fireEvent.blur(priceInput, { target: { value: "0" } });
  expect(
    screen.getByRole<HTMLButtonElement>("button", {
      name: "Enter at least $30.00",
    }).disabled
  ).toBe(true);

  // the shortcut pays exactly the minimum and clears the message
  await act(async () => {
    await user.click(screen.getByRole("button", { name: "Change to $30.00" }));
  });
  await waitFor(() => expect(priceInput.value).toBe("30"));
  expect(screen.queryByTestId("below-minimum")).toBeNull();
  expect(
    screen.getByRole("button", { name: "Charge credit card $30.00" })
  ).toBeTruthy();

  expect(alertSpy).not.toHaveBeenCalled();
  window.alert = originalAlert;
  expect(onCreateOrder).not.toHaveBeenCalled();
});
