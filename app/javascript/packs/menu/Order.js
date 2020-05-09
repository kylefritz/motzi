import React from "react";
import _ from "lodash";

import BakersNote from "./BakersNote";
import User from "./User";
import Cart from "./Cart";

export default function Order({
  menu,
  user,
  order,
  onRefreshUser,
  onEditOrder,
}) {
  const { name, bakersNote } = menu;
  const { items: cart, skip, comments, feedback } = order;

  return (
    <>
      <h2 className="mt-5 mb-4">We got your order!</h2>

      <Cart {...{ cart, menu, skip }} />
      <div className="ml-2 mt-3">
        <h6>Feedback</h6>
        <p>{feedback || <em>none</em>}</p>

        <h6>Comments & Special Requests</h6>
        <p>{comments || <em>none</em>}</p>
      </div>

      {onEditOrder && (
        <div>
          <button
            type="button"
            className="btn btn-outline-primary btn-sm"
            onClick={onEditOrder}
          >
            Edit Order
          </button>
        </div>
      )}

      <User user={user} onRefreshUser={onRefreshUser} />

      <hr className="mb-5" />

      <h2 className="mt-3 mb-5">{name}</h2>
      <BakersNote {...{ bakersNote }} />
    </>
  );
}
