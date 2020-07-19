require("../configure_enzyme");
import { act } from "react-dom/test-utils";

import orderData from "./order-data";
import { renderMenu } from "./market_place_helpers";

test("marketplace render menu", () => {
  const menu = renderMenu({ menu: orderData.menu });

  expect(menu.items().length).toBe(4);
  expect(menu.submitOrderBtn().text()).toBe("Select an item");
});

test("marketplace, add item to cart", () => {
  const menu = renderMenu({ menu: orderData.menu, user: orderData.user });
  expect(menu.cart().text()).toContain("No items");

  // click "thurs"
  const thurs = menu.items().at(0).find("button").at(0);
  thurs.simulate("click");

  // click "add to cart"
  const addToCart = menu.items().at(0).find("button").at(2);
  addToCart.simulate("click");

  expect(menu.cartTotal()).toContain("$3.00");

  // fill out customer info
  menu.fillUser("k@k.com", "k", "f");

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
  const { cart } = order;
  console.log("submitted card", cart);

  // uid is assigned and skip is true
  expect(cart.length).toBe(1);
  expect(cart[0]).toStrictEqual({
    itemId: 3,
    price: 3,
    quantity: 1,
    day: "Thursday",
  });
});
