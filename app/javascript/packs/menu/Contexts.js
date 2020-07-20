import React, { useContext } from "react";
import { pastDeadline } from "./pastDeadline";

const UserContext = React.createContext();
const DayContext = React.createContext();
export { DayContext, UserContext };

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
