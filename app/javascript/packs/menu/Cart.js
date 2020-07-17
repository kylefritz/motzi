import React from "react";
import _ from "lodash";

import Price from "./Price";

function buildMenuItemLookup(menu) {
  const { items } = menu;
  const menuItems = _.keyBy(items, (i) => i.id);
  menuItems[menu.payItForward.id] = menu.payItForward;
  return menuItems;
}

function DaysCart({ menu, cart, rmCartItem }) {
  const menuItemsById = buildMenuItemLookup(menu);

  return (
    <>
      <ul className="list-unstyled">
        {cart.map(({ itemId, quantity, day }, index) => (
          <li
            key={`${index}:${itemId}:${quantity}:${day}`}
            className="mb-2 ml-4"
          >
            {quantity > 1 && <strong className="mr-2">{quantity}x</strong>}
            {_.get(menuItemsById[itemId], "name", `Item ${itemId}`)}
            {rmCartItem && (
              <button
                type="button"
                className="mr-5 close"
                aria-label="Close"
                onClick={() => rmCartItem(itemId, quantity, day)}
              >
                <span aria-hidden="true">&times;</span>
              </button>
            )}
          </li>
        ))}
      </ul>
    </>
  );
}

function Days({ menu, cart, rmCartItem, skip }) {
  const thurs = cart.filter(({ day }) => day === "Thursday");
  const sat = cart.filter(({ day }) => day === "Saturday");
  const payItForward = cart.filter(
    ({ itemId }) => itemId === menu.payItForward.id
  );

  if (skip) {
    return (
      <div>
        <p>Skip this week</p>
      </div>
    );
  }

  const sections = [];
  if (thurs.length) {
    sections.push(
      <div key="thurs">
        <h6>Thursday</h6>
        <DaysCart {...{ menu, rmCartItem, cart: thurs }} />
      </div>
    );
  }

  if (sat.length) {
    sections.push(
      <div key="sat">
        <h6>Saturday</h6>
        <DaysCart {...{ menu, rmCartItem, cart: sat }} />
      </div>
    );
  }

  if (payItForward.length) {
    sections.push(
      <div key="pay-it-forward">
        <h6>Pay It Forward</h6>
        <DaysCart {...{ menu, rmCartItem, cart: payItForward }} />
      </div>
    );
  }

  return sections;
}

export function cartTotal({ cart, menu, stripeChargeAmount }) {
  if (cart.length === 0) {
    return null;
  }

  const menuItemsById = buildMenuItemLookup(menu);
  return _.sum(
    cart.map(
      ({ itemId, quantity }) =>
        _.get(menuItemsById[itemId], "price", 0) * quantity
    )
  );
}

function Total({ cart, menu, stripeChargeAmount }) {
  const credits = _.sum(cart.map(({ quantity }) => quantity));
  const price = cartTotal({ cart, menu });
  return (
    <div>
      <h6>Total</h6>
      <div className="ml-4">
        <Price {...{ price, credits, stripeChargeAmount }} />
      </div>
    </div>
  );
}

function Cart(props) {
  const { cart, skip } = props;
  if (!cart.length && !skip) {
    return <p>No items</p>;
  }
  return (
    <>
      <Days {...props} />
      <Total {...props} />
    </>
  );
}

export default function CartWrapper(props) {
  return (
    <>
      <h5>Your order</h5>
      <div className="ml-2">
        <Cart {...props} />
      </div>
    </>
  );
}
