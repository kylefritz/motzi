import React from "react";

import { pastDeadline } from "./pastDeadline";

export default function Deadline({ menu }) {
  const { deadlineDay, deadline } = menu;

  if (!pastDeadline(deadline)) {
    return null;
  }

  return (
    <div className="alert alert-secondary text-center py-3 my-4" role="alert">
      <h6 className="alert-heading">Ordering is closed for this menu</h6>
      The cut off for ordering is midnight {deadlineDay} every week
    </div>
  );
}
