import React, { useContext } from "react";
import _ from "lodash";

import { getDeadlineContext, HideMenuNameContext } from "./Contexts";
import type { MenuPickupDay } from "../../types/api";

function When({ orderingDeadlineText }) {
  if (!orderingDeadlineText) {
    console.warn("menu.orderingDeadlineText is null");
    return null;
  }

  const days = orderingDeadlineText.split(" or\n");
  if (days.length > 0) {
    days[0] = _.upperFirst(days[0]);
  }

  return days.map((words, index) => (
    <React.Fragment key={index}>
      {words}
      {index != days.length - 1 && <br />}
    </React.Fragment>
  ));
}

type TitleProps = {
  menu: {
    name: string;
    orderingDeadlineText: string;
    pickupDays: MenuPickupDay[];
  };
};

export default function Title({ menu }: TitleProps) {
  const { name, orderingDeadlineText } = menu;
  const isClosed = getDeadlineContext().allClosed(menu);
  const hideMenuName = useContext(HideMenuNameContext);

  return (
    <>
      {!hideMenuName && <h2 id="menu-name">{name}</h2>}
      {isClosed ? (
        <div
          id="past-deadline"
          className="alert alert-secondary text-center py-3 my-4"
          role="alert"
        >
          <h6 className="alert-heading">Ordering is closed for this menu</h6>
          <When {...{ orderingDeadlineText }} />
        </div>
      ) : (
        <div id="deadline">
          <small>
            <When {...{ orderingDeadlineText }} />
          </small>
        </div>
      )}
    </>
  );
}
