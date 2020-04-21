import React, { createFactory } from "react";
import _ from "lodash";

function DaysCart({ menu, cart, rmCartItem }) {
  const { items } = menu;

  const menuItemLookup = _.keyBy(items, (i) => i.id);
  const lookupMenuItemName = (id) => _.get(menuItemLookup[id], "name", id);

  return (
    <>
      <ul>
        {cart.map(({ itemId, quantity, day }) => (
          <li key={`${itemId}:${quantity}:${day}`} className="mb-2">
            {quantity > 1 && <strong className="mr-2">{quantity}x</strong>}
            {lookupMenuItemName(itemId)}
            <button
              type="button"
              className="mr-5 close"
              aria-label="Close"
              onClick={() => rmCartItem(itemId, quantity, day)}
            >
              <span aria-hidden="true">&times;</span>
            </button>
          </li>
        ))}
      </ul>
    </>
  );
}

function Days({ menu, cart, rmCartItem }) {
  const [thurs, sat] = _.partition(cart, ({ day }) => day == "Thursday");

  const days = [];

  if (thurs.length) {
    days.push(
      <div key="thurs">
        <h6>Thursday</h6>
        <DaysCart {...{ menu, rmCartItem, cart: thurs }} />
      </div>
    );
  }

  if (sat.length) {
    days.push(
      <div key="sat">
        <h6>Saturday</h6>
        <DaysCart {...{ menu, rmCartItem, cart: sat }} />
      </div>
    );
  }

  return days;
}

function Total({ cart }) {
  const total = _.sum(cart.map(({ quantity }) => quantity));
  return (
    <div>
      <h6>Total</h6>
      <div className="ml-4">
        {total} credit{total > 1 && "s"}
      </div>
    </div>
  );
}

function Wrapped({ menu, cart, rmCartItem }) {
  if (!cart.length) {
    return <p>No items</p>;
  }
  return (
    <>
      <Days {...{ menu, cart, rmCartItem }} />
      <Total cart={cart} />
    </>
  );
}

export default function Cart(props) {
  return (
    <>
      <h5>Your order</h5>
      <div className="ml-2">
        <Wrapped {...props} />
      </div>
    </>
  );
}
