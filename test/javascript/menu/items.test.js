require("../configure_enzyme");
import React from "react";
import { mount } from "enzyme";

import mockMenuJson from "./mockMenuJson";
import Items, { DayButton, Item } from "menu/Items";

test("items", () => {
  const { menu } = mockMenuJson();
  const { items } = menu;

  const wrapper = mount(<Items items={items} />);
  expect(wrapper.find("Item")).toHaveLength(6);
});

test("day1day2", () => {
  const render = (props) => mount(<Item onChange={true} {...props} />);
  const expectButtons = (props) => expect(render(props).find("button"));

  expectButtons({ day1: true, day2: true }).toHaveLength(2);
  expectButtons({ day1: true, day2: false }).toHaveLength(1);
  expectButtons({ day1: false, day2: true }).toHaveLength(1);
  expectButtons({ day1: false, day2: false }).toHaveLength(0);
});

test("remaining deadline", () => {
  const render = (props) =>
    mount(<DayButton day="Thursday" btn="primary" {...props} />);

  expect(render({ remaining: 4 }).text()).toMatch("4 left");
  expect(render({ remaining: 4 }).find("button").prop("disabled")).toBe(
    undefined
  );
  expect(render({ remaining: 0 }).find("button").prop("disabled")).toBe(true);

  expect(render({ isPastDeadline: true }).find("button").prop("disabled")).toBe(
    true
  );
});
