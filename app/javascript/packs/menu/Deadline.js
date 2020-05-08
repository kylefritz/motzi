import React from "react";

import { pastDeadline } from "./pastDeadline";

export default function Deadline({ menu }) {
  const { deadlineDay, deadline } = menu;

  if (!pastDeadline(deadline)) {
    return null;
  }

  return (
    <div className="alert alert-warning text-center" role="alert">
      <h4 className="alert-heading">Ordering is closed for this menu</h4>
      Order by {deadlineDay} at midnight for each week's menu.
    </div>
  );
}
