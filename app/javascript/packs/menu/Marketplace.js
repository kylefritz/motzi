import React, { useState } from "react";
import _ from "lodash";

import BakersNote from "./BakersNote";
import Cart, { cartTotal } from "./Cart";
import Deadline from "./Deadline";
import EmailName from "./EmailName";
import Items from "./Items";
import PayItForward from "./PayItForward";
import Payment from "../buy/Payment";
import useCart from "./useCart";

export default function Marketplace({ menu, onCreateOrder }) {
  const { cart, addToCart, rmCartItem } = useCart();

  const [submitting, setSubmitting] = useState(false);
  const [comments, setComments] = useState();
  const [emailName, setEmailName] = useState({});

  const totalPrice = cartTotal({ cart, menu });

  const handleCardToken = ({ token }) => {
    if (_.isEmpty(emailName.email)) {
      return alert("Enter email!");
    }

    console.log("handleCardToken", { token, totalPrice });
    setSubmitting(true);

    // send stripe token to rails to complete purchase
    onCreateOrder({
      ...emailName,
      comments,
      cart,
      price: totalPrice,
      token: token.id,
    }).then(() => setSubmitting(false));
  };

  const { name, bakersNote, items } = menu;
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

      <div className="mt-3">
        <EmailName onChange={setEmailName} />
      </div>

      <Payment
        price={totalPrice}
        stripeApiKey={gon.stripeApiKey}
        onCardToken={handleCardToken}
        submitting={submitting}
      />
    </>
  );
}
