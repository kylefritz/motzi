import { expect, test } from "bun:test";
import { act, fireEvent, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import renderMenu from "./MarketPlace.helpers";

const getCartTotalText = () => {
  const orderHeading = screen.getByText("Your order");
  const orderContainer = orderHeading.nextElementSibling;
  const priceEl = orderContainer.querySelector(".price");
  return priceEl ? priceEl.textContent : "";
};

test("menu", async () => {
  const { container } = renderMenu({ order: false, user: false });

  expect(container.querySelectorAll(".col-6.mb-4")).toHaveLength(4);
  expect(screen.getByRole("button", { name: "Select an item" })).toBeTruthy();

  const donateBtn = screen.getByRole("button", { name: "Donate Now" });
  await act(async () => {
    await userEvent.click(donateBtn);
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
  const { onCreateOrder } = renderMenu({
    order: false,
    user: false,
  });
  expect(screen.getByText("No items")).toBeTruthy();

  await userEvent.click(screen.getByTestId("pickup-day-3-1"));
  await userEvent.click(screen.getByTestId("add-to-cart-3"));
  await waitFor(() => expect(getCartTotalText()).toContain("$3.00"));

  await userEvent.type(screen.getByLabelText("First Name"), "kyle");
  await userEvent.type(screen.getByLabelText("Last Name"), "fritz");
  await userEvent.type(screen.getByLabelText("Email"), "kf@woo.com");
  await userEvent.type(screen.getByLabelText("Phone"), "555-123-4567");

  const cardElement = screen.getByTestId("card-element");
  await userEvent.type(cardElement, "4242");

  const submitButton = screen.getByRole("button", {
    name: "Charge credit card $3.00",
  });
  await waitFor(() => expect(submitButton.disabled).toBe(false));
  await act(async () => {
    await userEvent.click(submitButton);
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
});

test("0-price", async () => {
  const { onCreateOrder } = renderMenu({
    order: false,
    user: false,
  });
  expect(screen.getByText("No items")).toBeTruthy();

  await userEvent.click(screen.getByTestId("pickup-day-3-1"));
  await userEvent.click(screen.getByTestId("add-to-cart-3"));
  await waitFor(() => expect(getCartTotalText()).toContain("$3.00"));

  await userEvent.type(screen.getByLabelText("First Name"), "kyle");
  await userEvent.type(screen.getByLabelText("Last Name"), "fritz");
  await userEvent.type(screen.getByLabelText("Email"), "kf@woo.com");
  await userEvent.type(screen.getByLabelText("Phone"), "555-123-4567");

  const payWhatYouCan = screen.getByLabelText("Price");
  fireEvent.change(payWhatYouCan, { target: { value: "0" } });
  fireEvent.blur(payWhatYouCan, { target: { value: "0" } });

  await act(async () => {
    await userEvent.click(screen.getByRole("button", { name: "Submit Order" }));
  });

  await waitFor(() => expect(onCreateOrder).toHaveBeenCalledTimes(1));
  await act(async () => {
    await onCreateOrder.mock.results[0].value;
  });

  const order = onCreateOrder.mock.calls[0][0];
  expect(order.price).toBe(0);
});
