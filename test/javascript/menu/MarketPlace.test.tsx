import { expect, mock, test } from "bun:test";
import { act, fireEvent, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import renderMenu from "./MarketPlace.helpers";
import stripeMock from "./stripeMock";

const getCartTotalText = () => {
  const orderHeading = screen.getByText("Your order");
  const orderContainer = orderHeading.nextElementSibling;
  const priceEl = orderContainer?.querySelector(".price");
  return priceEl ? priceEl.textContent : "";
};

test("menu", async () => {
  const user = userEvent.setup();
  const { container } = renderMenu({ order: false, user: false });

  expect(container.querySelectorAll(".col-6.mb-4")).toHaveLength(4);
  expect(screen.getByRole("button", { name: "Select an item" })).toBeTruthy();

  const donateBtn = screen.getByRole("button", { name: "Donate Now" });
  await act(async () => {
    await user.click(donateBtn);
  });
  await waitFor(() => expect(getCartTotalText()).toContain("$5.00"));
});

test("noItems", () => {
  const { container } = renderMenu({ order: false, user: false, items: [] });
  expect(container.firstChild).toBeNull();
});

test("payWhatYouCan false", () => {
  const { unmount } = renderMenu({ enablePayWhatYouCan: true });
  expect(screen.getByLabelText("Price")).toBeTruthy();
  unmount();

  renderMenu({ enablePayWhatYouCan: false });
  expect(screen.queryByLabelText("Price")).toBeNull();
});

test("checkout", async () => {
  const user = userEvent.setup();
  const { onCreateOrder } = renderMenu({
    order: false,
    user: false,
  });
  expect(screen.getByText("No items")).toBeTruthy();

  await user.click(screen.getByTestId("pickup-day-3-1"));
  await user.click(screen.getByTestId("add-to-cart-3"));
  await waitFor(() => expect(getCartTotalText()).toContain("$3.00"));

  await user.type(screen.getByLabelText("First Name"), "kyle");
  await user.type(screen.getByLabelText("Last Name"), "fritz");
  await user.type(screen.getByLabelText("Email"), "kf@woo.com");
  await user.type(screen.getByLabelText("Phone"), "555-123-4567");

  const cardElement = screen.getByTestId("payment-element");
  await user.type(cardElement, "4242");

  const submitButton = screen.getByRole<HTMLButtonElement>("button", {
    name: "Charge credit card $3.00",
  });
  await waitFor(() => expect(submitButton.disabled).toBe(false));
  await act(async () => {
    await user.click(submitButton);
  });

  await waitFor(() => expect(onCreateOrder).toHaveBeenCalledTimes(1));
  await act(async () => {
    await onCreateOrder.mock.results[0].value;
  });

  const order = onCreateOrder.mock.calls[0][0];
  expect(order).toBeTruthy();
  const { email, firstName, lastName, phone, cart, price } = order;
  console.log("submitted order", order);

  expect(cart).toHaveLength(1);
  expect(cart[0]).toStrictEqual({
    itemId: 3,
    quantity: 1,
    pickupDayId: 1,
  });
  expect(email).toBe("kf@woo.com");
  expect(lastName).toBe("fritz");
  expect(firstName).toBe("kyle");
  expect(phone).toBe("555-123-4567");
  expect(price).toBe(3);
  expect(order.confirmationTokenId).toBe("ctoken_test");
});

test("0-price", async () => {
  const user = userEvent.setup();
  const { onCreateOrder } = renderMenu({
    order: false,
    user: false,
  });
  expect(screen.getByText("No items")).toBeTruthy();

  await user.click(screen.getByTestId("pickup-day-3-1"));
  await user.click(screen.getByTestId("add-to-cart-3"));
  await waitFor(() => expect(getCartTotalText()).toContain("$3.00"));

  await user.type(screen.getByLabelText("First Name"), "kyle");
  await user.type(screen.getByLabelText("Last Name"), "fritz");
  await user.type(screen.getByLabelText("Email"), "kf@woo.com");
  await user.type(screen.getByLabelText("Phone"), "555-123-4567");

  const payWhatYouCan = screen.getByLabelText("Price");
  fireEvent.change(payWhatYouCan, { target: { value: "0" } });
  fireEvent.blur(payWhatYouCan, { target: { value: "0" } });

  await act(async () => {
    await user.click(screen.getByRole("button", { name: "Submit Order" }));
  });

  await waitFor(() => expect(onCreateOrder).toHaveBeenCalledTimes(1));
  await act(async () => {
    await onCreateOrder.mock.results[0].value;
  });

  const order = onCreateOrder.mock.calls[0][0];
  expect(order.price).toBe(0);
  expect(order.confirmationTokenId).toBeUndefined();
  expect(stripeMock.createConfirmationToken).not.toHaveBeenCalled();
});

// Adds the $3 item and fills in the guest's details.
async function fillCart(user: ReturnType<typeof userEvent.setup>) {
  await user.click(screen.getByTestId("pickup-day-3-1"));
  await user.click(screen.getByTestId("add-to-cart-3"));
  await waitFor(() => expect(getCartTotalText()).toContain("$3.00"));

  await user.type(screen.getByLabelText("First Name"), "kyle");
  await user.type(screen.getByLabelText("Last Name"), "fritz");
  await user.type(screen.getByLabelText("Email"), "kf@woo.com");
  await user.type(screen.getByLabelText("Phone"), "555-123-4567");
}

test("a card needing 3D Secure is authenticated, then the order is posted with the payment intent", async () => {
  const user = userEvent.setup();
  const { onCreateOrder } = renderMenu({ order: false, user: false });
  onCreateOrder.mockImplementationOnce(() =>
    Promise.resolve({ requiresAction: true, clientSecret: "pi_secret" })
  );
  await fillCart(user);
  await user.type(screen.getByTestId("payment-element"), "4242");

  await act(async () => {
    await user.click(
      screen.getByRole("button", { name: "Charge credit card $3.00" })
    );
  });

  await waitFor(() => expect(onCreateOrder).toHaveBeenCalledTimes(2));
  expect(stripeMock.handleNextAction).toHaveBeenCalledWith({
    clientSecret: "pi_secret",
  });
  const [first, second] = onCreateOrder.mock.calls.map(([order]) => order);
  expect(first.confirmationTokenId).toBe("ctoken_test");
  expect(second.paymentIntentId).toBe("pi_test_3ds");
  expect(second.confirmationTokenId).toBeUndefined();
  expect(second.cart).toEqual(first.cart);
  expect(second.price).toBe(3);
});

test("Stripe.js errors are shown and nothing is posted", async () => {
  const user = userEvent.setup();
  const { onCreateOrder } = renderMenu({ order: false, user: false });
  stripeMock.createConfirmationToken.mockImplementation(() =>
    Promise.resolve({ error: { message: "Your card was declined." } })
  );
  await fillCart(user);
  await user.type(screen.getByTestId("payment-element"), "4000");

  await act(async () => {
    await user.click(
      screen.getByRole("button", { name: "Charge credit card $3.00" })
    );
  });

  await waitFor(() =>
    expect(screen.getByRole("alert").textContent).toBe(
      "Your card was declined."
    )
  );
  expect(onCreateOrder).not.toHaveBeenCalled();
});

test("Apple Pay / Google Pay pays through the Express Checkout Element", async () => {
  const user = userEvent.setup();
  const { onCreateOrder } = renderMenu({ order: false, user: false });

  // the wallet sheet doesn't open without an email
  const alertMock = mock(() => {});
  globalThis.alert = alertMock;
  await user.click(screen.getByTestId("pickup-day-3-1"));
  await user.click(screen.getByTestId("add-to-cart-3"));
  await act(async () => {
    await user.click(screen.getByTestId("express-checkout"));
  });
  expect(alertMock).toHaveBeenCalledWith("Enter email!");
  expect(stripeMock.createConfirmationToken).not.toHaveBeenCalled();

  await user.type(screen.getByLabelText("Email"), "kf@woo.com");
  await act(async () => {
    await user.click(screen.getByTestId("express-checkout"));
  });

  await waitFor(() => expect(onCreateOrder).toHaveBeenCalledTimes(1));
  expect(onCreateOrder.mock.calls[0][0].confirmationTokenId).toBe(
    "ctoken_test"
  );
});

test("below Stripe's 50 cent minimum the card can't be charged", async () => {
  const user = userEvent.setup();
  renderMenu({ order: false, user: false });
  await fillCart(user);

  const payWhatYouCan = screen.getByLabelText("Price");
  fireEvent.change(payWhatYouCan, { target: { value: "0.25" } });
  fireEvent.blur(payWhatYouCan, { target: { value: "0.25" } });

  const button = await screen.findByRole<HTMLButtonElement>("button", {
    name: "Card payments start at $0.50",
  });
  expect(button.disabled).toBe(true);
  expect(screen.queryByTestId("express-checkout")).toBeNull();
});
