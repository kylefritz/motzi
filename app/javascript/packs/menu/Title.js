import React from "react";
import _ from "lodash";

import { getDeadlineContext } from "./Contexts";

export default function Title({ menu }) {
  const { name, orderingDeadlineText } = menu;
  const isClosed = getDeadlineContext().allClosed(menu);

  return (
    <>
      <h2 id="menu-name">{name}</h2>
      {isClosed ? (
        <div
          id="past-deadline"
          className="alert alert-secondary text-center py-3 my-4"
          role="alert"
        >
          <h6 className="alert-heading">Ordering is closed for this menu</h6>
          {orderingDeadlineText}
        </div>
      ) : (
        <div id="deadline">
          <small>{orderingDeadlineText}</small>
        </div>
      )}
    </>
  );
}
