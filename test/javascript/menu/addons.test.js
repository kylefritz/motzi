require("../configure_enzyme");
import _ from "lodash";

import orderData from "./order-data";

import {
  renderMenu,
  clickItem,
  clickAddon,
  increaseAddon,
  submitForm,
} from "./helpers";

test("Menu pick item", () => {
  const onCreateOrder = renderMenu();

  clickItem("Baguette");
  clickAddon("Baguette");
  increaseAddon("Baguette");
  submitForm();

  expect(onCreateOrder).toHaveBeenCalledTimes(1);

  // order is the 0th arg of the 0th call
  const order = onCreateOrder.mock.calls[0][0];
  expect(order).toBeTruthy();
  const { uid, items } = order;

  expect(uid).toBe("Dot9gKn9w");
  expect(items).toHaveLength(3);

  const baguette = orderData.menu.items.filter((i) => i.name == "Baguette")[0];
  expect(items[0]).toBe(baguette.id);
});
