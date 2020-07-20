import React from "react";
import _ from "lodash";

import Price from "./Price";
import { getDayContext } from "./Contexts";

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
      {cart.map(({ itemId, quantity, day }, index) => (
        <div className="row mb-3" key={`${index}:${itemId}:${quantity}:${day}`}>
          <div className="col-1" />
          <div className="col">
            {quantity > 1 && <strong className="mr-2">{quantity}x</strong>}
            {_.get(menuItemsById[itemId], "name", `Item ${itemId}`)}
          </div>
          {rmCartItem && (
            <div className="col">
              <button
                type="button"
                className="close"
                aria-label="Close"
                onClick={() => rmCartItem(itemId, quantity, day)}
              >
                <span aria-hidden="true">&times;</span>
              </button>
            </div>
          )}
        </div>
      ))}
    </>
  );
}

function Days({ menu, cart, rmCartItem, skip }) {
  const { day1, pastDay1Deadline, day2, pastDay2Deadline } = getDayContext();

  const thurs = cart.filter(({ day }) => day === day1);
  const sat = cart.filter(({ day }) => day === day2);
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
      <div key="day1">
        <h6>{day1}</h6>
        <DaysCart
          {...{
            menu,
            rmCartItem: !pastDay1Deadline && rmCartItem,
            cart: thurs,
          }}
        />
      </div>
    );
  }

  if (sat.length) {
    sections.push(
      <div key="day2">
        <h6>{day2}</h6>
        <DaysCart
          {...{
            menu,
            rmCartItem: !pastDay2Deadline && rmCartItem,
            cart: sat,
          }}
        />
      </div>
    );
  }

  if (payItForward.length) {
    sections.push(
      <div key="pay-it-forward">
        <h6>Pay It Forward</h6>
        <DaysCart
          {...{
            menu,
            rmCartItem: !pastDay2Deadline && rmCartItem,
            cart: payItForward,
          }}
        />
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
      <div className="row">
        <div className="col-1" />
        <div className="col">
          <Price {...{ price, credits, stripeChargeAmount }} />
        </div>
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
