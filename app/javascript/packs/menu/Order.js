import React from "react";
import _ from "lodash";

import BakersNote from "./BakersNote";
import Subscription from "./Subscription";
import Cart from "./Cart";

export default function Order({
  menu,
  user,
  order,
  onRefreshUser,
  onEditOrder,
}) {
  const { name, deadlineDay } = menu;
  const {
    items: cart,
    skip,
    comments,
    stripeReceiptUrl,
    stripeChargeAmount,
  } = order;

  const isSubscriptionOrder = _.get(user, "subscriber");
  return (
    <>
      <h2 id="menu-name">{name}</h2>

      <h3 className="mt-5 mb-4">We've got your order!</h3>

      <Cart {...{ cart, menu, skip, stripeChargeAmount }} />
      {stripeReceiptUrl && (
        <p className="text-center my-2">
          <a href={stripeReceiptUrl} target="blank">
            View receipt
          </a>
        </p>
      )}
      <div className="ml-2 mt-3">
        <h6>Feedback, Comments & Special Requests</h6>
        <p>{comments || <em>none</em>}</p>
      </div>

      {onEditOrder && isSubscriptionOrder && (
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

      {isSubscriptionOrder && (
        <div className="mt-5">
          <Subscription {...{ user, onRefreshUser, deadlineDay }} />
        </div>
      )}
    </>
  );
}
