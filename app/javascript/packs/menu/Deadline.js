import React from "react";
import moment from "moment";

export default function Deadline({ menu }) {
  const { deadlineDay } = menu;

  const now = moment();
  const deadline = moment(menu.deadline);
  const pastDeadline = now > deadline;
  if (!pastDeadline) {
    return null;
  }

  return (
    <div className="alert alert-warning text-center" role="alert">
      <h4 className="alert-heading">Ordering is closed for this menu</h4>
      Order by {deadlineDay} at midnight for each week's menu.
    </div>
  );
}
