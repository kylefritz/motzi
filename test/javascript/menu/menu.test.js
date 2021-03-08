require("../configure_enzyme");

import renderMenu from "./Menu.helpers";

test("menu for uid-user, before order", () => {
  const menu = renderMenu({ order: false });

  expect(menu.items()).toHaveLength(3);
  expect(menu.submitOrderBtn().text()).toBe("Submit Order");

  // click pay it forward
  expect(menu.payItForward()).toHaveLength(1);
  menu.payItForward().find("button").at(0).simulate("click");
  expect(menu.cartTotal()).toContain("1 credit");
});

test("payItForward", () => {
  const menu = renderMenu({ payItForward: false });
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
  expect(skip).toBeFalsy();
  expect(cart).toHaveLength(1);
  expect(cart[0]).toStrictEqual({
    itemId: 3,
    quantity: 1,
    pickupDayId: 1,
  });
});

test("menu for uid-user, after order", () => {
  const menu = renderMenu();
  expect(menu.cartTotal()).toContain("3 credits");
  expect(menu.items()).toHaveLength(3);
  expect(menu.submitOrderBtn().text()).toBe("Update Order");
});

test("orderCredits", () => {
  const menu = renderMenu({ user: { credits: 1 } }); // 3 credits in order

  expect(menu.cartTotal()).toContain("3 credits");
  menu.payItForward().find("button").at(0).simulate("click");
  expect(menu.cartTotal()).toContain("4 credits"); // ok
  expect(menu.submitOrderBtn().prop("disabled")).toBeFalsy();

  // add item to cart
  menu.items().at(0).find("button").at(0).simulate("click");
  menu.items().at(0).find("button").at(2).simulate("click");

  expect(menu.cartTotal()).toContain("5 credits"); // too many
  expect(menu.submitOrderBtn().text()).toBe("Buy more credits :)");
  expect(menu.submitOrderBtn().prop("disabled")).toBeTruthy();
});

test("insufficientCredits, no order", () => {
  const menu = renderMenu({ user: { credits: 1 }, order: false });

  menu.payItForward().find("button").at(0).simulate("click");

  // add item to cart
  menu.items().at(0).find("button").at(0).simulate("click");
  menu.items().at(0).find("button").at(2).simulate("click");

  expect(menu.cartTotal()).toContain("2 credits");
  expect(menu.submitOrderBtn().prop("disabled")).toBeTruthy();
});

test("nag buy more credits", () => {
  const noNag = renderMenu({ user: { credits: 5 }, order: false });
  expect(noNag.find("Buy")).toHaveLength(0);

  const menu = renderMenu({ user: { credits: 1 }, order: false });
  expect(menu.find("Buy")).toHaveLength(1);
});

test("must buy more credits", () => {
  const must = renderMenu({ user: { credits: 0 }, order: false });
  expect(must.find("Buy")).toHaveLength(1);
  expect(must.find("SubmitButton")).toHaveLength(0);

  const regular = renderMenu({ user: { credits: 5 }, order: false });
  expect(regular.find("Buy")).toHaveLength(0);
  expect(regular.find("SubmitButton")).toHaveLength(1);
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
  expect(skip).toBeTruthy();
});
