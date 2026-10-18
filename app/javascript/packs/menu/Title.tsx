import React from "react";
import { parse, shortDate, shortTime } from "../../lib/dates";

import { useDeadlineContext } from "./Contexts";
import type { MenuPickupDay } from "../../types/api";

function PickupSchedule({
  pickupDays,
  muted,
}: {
  pickupDays: MenuPickupDay[];
  muted?: string;
}) {
  if (!pickupDays || pickupDays.length === 0) return null;

  return (
    <div
      style={{
        display: "flex",
        justifyContent: "center",
        gap: "16px",
        textAlign: "center",
        flexWrap: "wrap",
      }}
    >
      {pickupDays.map(({ id, pickupAt, orderDeadlineAt }) => {
        const pickup = parse(pickupAt);
        const deadline = parse(orderDeadlineAt);
        return (
          <div key={id} style={{ flex: "1 1 140px" }}>
            <span>{shortDate(pickup)}</span>
            <br />
            <span>pickup after {shortTime(pickup)}</span>
            <br />
            <span style={{ fontSize: "0.85em", opacity: 0.7, color: muted }}>
              order by {shortDate(deadline)} at {shortTime(deadline)}
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
  const isClosed = useDeadlineContext().allClosed(menu);

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
