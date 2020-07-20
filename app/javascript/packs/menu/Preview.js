import React from "react";

import BakersNote from "./BakersNote";
import Deadline from "./Deadline";
import Items from "./Items";
import Subscription from "./Subscription";

export default function Preview({ user, menu }) {
  const { name, menuNote, items, deadlineDay } = menu;

  return (
    <>
      {user && <Subscription {...{ user, deadlineDay }} />}

      <h2 id="menu-name">{name}</h2>
      <Deadline menu={menu} />
      <BakersNote note={menuNote} />

      <h5>Items</h5>
      <Items marketplace items={items} />
    </>
  );
}
