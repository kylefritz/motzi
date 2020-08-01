import React from "react";
require("../configure_enzyme");
import { mount } from "enzyme";

import Order from "menu/Order";
import { MenuContext } from "menu/Contexts";
import mockMenuJson from "./mockMenuJson";

test("Order snapshot", () => {
  const data = mockMenuJson();
  const wrapper = mount(
    <MenuContext.Provider value={data}>
      <Order {...data} />
    </MenuContext.Provider>
  );

  expect(wrapper.find("DaysCart").length).toBe(1);
  expect(wrapper.find("DaysCart").text()).toContain("Classic");
  expect(wrapper.find("h3").text()).toContain("got your order");
});
