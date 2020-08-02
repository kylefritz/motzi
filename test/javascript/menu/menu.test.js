require("../configure_enzyme");

import renderMenu from "./Menu.helpers";

test("menu for uid-user, before order", () => {
  const menu = renderMenu({ order: false });

  expect(menu.items()).toHaveLength(3);
  expect(menu.submitOrderBtn().text()).toBe("Submit Order");
  expect(menu.payItForward()).toHaveLength(1);
});

test("payItForward false", () => {
  const menu = renderMenu({ enablePayItForward: false });
  expect(menu.payItForward()).toHaveLength(0);
});

test("menu for uid-user, add item to cart", () => {
  const menu = renderMenu({ order: false });
  expect(menu.cart().text()).toContain("No items");

  // click "thurs"
  const thurs = menu.items().at(0).find("button").at(0);
  thurs.simulate("click");

  // click "add to cart"
  const addToCart = menu.items().at(0).find("button").at(2);
  addToCart.simulate("click");

  expect(menu.cartTotal()).toContain("1 credit");

  // click submit
  menu.submitOrder();

  // create order gets called
  expect(menu.onCreateOrder).toHaveBeenCalledTimes(1);

  // order is the 0th arg of the 0th call
  const order = menu.submittedOrder();
  expect(order).toBeTruthy();
  const { uid, skip, cart } = order;
  console.log("submitted card", cart);

  // uid is assigned and skip is true
  expect(uid).toBe("Dot9gKn9w");
  expect(skip).toBe(false);
  expect(cart).toHaveLength(1);
  expect(cart[0]).toStrictEqual({
    itemId: 3,
    price: 3,
    quantity: 1,
    day: "Thursday",
  });
});

test("menu for uid-user, after order", () => {
  const menu = renderMenu();
  expect(menu.cartTotal()).toContain("3 credits");
  expect(menu.items()).toHaveLength(3);
  expect(menu.submitOrderBtn().text()).toBe("Update Order");
});

test("Menu pick skip", () => {
  const menu = renderMenu();

  expect(menu.cartTotal()).toContain("3 credits");

  // click skip
  menu.skipBtn().simulate("click");

  // cart should go to $0
  expect(menu.cartTotal()).toContain("0 credits");

  // click submit
  menu.submitOrder();

  // create order gets called
  expect(menu.onCreateOrder).toHaveBeenCalledTimes(1);

  // order is the 0th arg of the 0th call
  const order = menu.submittedOrder();
  expect(order).toBeTruthy();
  const { uid, skip } = order;

  // uid is assigned and skip is true
  expect(uid).toBe("Dot9gKn9w");
  expect(skip).toBe(true);
});
