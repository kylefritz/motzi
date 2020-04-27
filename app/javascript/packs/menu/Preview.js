import React from "react";

import Item from "./Item";
import BakersNote from "./BakersNote";

export default function ({ menu }) {
  const { name, bakersNote, items } = menu;

  return (
    <>
      <h2>{name}</h2>

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
