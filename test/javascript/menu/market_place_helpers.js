import React from "react";
import { mount } from "enzyme";

import Marketplace from "menu/Marketplace";

export function renderMenu({ menu }) {
  window.gon = { stripeApiKey: "no-such-key" };

  // Mocking Stripe object
  const elementMock = {
    mount: jest.fn(),
    destroy: jest.fn(),
    on: jest.fn(),
    update: jest.fn(),
  };

  const elementsMock = {
    create: jest.fn().mockReturnValue(elementMock),
  };

  const stripeMock = {
    elements: jest.fn().mockReturnValue(elementsMock),
    createToken: jest.fn(() => Promise.resolve()),
    createSource: jest.fn(() => Promise.resolve()),
  };

  // Set the global Stripe
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
    <Marketplace menu={menu} onCreateOrder={onCreateOrder} />
  );

  return new MarketplaceWrapper(wrapper, onCreateOrder);
}

class MarketplaceWrapper {
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
    return this.wrapper.find("button[type='submit']");
  }
  items() {
    return this.wrapper.find("Item");
  }
  skipBtn() {
    return this.wrapper.find("SkipThisWeek").find("button");
  }
  submitOrder() {
    const btn = this.submitOrderBtn();
    expect(btn.prop("disabled")).toBe(false);
    btn.simulate("click");
  }
  submittedOrder() {
    return this.onCreateOrder.mock.calls[0][0];
  }
  fillUser(firstName, lastName, email) {
    const inputs = this.wrapper.find("input");
    // idk why but the email field needs to get automated first
    inputs.at(2).simulate("change", { target: { value: email } });
    inputs.at(0).simulate("change", { target: { value: firstName } });
    inputs.at(1).simulate("change", { target: { value: lastName } });
  }
}
