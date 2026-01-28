import React from "react";
import { expect, test } from "bun:test";
import { render } from "@testing-library/react";

import mockMenuJson from "./mockMenuJson";
import Items, { DayButton, Item } from "menu/Items";
import { DateTime, Duration } from "luxon";

const basePickupAt = DateTime.now().plus(Duration.fromISO("PT24H")).toISO();

const basePickupDay = (id: number, remaining: number = 10) => ({
  id,
  pickupAt: basePickupAt,
  orderDeadlineAt: basePickupAt,
  remaining,
});

const baseItem = (overrides = {}) => ({
  id: 1,
  name: "Test item",
  description: "",
  price: 1,
  credits: 1,
  image: null,
  subscriber: true,
  marketplace: true,
  pickupDays: [basePickupDay(1)],
  ...overrides,
});

test("items", () => {
  const { menu } = mockMenuJson();
  const { items } = menu;

  const { container } = render(<Items items={items} />);
  expect(container.querySelectorAll(".col-6.mb-4")).toHaveLength(6);
});

test("day1day2", () => {
  const renderItem = (props) =>
    render(<Item onChange={() => {}} {...baseItem(props)} />);
  const expectButtons = (props) =>
    expect(renderItem(props).container.querySelectorAll("button"));

  expectButtons({
    pickupDays: [basePickupDay(1), basePickupDay(2)],
  }).toHaveLength(2);
  expectButtons({ pickupDays: [basePickupDay(1)] }).toHaveLength(1);
  expectButtons({ pickupDays: [] }).toHaveLength(0);
});

test("remaining deadline", () => {
  const renderDay = (props) =>
    render(
      <DayButton
        itemId={1}
        id={1}
        pickupAt={basePickupAt}
        orderDeadlineAt={basePickupAt}
        onSetDayId={() => {}}
        {...props}
      />
    );

  expect(renderDay({ remaining: 4 }).container.textContent).toMatch("4 left");
  expect(
    renderDay({ remaining: 4 }).container.querySelector("button").disabled
  ).toBe(false);
  expect(
    renderDay({ remaining: 0 }).container.querySelector("button").disabled
  ).toBe(true);

  const orderDeadlineAt = DateTime.now()
    .minus(Duration.fromISO("PT1H"))
    .toISO();
  expect(
    renderDay({ orderDeadlineAt }).container.querySelector("button").disabled
  ).toBe(true);
});
