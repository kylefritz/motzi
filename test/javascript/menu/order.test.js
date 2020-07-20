import React from "react";
require("../configure_enzyme");
import { mount } from "enzyme";

import { munge } from "menu/App";
import Order from "menu/Order";
import orderData from "./order-data";

test("Order snapshot", () => {
  const { user, order, menu } = orderData;
  const wrapper = mount(<Order {...{ user, order, menu: munge(menu) }} />);

  expect(wrapper.find("DaysCart").length).toBe(1);
  expect(wrapper.find("DaysCart").text()).toContain("Classic");
  expect(wrapper.find("h3").text()).toContain("got your order");
});
