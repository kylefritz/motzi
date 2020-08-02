import React from "react";
import { mount } from "enzyme";

import Menu from "menu/Menu";
import mockMenuJson from "./mockMenuJson";
import { SettingsContext } from "menu/Contexts";

export default function renderMenu(mockMenuJsonOptions) {
  const onCreateOrder = jest.fn();
  const data = mockMenuJson(mockMenuJsonOptions);
  const { bundles } = data;

  const wrapper = mount(
    <SettingsContext.Provider value={{ showCredits: true, bundles }}>
      <Menu {...data} onCreateOrder={onCreateOrder} />
    </SettingsContext.Provider>
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
    return this.cart().find("Total").find("Price").text();
  }
  submitOrderBtn() {
    const btn = this.find("SubmitButton").find("button");
    expect(btn).toHaveLength(1);
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
