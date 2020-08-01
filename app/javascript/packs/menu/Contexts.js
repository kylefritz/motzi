import React, { useContext } from "react";
import { pastDeadline } from "./pastDeadline";
import _ from "lodash";

const DayContext = React.createContext();
const MenuContext = React.createContext();

export { DayContext, MenuContext };

export function getMenuContext() {
  const ctx = useContext(MenuContext);
  if (_.isNil(ctx)) {
    console.trace("getMenuContext is nil", ctx);
  }
  return ctx || {};
}

export function getDayContext() {
  const ctx = useContext(DayContext);
  if (ctx !== undefined) {
    const { day1Deadline, day2Deadline, ignoreDeadline } = ctx;

    const pastDay1Deadline = pastDeadline(day1Deadline);
    const day1Closed = pastDay1Deadline && !ignoreDeadline;
    const pastDay2Deadline = pastDeadline(day2Deadline);
    const day2Closed = pastDay2Deadline && !ignoreDeadline;

    return {
      ...ctx,
      pastDay1Deadline,
      pastDay2Deadline,
      day1Closed,
      day2Closed,
    };
  }

  return {
    day1: "Thursday",
    day1DeadlineDay: "Tuesday",
    pastDay1Deadline: false,
    day1Closed: false,
    //
    day2: "Saturday",
    day2DeadlineDay: "Thursday",
    pastDay2Deadline: false,
    day2Closed: false,
  };
}
