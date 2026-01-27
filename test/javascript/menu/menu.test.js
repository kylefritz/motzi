import { screen, within, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

import renderMenu from "./Menu.helpers";

const getCartTotalText = () => {
  const orderHeading = screen.getByText("Your order");
  const orderContainer = orderHeading.nextElementSibling;
  const priceEl = orderContainer.querySelector(".price");
  return priceEl ? priceEl.textContent : "";
};

test("menu for uid-user, before order", async () => {
  const { container } = renderMenu({ order: false });

  const itemCards = container.querySelectorAll(".col-6.mb-4");
  expect(itemCards).toHaveLength(3);
  expect(
    screen.getByRole("button", { name: "Submit Order" })
  ).toBeTruthy();

  // click pay it forward
  const donateBtn = screen.getByRole("button", { name: "Donate Now" });
  await userEvent.click(donateBtn);
  await waitFor(() => expect(getCartTotalText()).toContain("1 credit"));
});

test("payItForward", () => {
  renderMenu({ payItForward: false });
  expect(screen.queryByText("Pay it forward")).toBeNull();
});

test("menu for uid-user, add item to cart", async () => {
  const { container, onCreateOrder } = renderMenu({ order: false });
  expect(screen.getByText("No items")).toBeTruthy();

  const itemCards = container.querySelectorAll(".col-6.mb-4");
  const firstItem = itemCards[0];
  const dayButton = within(firstItem).getByRole("button", {
    name: /(mon|tues|wed|thu|fri|sat|sun)/i,
  });
  await userEvent.click(dayButton);

  const addToCartButton = within(firstItem).getByRole("button", {
    name: /add to cart/i,
  });
  await userEvent.click(addToCartButton);

  await waitFor(() => expect(getCartTotalText()).toContain("1 credit"));

  await userEvent.click(screen.getByRole("button", { name: "Submit Order" }));

  await waitFor(() => expect(onCreateOrder).toHaveBeenCalledTimes(1));

  const order = onCreateOrder.mock.calls[0][0];
  expect(order).toBeTruthy();
  const { uid, skip, cart } = order;
  console.log("submitted card", cart);

  expect(uid).toBe("Dot9gKn9w");
  expect(skip).toBeFalsy();
  expect(cart).toHaveLength(1);
  expect(cart[0]).toStrictEqual({
    itemId: 3,
    quantity: 1,
    pickupDayId: 1,
  });
});

test("menu for uid-user, after order", () => {
  const { container } = renderMenu();
  expect(getCartTotalText()).toContain("3 credits");
  expect(container.querySelectorAll(".col-6.mb-4")).toHaveLength(3);
  expect(
    screen.getByRole("button", { name: "Update Order" })
  ).toBeTruthy();
});

test("orderCredits", async () => {
  const { container } = renderMenu({ user: { credits: 1 } }); // 3 credits in order

  expect(getCartTotalText()).toContain("3 credits");
  await userEvent.click(screen.getByRole("button", { name: "Donate Now" }));
  await waitFor(() => expect(getCartTotalText()).toContain("4 credits")); // ok
  expect(
    screen.getByRole("button", { name: "Update Order" }).disabled
  ).toBe(false);

  const itemCards = container.querySelectorAll(".col-6.mb-4");
  const firstItem = itemCards[0];
  const dayButton = within(firstItem).getByRole("button", {
    name: /(mon|tues|wed|thu|fri|sat|sun)/i,
  });
  await userEvent.click(dayButton);
  const addToCartButton = within(firstItem).getByRole("button", {
    name: /add to cart/i,
  });
  await userEvent.click(addToCartButton);

  await waitFor(() => expect(getCartTotalText()).toContain("5 credits")); // too many
  const buyMore = screen.getByRole("button", { name: "Buy more credits :)" });
  expect(buyMore.disabled).toBe(true);
});

test("insufficientCredits, no order", async () => {
  const { container } = renderMenu({ user: { credits: 1 }, order: false });

  await userEvent.click(screen.getByRole("button", { name: "Donate Now" }));

  const itemCards = container.querySelectorAll(".col-6.mb-4");
  const firstItem = itemCards[0];
  const dayButton = within(firstItem).getByRole("button", {
    name: /(mon|tues|wed|thu|fri|sat|sun)/i,
  });
  await userEvent.click(dayButton);
  const addToCartButton = within(firstItem).getByRole("button", {
    name: /add to cart/i,
  });
  await userEvent.click(addToCartButton);

  await waitFor(() => expect(getCartTotalText()).toContain("2 credits"));
  const buyMore = screen.getByRole("button", { name: "Buy more credits :)" });
  expect(buyMore.disabled).toBe(true);
});

test("nag buy more credits", () => {
  const { unmount } = renderMenu({ user: { credits: 5 }, order: false });
  expect(screen.queryByText("Buy credits")).toBeNull();
  unmount();

  renderMenu({ user: { credits: 1 }, order: false });
  expect(screen.getByText("Buy credits")).toBeTruthy();
});

test("must buy more credits", () => {
  const { unmount } = renderMenu({ user: { credits: 0 }, order: false });
  expect(screen.getByText("Buy credits")).toBeTruthy();
  expect(screen.queryByRole("button", { name: "Submit Order" })).toBeNull();
  unmount();

  renderMenu({ user: { credits: 5 }, order: false });
  expect(screen.queryByText("Buy credits")).toBeNull();
  expect(screen.getByRole("button", { name: "Submit Order" })).toBeTruthy();
});

test("Menu pick skip", async () => {
  const { onCreateOrder } = renderMenu();

  expect(getCartTotalText()).toContain("3 credits");

  await userEvent.click(screen.getByRole("button", { name: "Skip Now" }));

  expect(screen.getByText("Skip this week")).toBeTruthy();

  await userEvent.click(screen.getByRole("button", { name: "Update Order" }));

  await waitFor(() => expect(onCreateOrder).toHaveBeenCalledTimes(1));

  const order = onCreateOrder.mock.calls[0][0];
  expect(order).toBeTruthy();
  const { uid, skip } = order;

  expect(uid).toBe("Dot9gKn9w");
  expect(skip).toBeTruthy();
});
