import React from "react";
require("../configure_enzyme");
import { mount } from "enzyme";

import { DayContext } from "menu/Contexts";
import Title from "menu/Title";

//
// setup a mock for past deadline
//
import { pastDeadline } from "menu/pastDeadline";
jest.mock("menu/pastDeadline", () => {
  let areWePastDeadline = true;
  function __setPastDeadline(newValue) {
    areWePastDeadline = newValue;
  }

  return { __setPastDeadline, pastDeadline: () => areWePastDeadline };
});
import { __setPastDeadline } from "menu/pastDeadline";

test("__setPastDeadline back and forth in same test", () => {
  __setPastDeadline(false);
  expect(pastDeadline()).toBeFalsy();

  __setPastDeadline(true);
  expect(pastDeadline()).toBeTruthy();
});

function makeTitle() {
  return mount(
    <DayContext.Provider
      value={{
        day1: "Tuesday",
        day1DeadlineDay: "Sunday",
        day2: "Wednesday",
        day2DeadlineDay: "Monday",
      }}
    >
      <Title
        menu={{
          name: "Week 6: toast",
          orderingDeadlineText:
            "9:00 pm Tuesday for Thursday pickup or 9:00 pm Thurs for Sat pickup",
        }}
      />
    </DayContext.Provider>
  );
}
test("After deadline: ordering close", () => {
  __setPastDeadline(true);
  expect(makeTitle()).toMatchSnapshot();
});

test("Before deadline: small warning", () => {
  __setPastDeadline(false);
  expect(makeTitle()).toMatchSnapshot();
});
