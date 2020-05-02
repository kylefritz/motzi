import React from "react";
require("../configure_enzyme");
import { shallow } from "enzyme";

import Deadline from "menu/Deadline";
import orderData from "./order-data";
import moment from "moment";

test("Before deadline snapshot", () => {
  const wrapper = shallow(<Deadline {...orderData} />);
  expect(wrapper).toMatchSnapshot();
});

test("After deadline snapshot", () => {
  orderData.menu.deadline = moment().add(-1, "days");
  const wrapper = shallow(<Deadline {...orderData} />);
  expect(wrapper).toMatchSnapshot();
});
