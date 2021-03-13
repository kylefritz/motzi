require("../configure_enzyme");
import React from "react";
import { mount } from "enzyme";

import mockMenuJson from "./mockMenuJson";
import Items, { DayButton, Item } from "menu/Items";
import { DateTime, Duration } from "luxon";

test("items", () => {
  const { menu } = mockMenuJson();
  const { items } = menu;

  const wrapper = mount(<Items items={items} />);
  expect(wrapper.find("Item")).toHaveLength(6);
});

test("day1day2", () => {
  const render = (props) => mount(<Item onChange={true} {...props} />);
  const expectButtons = (props) => expect(render(props).find("button"));

  expectButtons({ pickupDays: [{ id: 1 }, { id: 2 }] }).toHaveLength(2);
  expectButtons({ pickupDays: [{ id: 1 }] }).toHaveLength(1);
  expectButtons({ pickupDays: [] }).toHaveLength(0);
});

test("remaining deadline", () => {
  const render = (props) =>
    mount(<DayButton day="Thursday" btn="primary" {...props} />);

  expect(render({ remaining: 4 }).text()).toMatch("4 left");
  expect(render({ remaining: 4 }).find("button").prop("disabled")).toBe(
    undefined
  );
  expect(render({ remaining: 0 }).find("button").prop("disabled")).toBeTruthy();

  const orderDeadlineAt = DateTime.now()
    .minus(Duration.fromISO("PT1H"))
    .toISO();
  expect(render({ orderDeadlineAt }).find("button").prop("disabled")).toBe(
    true
  );
});
