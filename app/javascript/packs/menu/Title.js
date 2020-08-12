import React from "react";
import _ from "lodash";

import { getDayContext } from "./Contexts";

function When({ menu, br }) {
  const { orderingDeadlineText } = menu;
  if (!orderingDeadlineText) {
    console.warn("menu.orderingDeadlineText is null");
    return null;
  }

  const [day1, day2] = orderingDeadlineText.split("or");
  return (
    <>
      Order by {day1} {day2 && br && <br />}
      {day2 && <>or {day2}</>}
    </>
  );
}

export default function Title({ menu }) {
  const { name } = menu;
  const { pastDay2Deadline: isClosed } = getDayContext();

  return (
    <>
      <h2 id="menu-name">{name}</h2>
      {isClosed ? (
        <div
          className="alert alert-secondary text-center py-3 my-4"
          role="alert"
        >
          <h6 className="alert-heading">Ordering is closed for this menu</h6>
          <When menu={menu} br={true} />
        </div>
      ) : (
        <div id="deadline">
          <small>
            <When menu={menu} br={false} />
          </small>
        </div>
      )}
    </>
  );
}
