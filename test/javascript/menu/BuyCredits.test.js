import React from "react";
require("../configure_enzyme");
import { mount } from "enzyme";

import Subscription, { humanizeBreadsPerWeek } from "menu/Subscription";
import { SettingsContext } from "menu/Contexts";
import mockMenuJson from "./mockMenuJson";
import stripeMock from "./stripeMock";

test("buy credits", () => {
  window.gon = { stripeApiKey: "no-such-key" };
  window.Stripe = jest.fn().mockReturnValue(stripeMock);

  const { user, bundles } = mockMenuJson();

  const wrapper = mount(
    <SettingsContext.Provider value={{ bundles, enablePayWhatYouCan: true }}>
      <Subscription user={user} />
    </SettingsContext.Provider>
  );

  // user name
  expect(wrapper.find(".subscriber-info").first().text()).toEqual(user.name);

  // credits
  expect(parseInt(wrapper.find(".subscriber-info").at(1).text())).toEqual(
    user.credits
  );

  // click buy credits button
  wrapper.find("button").simulate("click");

  // for each choice in the bundle
  expect(wrapper.find("Choice")).toHaveLength(bundles.length);
  expect(wrapper.find("Choice").first().text()).toEqual(
    "Weekly26 credits at $6.50 ea$169.00"
  );

  // 6-month, 3-month headers
  expect(wrapper.find("h6")).toHaveLength(2);
  expect(wrapper.find("h6").first().text()).toEqual("6-Month");

  // click a bundle
  wrapper.find("Choice").first().find("button").first().simulate("click");

  expect(wrapper.find("Payment")).toHaveLength(1);
  expect(wrapper.find("PayWhatYouCan")).toHaveLength(1);
  expect(wrapper.find("Card")).toHaveLength(1);

  expect(wrapper.find("Payment").props().credits).toBe(26);
  expect(wrapper.find("Payment").props().price).toBe(169);
});

test("no payWhatYouCan", () => {
  window.gon = { stripeApiKey: "no-such-key" };
  window.Stripe = jest.fn().mockReturnValue(stripeMock);

  const { user, bundles } = mockMenuJson();
  const wrapper = mount(
    <SettingsContext.Provider value={{ bundles, enablePayWhatYouCan: false }}>
      <Subscription user={user} />
    </SettingsContext.Provider>
  );

  // click buy credits button
  wrapper.find("button").simulate("click");

  // click a bundle
  wrapper.find("Choice").first().find("button").first().simulate("click");

  expect(wrapper.find("Payment")).toHaveLength(1);
  expect(wrapper.find("PayWhatYouCan")).toHaveLength(0);
  expect(wrapper.find("Card")).toHaveLength(1);
});

test("humanizeBreadsPerWeek", () => {
  expect(humanizeBreadsPerWeek(0.5)).toEqual("Every other week");
  expect(humanizeBreadsPerWeek(1.0)).toEqual("Every week");
  expect(humanizeBreadsPerWeek(2.0)).toEqual("Two breads per week");
  expect(humanizeBreadsPerWeek(3.0)).toEqual("Three breads per week");
  expect(humanizeBreadsPerWeek(5.3)).toEqual("5.3 breads per week");
});
