import React from "react";
import _ from "lodash";

import { getDayContext } from "./Contexts";

function When({ br }) {
  const { day1, day1DeadlineDay, day2, day2DeadlineDay } = getDayContext();

  return (
    <>
      Order by 9pm {day1DeadlineDay} for {day1} pickup {br && <br />}or 9pm{" "}
      {day2DeadlineDay} for {day2} pickup.
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
