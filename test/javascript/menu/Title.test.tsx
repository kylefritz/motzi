import React from "react";
import { expect, test } from "bun:test";
import { render } from "@testing-library/react";
import { DateTime, Duration } from "luxon";

import Title from "menu/Title";

function makeTitle(orderDeadlineAt) {
  const pickupAt = DateTime.now().plus(Duration.fromISO("PT24H")).toISO();

  return render(
    <Title
      menu={{
        name: "Week 6: toast",
        orderingDeadlineText:
          "9:00 pm Tuesday for Thursday pickup or 9:00 pm Thurs for Sat pickup",
        pickupDays: [{ id: 1, pickupAt, orderDeadlineAt }],
      }}
    />
  );
}

test("After deadline: ordering close", () => {
  const orderDeadlineAt = DateTime.now()
    .plus(Duration.fromISO("PT12H"))
    .toISO();
  const { container } = makeTitle(orderDeadlineAt);
  const deadlineEl = container.querySelector("#deadline");
  expect(deadlineEl).toBeTruthy();
});

test("Before deadline: small warning", () => {
  const orderDeadlineAt = DateTime.now()
    .minus(Duration.fromISO("PT12H"))
    .toISO();
  const { container } = makeTitle(orderDeadlineAt);
  const warningEl = container.querySelector("#past-deadline");
  expect(warningEl).toBeTruthy();
});

test("Multiple pickup days: schedule wraps for mobile", () => {
  const now = DateTime.now();
  const pickupDays = [
    {
      id: 1,
      pickupAt: now.plus({ days: 1 }).toISO(),
      orderDeadlineAt: now.plus({ hours: 12 }).toISO(),
    },
    {
      id: 2,
      pickupAt: now.plus({ days: 3 }).toISO(),
      orderDeadlineAt: now.plus({ days: 2 }).toISO(),
    },
    {
      id: 3,
      pickupAt: now.plus({ days: 5 }).toISO(),
      orderDeadlineAt: now.plus({ days: 4 }).toISO(),
    },
  ];

  const { container } = render(
    <Title
      menu={{
        name: "Week 6: toast",
        orderingDeadlineText: "",
        pickupDays,
      }}
    />
  );

  const scheduleContainer = container.querySelector("#deadline > small > div");
  expect(scheduleContainer).toBeTruthy();
  expect(scheduleContainer!.style.flexWrap).toBe("wrap");
});
