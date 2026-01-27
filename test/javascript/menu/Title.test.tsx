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
