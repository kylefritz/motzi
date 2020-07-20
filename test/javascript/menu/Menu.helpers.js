import React from "react";
import { mount } from "enzyme";

import { UserContext } from "menu/Contexts";
import Menu from "menu/Menu";

export default function renderMenu({ user, menu, order }) {
  const onCreateOrder = jest.fn();

  const wrapper = mount(
    <UserContext.Provider value={user}>
      <Menu {...{ user, order, menu }} onCreateOrder={onCreateOrder} />
    </UserContext.Provider>
  );

  return new MenuWrapper(wrapper, onCreateOrder);
}

class MenuWrapper {
  constructor(wrapper, onCreateOrder) {
    this.wrapper = wrapper;
    this.onCreateOrder = onCreateOrder;
  }
  cart() {
    return this.wrapper.find("Cart");
  }
  cartTotal() {
    return this.cart().find("Total").text();
  }
  submitOrderBtn() {
    const btn = this.wrapper.find("button[type='submit']");
    expect(btn.text()).toContain("Order");
    return btn;
  }
  items() {
    return this.wrapper.find("Item");
  }
  skipBtn() {
    return this.wrapper.find("SkipThisWeek").find("button");
  }
  submitOrder() {
    this.submitOrderBtn().simulate("click");
  }
  submittedOrder() {
    return this.onCreateOrder.mock.calls[0][0];
  }
}
