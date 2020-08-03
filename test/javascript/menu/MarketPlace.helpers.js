import React from "react";
import { mount } from "enzyme";

import Marketplace from "menu/Marketplace";
import mockMenuJson from "./mockMenuJson";
import stripeMock from "./stripeMock";
import { SettingsContext } from "../../../app/javascript/packs/menu/Contexts";

export default function renderMenu(menuJsonOptions) {
  window.gon = { stripeApiKey: "no-such-key" };
  window.Stripe = jest.fn().mockReturnValue(stripeMock);

  // Ex. of a token successfully created mock
  stripeMock.createToken.mockResolvedValue({
    token: {
      id: "test_id",
    },
  });

  // Ex. of a failure mock
  // stripeMock.createToken.mockResolvedValue({
  //   error: {
  //     code: 'incomplete_number',
  //     message: 'Your card number is incomplete.',
  //     type: 'validation_error',
  //   },
  // });

  const onCreateOrder = jest.fn(() => Promise.resolve());

  const wrapper = mount(
    <SettingsContext.Provider value={{}}>
      <Marketplace
        {...mockMenuJson(menuJsonOptions)}
        onCreateOrder={onCreateOrder}
      />
    </SettingsContext.Provider>
  );

  return new MarketplaceWrapper(wrapper, onCreateOrder);
}

class MarketplaceWrapper {
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
  cartTotal() {
    return this.cart().find("Total").text();
  }
  submitOrderBtn() {
    return this.find("button[type='submit']");
  }
  items() {
    return this.find("Item");
  }
  addItemToCart() {
    // click "thurs"
    const thurs = this.items().at(0).find("button").at(0);
    thurs.simulate("click");

    // click "add to cart"
    const addToCart = this.items().at(0).find("button").at(2);
    addToCart.simulate("click");
  }
  skipBtn() {
    return this.find("SkipThisWeek").find("button");
  }
  submitOrder() {
    const btn = this.submitOrderBtn();
    expect(btn.prop("disabled")).toBe(false);
    btn.simulate("click");
  }
  submittedOrder() {
    return this.onCreateOrder.mock.calls[0][0];
  }
  fillUser(firstName, lastName, email, phone) {
    const inputs = this.find("input");
    const setInput = (index, value) =>
      inputs.at(index).simulate("change", { target: { value } });

    setInput(0, firstName);
    setInput(1, lastName);
    setInput(2, email);
    setInput(3, phone);
  }
}
