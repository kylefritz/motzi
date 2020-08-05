import React from "react";
import _ from "lodash";
import { useState } from "react";

import Price from "./Price";
import { getDayContext } from "./Contexts";

function DaysCart({ menu: { items }, cart, rmCartItem }) {
  const menuItemsById = _.keyBy(items, ({ id }) => id);

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
    ({ itemId }) => itemId === _.get(menu, "payItForward.id", "wont-match")
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

function Total({ cart, menu: { items }, stripeChargeAmount }) {
  const { price, credits } = cartTotal({ cart, items });
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

function cartTotal({ cart, items }) {
  if (cart.length === 0) {
    return { price: null, credits: 0 };
  }
  const menuItemsById = _.keyBy(items, ({ id }) => id);
  const addBy = (attribute) =>
    _.sum(
      cart.map(
        ({ itemId, quantity }) =>
          _.get(menuItemsById[itemId], attribute, 0) * quantity
      )
    );

  return { price: addBy("price"), credits: addBy("credits") };
}

export function useCart({ order = null, items }) {
  const [cart, setCart] = useState(_.get(order, "items", []));
  const { day1 } = getDayContext();

  const calcTotal = (cart) => cartTotal({ cart, items });

  const addToCart = ({ id: itemId, quantity, day }) => {
    console.log("addToCart", itemId, quantity, day);
    const nextCart = [...cart, { itemId, quantity, day }];
    setCart(nextCart);
    return calcTotal(nextCart).price;
  };

  const rmCartItem = (itemId, quantity, day) => {
    const index = _.findIndex(
      cart,
      (ci) => ci.itemId === itemId && ci.quantity === quantity && ci.day === day
    );
    console.log("rmCartItem", index);
    const nextCart = [...cart];
    nextCart.splice(index, 1);
    setCart(nextCart);
    return calcTotal(nextCart).price;
  };

  // update remaining items
  const itemLookup = _.keyBy(_.cloneDeep(items), ({ id }) => id);
  cart.forEach(({ itemId, quantity, day }) => {
    if (itemId === -1) {
      return;
    }
    const prop = day === day1 ? "remainingDay1" : "remainingDay2";
    itemLookup[itemId][prop] -= quantity;
  });
  // maintain original order
  const nextItems = items.map(({ id }) => itemLookup[id]);

  return {
    cart,
    addToCart,
    rmCartItem,
    setCart,
    total: calcTotal(cart),
    items: nextItems,
  };
}
