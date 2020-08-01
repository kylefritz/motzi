import React from "react";
require("../configure_enzyme");
import { mount } from "enzyme";

import Order from "menu/Order";
import mockMenuJson from "./mockMenuJson";

test("Order snapshot", () => {
  const data = mockMenuJson();
  const wrapper = mount(<Order {...data} />);

  expect(wrapper.find("DaysCart").length).toBe(1);
  expect(wrapper.find("DaysCart").text()).toContain("Classic");
  expect(wrapper.find("h3").text()).toContain("got your order");
});
