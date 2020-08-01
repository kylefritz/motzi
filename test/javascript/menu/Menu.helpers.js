import React from "react";
import { mount } from "enzyme";

import { MenuContext } from "menu/Contexts";
import Menu from "menu/Menu";
import mockMenuJson from "./mockMenuJson";

export default function renderMenu(mockMenuJsonOptions) {
  const onCreateOrder = jest.fn();
  const onRefreshUser = jest.fn();
  const data = mockMenuJson(mockMenuJsonOptions);
  const wrapper = mount(
    <MenuContext.Provider value={{ ...data, onRefreshUser }}>
      <Menu {...data} onCreateOrder={onCreateOrder} />
    </MenuContext.Provider>
  );

  return new MenuWrapper(wrapper, onCreateOrder);
}

class MenuWrapper {
  constructor(wrapper, onCreateOrder) {
    this.wrapper = wrapper;
    this.onCreateOrder = onCreateOrder;
  }
  find(selector) {
    return this.wrapper.find(selector);
  }
  cart() {
    return this.find("Cart");
  }
  payItForward() {
    return this.find("PayItForward");
  }
  cartTotal() {
    return this.cart().find("Total").text();
  }
  submitOrderBtn() {
    const btn = this.find("button[type='submit']");
    expect(btn.text()).toContain("Order");
    return btn;
  }
  items() {
    return this.find("Item");
  }
  skipBtn() {
    return this.find("SkipThisWeek").find("button");
  }
  submitOrder() {
    this.submitOrderBtn().simulate("click");
  }
  submittedOrder() {
    return this.onCreateOrder.mock.calls[0][0];
  }
}
