import React from "react";
import _ from "lodash";

import { pastDeadline } from "./pastDeadline";

function When({ menu, br }) {
  const { day1, day1DeadlineDay, day2, day2DeadlineDay } = menu;

  return (
    <>
      Order by midnight {day1DeadlineDay} for {day1} pickup {br && <br />}or
      midnight {day2DeadlineDay} for {day2} pickup.
    </>
  );
}

export default function Title({ menu }) {
  const { name, day2Deadline } = menu;

  const isClosed = pastDeadline(day2Deadline);

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
