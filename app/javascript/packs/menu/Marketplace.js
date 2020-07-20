import React, { useState } from "react";
import _ from "lodash";

import BakersNote from "./BakersNote";
import Cart, { cartTotal } from "./Cart";
import Title from "./Title";
import EmailName from "./EmailName";
import Items from "./Items";
import PayItForward from "./PayItForward";
import Payment from "../buy/Payment";
import PayWhatYouCan from "../buy/PayWhatYouCan";
import useCart from "./useCart";
import { getDayContext } from "./Contexts";

export default function Marketplace({ menu, onCreateOrder }) {
  const { cart, addToCart, rmCartItem } = useCart();

  const [submitting, setSubmitting] = useState(false);
  const [comments, setComments] = useState();
  const [emailName, setEmailName] = useState({});

  const [price, setPrice] = useState(cartTotal({ cart, menu }));

  const handleCardToken = ({ token }) => {
    if (_.isEmpty(emailName.email)) {
      return alert("Enter email!");
    }

    console.log("handleCardToken", { token, price });
    setSubmitting(true);

    // send stripe token to rails to complete purchase
    onCreateOrder({
      ...emailName,
      comments,
      cart,
      price,
      token: token.id,
    }).then(() => setSubmitting(false));
  };

  const resetPrice = (nextCart) =>
    setPrice(cartTotal({ cart: nextCart, menu }));

  const handleAddToCart = (item) => {
    const nextCart = addToCart(item);
    resetPrice(nextCart);
  };

  const handleRemoveFromCart = (item) => {
    const nextCart = rmCartItem(item);
    resetPrice(nextCart);
  };

  const { menuNote, items } = menu;
  const { pastDay2Deadline: menuClosed } = getDayContext();
  return (
    <>
      <Title menu={menu} />

      <BakersNote note={menuNote} />

      <h5>Menu</h5>
      <Items
        marketplace
        items={items}
        onAddToCart={handleAddToCart}
        disabled={menuClosed}
      />
      <PayItForward
        {...menu.payItForward}
        onAddToCart={handleAddToCart}
        disabled={menuClosed}
      />

      <h5>Comments & Special Requests</h5>
      <div className="row mt-2 mb-3">
        <div className="col">
          <textarea
            placeholder="Comments & special requests"
            defaultValue={comments}
            onChange={(e) => setComments(e.target.value)}
            className="form-control"
            disabled={menuClosed}
          />
        </div>
      </div>

      <Cart {...{ cart, menu, rmCartItem: handleRemoveFromCart }} />

      <div className="mt-3">
        <EmailName onChange={setEmailName} disabled={menuClosed} />
      </div>
      <PayWhatYouCan
        price={price}
        onPricedChanged={setPrice}
        disabled={menuClosed}
      />
      <Payment
        price={price}
        stripeApiKey={gon.stripeApiKey}
        onCardToken={handleCardToken}
        submitting={submitting}
        disabled={menuClosed}
      />
    </>
  );
}
