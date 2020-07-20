import React from "react";
require("../configure_enzyme");
import { shallow } from "enzyme";

import Title from "menu/Title";
import orderData from "./order-data";

//
// setup a mock for past deadline
//
import { pastDeadline } from "menu/pastDeadline";
jest.mock("menu/pastDeadline", () => {
  let areWePastDeadline = true;
  function __setPastDeadline(newValue) {
    areWePastDeadline = newValue;
  }

  return { __setPastDeadline, pastDeadline: () => areWePastDeadline };
});
import { __setPastDeadline } from "menu/pastDeadline";

test("__setPastDeadline back and forth in same test", () => {
  __setPastDeadline(false);
  expect(pastDeadline()).toBe(false);

  __setPastDeadline(true);
  expect(pastDeadline()).toBe(true);
});

test("Before deadline snapshot", () => {
  __setPastDeadline(false);

  const wrapper = shallow(<Title {...orderData} />);
  expect(wrapper).toMatchSnapshot();
});

test("After deadline snapshot", () => {
  __setPastDeadline(true);

  const wrapper = shallow(<Title {...orderData} />);
  expect(wrapper).toMatchSnapshot();
});
