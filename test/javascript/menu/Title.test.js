import React from "react";
require("../configure_enzyme");
import { mount } from "enzyme";
import { DateTime, Duration } from "luxon";

import Title from "menu/Title";

function makeTitle(orderDeadlineAt) {
  const pickupAt = DateTime.now().plus(Duration.fromISO("PT24H")).toISO();

  return mount(
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
  const wrapper = makeTitle(orderDeadlineAt);
  expect(wrapper.getDOMNode()[1].id).toBe("deadline");
});

test("Before deadline: small warning", () => {
  const orderDeadlineAt = DateTime.now()
    .minus(Duration.fromISO("PT12H"))
    .toISO();
  const wrapper = makeTitle(orderDeadlineAt);
  expect(wrapper.getDOMNode()[1].id).toBe("past-deadline");
});
