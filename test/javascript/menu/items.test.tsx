import React from "react";
import { expect, test } from "bun:test";
import { render } from "@testing-library/react";

import mockMenuJson from "./mockMenuJson";
import Items, { DayButton, Item } from "menu/Items";
import { DateTime, Duration } from "luxon";

test("items", () => {
  const { menu } = mockMenuJson();
  const { items } = menu;

  const { container } = render(<Items items={items} />);
  expect(container.querySelectorAll(".col-6.mb-4")).toHaveLength(6);
});

test("day1day2", () => {
  const renderItem = (props) =>
    render(<Item onChange={true} {...props} />);
  const expectButtons = (props) =>
    expect(renderItem(props).container.querySelectorAll("button"));

  expectButtons({ pickupDays: [{ id: 1 }, { id: 2 }] }).toHaveLength(2);
  expectButtons({ pickupDays: [{ id: 1 }] }).toHaveLength(1);
  expectButtons({ pickupDays: [] }).toHaveLength(0);
});

test("remaining deadline", () => {
  const renderDay = (props) =>
    render(<DayButton day="Thursday" btn="primary" {...props} />);

  expect(renderDay({ remaining: 4 }).container.textContent).toMatch("4 left");
  expect(renderDay({ remaining: 4 }).container.querySelector("button").disabled).toBe(false);
  expect(renderDay({ remaining: 0 }).container.querySelector("button").disabled).toBe(true);

  const orderDeadlineAt = DateTime.now()
    .minus(Duration.fromISO("PT1H"))
    .toISO();
  expect(renderDay({ orderDeadlineAt }).container.querySelector("button").disabled).toBe(true);
});
