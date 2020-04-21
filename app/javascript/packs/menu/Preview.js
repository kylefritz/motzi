import React from "react";

import Item from "./Item";
import AddOn from "./AddOn";
import BakersNote from "./BakersNote";

export default function ({ menu }) {
  const { name, bakersNote, items, addons } = menu;

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

      {!!addons.length && (
        <>
          <h5>Add-Ons</h5>
          <div className="row mt-3 mb-5">
            <div className="col">
              <ul>
                {addons.map(({ id, name }) => (
                  <li key={id}>{name}</li>
                ))}
              </ul>
            </div>
          </div>
        </>
      )}
    </>
  );
}
