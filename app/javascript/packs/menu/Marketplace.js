import React, { useState } from "react";
import _ from "lodash";

import BakersNote from "./BakersNote";
import Cart from "./Cart";
import Deadline from "./Deadline";
import Items from "./Items";
import PayItForward from "./PayItForward";
import useCart from "./useCart";

export default function Marketplace({ menu, order, onCreateOrder }) {
  const { cart, addToCart, rmCartItem } = useCart(order);

  const [comments, setComments] = useState(_.get(order, "comments", null));

  const handleCreateOrder = () => {
    if (_.isEmpty(cart)) {
      return alert("Make a selection!");
    }

    onCreateOrder({
      comments,
      cart,
      // uid: user.hashid, // going to need email or something to tell person
    });
  };

  const { name, bakersNote, items, isCurrent } = menu;

  return (
    <>
      <h2>{name}</h2>
      <Deadline menu={menu} />
      <BakersNote {...{ bakersNote }} />

      <h5>Menu</h5>
      <Items items={items} onAddToCart={addToCart} />
      <PayItForward {...menu.payItForward} onAddToCart={addToCart} />

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
