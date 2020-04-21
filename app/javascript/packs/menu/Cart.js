import React from "react";
import _ from "lodash";

export default function ({ menu, cart }) {
  const { items } = menu;

  const menuItemLookup = _.keyBy(items, (i) => i.id);
  const lookupMenuItemName = (id) => _.get(menuItemLookup[id], "name", id);

  return (
    <>
      <ul>
        {cart.map(({ itemId, quantity, day }, i) => (
          <li key={i}>
            {quantity > 1 && <strong className="mr-2">{quantity}x</strong>}
            {lookupMenuItemName(itemId)}
            <br />
            <small>{day}</small>
          </li>
        ))}
      </ul>
    </>
  );
}
