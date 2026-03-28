import React from "react";
import moment from "moment";

import { getDeadlineContext } from "./Contexts";
import type { MenuPickupDay } from "../../types/api";

function formatTime(m: moment.Moment) {
  const minutes = m.minutes();
  const formatted = minutes === 0 ? m.format("ha") : m.format("h:mma");
  return formatted.replace("am", "a").replace("pm", "p");
}

function PickupSchedule({ pickupDays, muted }: { pickupDays: MenuPickupDay[]; muted?: string }) {
  if (!pickupDays || pickupDays.length === 0) return null;

  return (
    <div style={{ display: "flex", justifyContent: "center", gap: "16px", textAlign: "center", flexWrap: "wrap" }}>
      {pickupDays.map(({ id, pickupAt, orderDeadlineAt }) => {
        const pickup = moment(pickupAt);
        const deadline = moment(orderDeadlineAt);
        return (
          <div key={id} style={{ flex: "1 1 140px" }}>
            <span>
              {pickup.format("ddd, MMM D")}
            </span>
            <br />
            <span>
              pickup after {formatTime(pickup)}
            </span>
            <br />
            <span style={{ fontSize: "0.85em", opacity: 0.7, color: muted }}>
              order by {deadline.format("ddd, MMM D")} at {formatTime(deadline)}
            </span>
          </div>
        );
      })}
    </div>
  );
}

type TitleProps = {
  menu: {
    name: string;
    orderingDeadlineText: string;
    pickupDays: MenuPickupDay[];
  };
};

export default function Title({ menu }: TitleProps) {
  const { name, pickupDays } = menu;
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
          <PickupSchedule pickupDays={pickupDays} />
        </div>
      ) : (
        <div id="deadline">
          <small>
            <PickupSchedule pickupDays={pickupDays} />
          </small>
        </div>
      )}
    </>
  );
}
