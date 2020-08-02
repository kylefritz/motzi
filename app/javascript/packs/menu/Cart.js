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
  const { day1, day1Closed, day2, day2Closed } = getDayContext();

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
            rmCartItem: !day1Closed && rmCartItem,
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
            rmCartItem: !day2Closed && rmCartItem,
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
            rmCartItem: !day2Closed && rmCartItem,
            cart: payItForward,
          }}
        />
      </div>
    );
  }

  return sections;
}

function cartPriceCredits({ cart, menu }) {
  if (cart.length === 0) {
    return [null, 0];
  }

  const menuItemsById = buildMenuItemLookup(menu);
  const addBy = (attribute) =>
    _.sum(
      cart.map(
        ({ itemId, quantity }) =>
          _.get(menuItemsById[itemId], attribute, 0) * quantity
      )
    );

  return [addBy("price"), addBy("credits")];
}

export function cartTotal({ cart, menu }) {
  cartPriceCredits({ cart, menu })[0];
}

function Total({ cart, menu, stripeChargeAmount }) {
  const [price, credits] = cartPriceCredits({ cart, menu });
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
