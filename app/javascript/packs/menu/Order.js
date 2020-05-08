import React from "react";
import _ from "lodash";

import BakersNote from "./BakersNote";
import User from "./User";
import Cart from "./Cart";

export default function ({ menu, user, order, onRefreshUser, onEditOrder }) {
  const { name, bakersNote } = menu;
  const { items: cart, skip } = order;

  return (
    <>
      <h2 className="mt-5 mb-4">We got your order!</h2>

      <Cart {...{ cart, menu, skip }} />

      {onEditOrder && (
        <button
          type="button"
          className="btn btn-outline-primary btn-sm mt-3"
          onClick={onEditOrder}
        >
          Edit Order
        </button>
      )}

      <User user={user} onRefreshUser={onRefreshUser} />

      <hr className="mb-5" />

      <h2 className="mt-3 mb-5">{name}</h2>
      <BakersNote {...{ bakersNote }} />
    </>
  );
}
