require("../configure_enzyme");

import renderMenu from "./MarketPlace.helpers";

test("marketplace render menu", () => {
  const menu = renderMenu({ order: false, user: false });

  expect(menu.items()).toHaveLength(4);
  expect(menu.submitOrderBtn().text()).toBe("Select an item");
});

test("payWhatYouCan false", () => {
  const menuWith = renderMenu({ enablePayWhatYouCan: true });
  expect(menuWith.find("PayWhatYouCan")).toHaveLength(1);

  const withOut = renderMenu({ enablePayWhatYouCan: false });
  expect(withOut.find("PayWhatYouCan")).toHaveLength(0);
});

test("marketplace, add item to cart", () => {
  const menu = renderMenu({ order: false, user: false });
  expect(menu.cart().text()).toContain("No items");

  // click "thurs"
  const thurs = menu.items().at(0).find("button").at(0);
  thurs.simulate("click");

  // click "add to cart"
  const addToCart = menu.items().at(0).find("button").at(2);
  addToCart.simulate("click");

  expect(menu.cartTotal()).toContain("$3.00");

  // fill out customer info
  menu.fillUser("kyle", "fritz", "kf@woo.com", "555-123-4567");

  // set payWhatYouCan to $0
  const payWhatYouCan = menu.wrapper.find("PayWhatYouCan").find("input");
  payWhatYouCan.simulate("change", { target: { value: "0" } });
  payWhatYouCan.simulate("blur", { target: { value: "0" } });

  // click submit
  menu.submitOrder();

  // create order gets called
  expect(menu.onCreateOrder).toHaveBeenCalledTimes(1);

  // order is the 0th arg of the 0th call
  const order = menu.submittedOrder();
  expect(order).toBeTruthy();
  const { email, firstName, lastName, phone, cart } = order;
  console.log("submitted order", order);

  // uid is assigned and skip is true
  expect(cart).toHaveLength(1);
  expect(cart[0]).toStrictEqual({
    itemId: 3,
    price: 3,
    quantity: 1,
    day: "Thursday",
  });
  expect(email).toBe("kf@woo.com");
  expect(lastName).toBe("fritz");
  expect(firstName).toBe("kyle");
  expect(phone).toBe("555-123-4567");
});
