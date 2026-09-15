import React from "react";
import { expect, test } from "bun:test";
import { render } from "@testing-library/react";
import { Duration } from "luxon";

import Title from "menu/Title";
import { now, withNow } from "../support/clock";

function makeTitle(orderDeadlineAt) {
  const pickupAt = now().plus(Duration.fromISO("PT24H")).toISO();

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
  const orderDeadlineAt = now().plus(Duration.fromISO("PT12H")).toISO();
  const { container } = makeTitle(orderDeadlineAt);
  const deadlineEl = container.querySelector("#deadline");
  expect(deadlineEl).toBeTruthy();
});

test("Before deadline: small warning", () => {
  const orderDeadlineAt = now().minus(Duration.fromISO("PT12H")).toISO();
  const { container } = makeTitle(orderDeadlineAt);
  const warningEl = container.querySelector("#past-deadline");
  expect(warningEl).toBeTruthy();
});

test("Same deadline flips from open to closed as the clock passes it", () => {
  const orderDeadlineAt = "2026-01-06T21:00:00-05:00";

  withNow("2026-01-06T20:59:00-05:00", () => {
    const { container, unmount } = makeTitle(orderDeadlineAt);
    expect(container.querySelector("#past-deadline")).toBeNull();
    expect(container.querySelector("#deadline")).toBeTruthy();
    unmount();
  });

  withNow("2026-01-06T21:01:00-05:00", () => {
    const { container } = makeTitle(orderDeadlineAt);
    expect(container.querySelector("#past-deadline")).toBeTruthy();
  });
});

test("Multiple pickup days: schedule wraps for mobile", () => {
  const current = now();
  const pickupDays = [
    {
      id: 1,
      pickupAt: current.plus({ days: 1 }).toISO(),
      orderDeadlineAt: current.plus({ hours: 12 }).toISO(),
    },
    {
      id: 2,
      pickupAt: current.plus({ days: 3 }).toISO(),
      orderDeadlineAt: current.plus({ days: 2 }).toISO(),
    },
    {
      id: 3,
      pickupAt: current.plus({ days: 5 }).toISO(),
      orderDeadlineAt: current.plus({ days: 4 }).toISO(),
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

  const scheduleContainer = container.querySelector<HTMLElement>(
    "#deadline > small > div"
  );
  expect(scheduleContainer).toBeTruthy();
  expect(scheduleContainer!.style.flexWrap).toBe("wrap");
});
