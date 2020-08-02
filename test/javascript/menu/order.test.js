import React from "react";
require("../configure_enzyme");
import { mount } from "enzyme";

import Order from "menu/Order";
import mockMenuJson from "./mockMenuJson";

test("Order snapshot", () => {
  const wrapper = mount(<Order {...mockMenuJson()} />);

  expect(wrapper.find("DaysCart")).toHaveLength(1);
  expect(wrapper.find("DaysCart").text()).toContain("Classic");
  expect(wrapper.find("h3").text()).toContain("got your order");
});
