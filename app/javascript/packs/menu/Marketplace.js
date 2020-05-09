import React, { useState } from "react";
import _ from "lodash";

import Item from "./Item";
import BakersNote from "./BakersNote";
import User from "./User";
import Cart from "./Cart";
import Deadline from "./Deadline";
import BuyCredits from "../buy/App";
import PayItForward from "./PayItForward";
import createMenuItemLookup from "./createMenuItemLookup";
import useCart from "./useCart";

export default function Marketplace({ menu, order, user, onCreateOrder }) {
  const { cart, addToCart, rmCartItem } = useCart(order);

  const [comments, setComments] = useState(_.get(order, "comments", null));

  const handleCreateOrder = () => {
    if (_.isEmpty(cart)) {
      return alert("Make a selection!");
    }

    onCreateOrder({
      feedback,
      comments,
      cart,
      uid: user.hashid, // going to need email or something to tell person
    });
  };

  const { name, bakersNote, items, isCurrent, deadlineDay } = menu;
  const { payItForward } = createMenuItemLookup(menu);

  return (
    <>
      <User {...{ user, deadlineDay }} />

      <h2>{name}</h2>
      <Deadline menu={menu} />
      <BakersNote {...{ bakersNote }} />

      <h5>Menu</h5>
      <>
        <div className="row mt-2">
          {items
            .filter(({ id }) => id !== payItForward.id)
            .map((i) => (
              <Item
                key={i.id}
                {...i}
                showPrice
                onChange={({ quantity, day }) => addToCart(i.id, quantity, day)}
              />
            ))}
        </div>

        <h5>Pay it forward</h5>
        <div className="row">
          <div className="col-6 mb-3">
            <PayItForward
              description={payItForward.description}
              onChange={({ quantity, day }) => addToCart(-1, quantity, day)}
            />
          </div>
        </div>
      </>

      <h5>Comments & Special Requests</h5>
      <div className="row mt-2 mb-3">
        <div className="col">
          <textarea
            placeholder="Comments or special requests"
            defaultValue={comments}
            onChange={(e) => setComments(e.target.value)}
            className="form-control"
          />
        </div>
      </div>

      <Cart {...{ cart, menu, rmCartItem }} />

      <div className="row mt-2 mb-3">
        <div className="col">
          <button
            onClick={handleCreateOrder}
            disabled={!isCurrent}
            title={
              isCurrent
                ? null
                : "This is not the current menu; you cannot submit an order."
            }
            className="btn btn-primary btn-lg btn-block"
            type="submit"
          >
            {order ? "Update Order" : "Place Order"}
          </button>
        </div>
      </div>
    </>
  );
}
