import React from "react";

import BakersNote from "./BakersNote";
import Deadline from "./Deadline";
import Item from "./Item";
import User from "./User";

export default function ({ user, menu }) {
  const { name, bakersNote, items, deadlineDay } = menu;

  return (
    <>
      {user && <User {...{ user, deadlineDay }} />}

      <h2>{name}</h2>
      <Deadline menu={menu} />
      <BakersNote {...{ bakersNote }} />

      <h5>Items</h5>
      <div className="row mt-3">
        {items.map((i) => (
          <Item key={i.id} {...i} />
        ))}
      </div>
    </>
  );
}
