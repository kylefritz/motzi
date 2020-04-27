import React from "react";
import _ from "lodash";
import createMenuItemLookup from "./createMenuItemLookup";

function DaysCart({ menu, cart, rmCartItem }) {
  const { menuItems } = createMenuItemLookup(menu);
  const lookupMenuItemName = (id) => _.get(menuItems[id], "name", id);

  return (
    <>
      <ul>
        {cart.map(({ itemId, quantity, day }, index) => (
          <li key={`${index}:${itemId}:${quantity}:${day}`} className="mb-2">
            {quantity > 1 && <strong className="mr-2">{quantity}x</strong>}
            {lookupMenuItemName(itemId)}
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

function Days({ menu, cart, rmCartItem, isSkipping }) {
  const thurs = cart.filter(({ day }) => day === "Thursday");
  const sat = cart.filter(({ day }) => day === "Saturday");
  const payItForwardId = createMenuItemLookup(menu).payItForward.id;
  const payItForward = cart.filter(({ itemId }) => itemId === payItForwardId);

  if (isSkipping) {
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

function Total({ cart }) {
  const total = _.sum(cart.map(({ quantity }) => quantity));
  return (
    <div>
      <h6>Total</h6>
      <div className="ml-4">
        {total} credit{total !== 1 && "s"}
      </div>
    </div>
  );
}

function Wrapped(props) {
  const { cart, isSkipping } = props;
  if (!cart.length && !isSkipping) {
    return <p>No items</p>;
  }
  return (
    <>
      <Days {...props} />
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
