import React from "react";
require("../configure_enzyme");
import { shallow } from "enzyme";

import User, { humanizeBreadsPerWeek } from "menu/User";

test("snapshot", () => {
  const user = {
    name: "kyle",
    credits: 6,
    firstHalf: true,
    breadsPerWeek: 1.0,
  };
  const wrapper = shallow(<User user={user} />);
  expect(wrapper).toMatchSnapshot();
});

test("humanizeBreadsPerWeek", () => {
  expect(humanizeBreadsPerWeek(0.5)).toEqual("Every other week");
  expect(humanizeBreadsPerWeek(1.0)).toEqual("Every week");
  expect(humanizeBreadsPerWeek(2.0)).toEqual("Two breads per week");
  expect(humanizeBreadsPerWeek(3.0)).toEqual("Three breads per week");
  expect(humanizeBreadsPerWeek(5.3)).toEqual("5.3 breads per week");
});
