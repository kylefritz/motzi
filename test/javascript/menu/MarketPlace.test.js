require("../configure_enzyme");

import renderMenu from "./MarketPlace.helpers";

test("menu", () => {
  const menu = renderMenu({ order: false, user: false });

  expect(menu.items()).toHaveLength(4);
  expect(menu.submitOrderBtn()).toHaveLength(1);
  expect(menu.submitOrderBtn().text()).toBe("Select an item");

  expect(menu.payItForward()).toHaveLength(1);
  menu.payItForward().find("button").at(0).simulate("click");
  expect(menu.cartTotal()).toContain("$5.00");
});

test("noItems", () => {
  const menu = renderMenu({ order: false, user: false, items: [] });
  expect(menu.submitOrderBtn()).toHaveLength(0);
});

test("payWhatYouCan false", () => {
  const menuWith = renderMenu({ enablePayWhatYouCan: true });
  expect(menuWith.find("PayWhatYouCan")).toHaveLength(1);

  const withOut = renderMenu({ enablePayWhatYouCan: false });
  expect(withOut.find("PayWhatYouCan")).toHaveLength(0);
});

test("checkout", () => {
  const menu = renderMenu({ order: false, user: false });
  expect(menu.cart().text()).toContain("No items");

  menu.addItemToCart();
  expect(menu.cartTotal()).toContain("$3.00");

  // fill out customer info
  menu.fillUser("kyle", "fritz", "kf@woo.com", "555-123-4567");

  // "fill" card by invoking onChange: https://enzymejs.github.io/enzyme/#reacttestutilsact-wrap
  menu.find("CardElement").invoke("onChange")({ complete: true });

  // click submit
  menu.submitOrder();

  // simulate getting response back from stripe
  menu
    .find("Payment")
    .props()
    .onToken({
      token: {
        id: "test_id",
      },
    });

  // create order gets called
  expect(menu.onCreateOrder).toHaveBeenCalledTimes(1);

  // order is the 0th arg of the 0th call
  const order = menu.submittedOrder();
  expect(order).toBeTruthy();
  const { email, firstName, lastName, phone, cart, price } = order;
  console.log("submitted order", order);

  // uid is assigned and skip is true
  expect(cart).toHaveLength(1);
  expect(cart[0]).toStrictEqual({
    itemId: 3,
    quantity: 1,
    day: "Thursday",
  });
  expect(email).toBe("kf@woo.com");
  expect(lastName).toBe("fritz");
  expect(firstName).toBe("kyle");
  expect(phone).toBe("555-123-4567");
  expect(price).toBe(3);
});

test("0-price", () => {
  const menu = renderMenu({ order: false, user: false });
  expect(menu.cart().text()).toContain("No items");

  menu.addItemToCart();
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
  const { price } = order;
  expect(price).toBe(0);
});
