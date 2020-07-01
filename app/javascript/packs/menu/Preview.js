import React from "react";

import BakersNote from "./BakersNote";
import Deadline from "./Deadline";
import Items from "./Items";
import Subscription from "./Subscription";

export default function Preview({ user, menu }) {
  const { name, bakersNote, items, deadlineDay } = menu;

  return (
    <>
      {user && <Subscription {...{ user, deadlineDay }} />}

      <h2>{name}</h2>
      <Deadline menu={menu} />
      <BakersNote {...{ bakersNote }} />

      <h5>Items</h5>
      <Items items={items} />
    </>
  );
}
