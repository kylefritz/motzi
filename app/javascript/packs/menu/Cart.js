import React, { createFactory } from "react";
import _ from "lodash";

function DaysCart({ menu, cart }) {
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
          </li>
        ))}
      </ul>
    </>
  );
}

function Days({ menu, cart }) {
  const [thurs, sat] = _.partition(cart, ({ day }) => day == "Thursday");

  const days = [];

  if (thurs.length) {
    days.push(
      <div key="thurs">
        <h6>Thursday</h6>
        <DaysCart menu={menu} cart={thurs} />
      </div>
    );
  }

  if (sat.length) {
    days.push(
      <div key="sat">
        <h6>Saturday</h6>
        <DaysCart menu={menu} cart={sat} />
      </div>
    );
  }

  return days;
}

export default function Cart({ menu, cart }) {
  return (
    <>
      <h5>Your order</h5>
      {cart.length ? <Days menu={menu} cart={cart} /> : <p>No items</p>}
    </>
  );
}
