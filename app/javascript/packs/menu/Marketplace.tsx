import React, { useState } from "react";
import _ from "lodash";

import BakersNote from "./BakersNote";
import Cart, { useCart } from "./Cart";
import Title from "./Title";
import Account from "./Account";
import Items from "./Items";
import PayItForward from "./PayItForward";
import Payment from "../buy/Payment";
import { applyTip } from "../buy/Tip";
import PayWhatYouCan from "../buy/PayWhatYouCan";
import { getDeadlineContext } from "./Contexts";

export default function Marketplace({ menu, onCreateOrder }) {
  const {
    cart,
    addToCart,
    rmCartItem,
    total,
    marketplaceItems,
    payItForward,
  } = useCart({
    items: menu.items,
  });
  const [submitting, setSubmitting] = useState(false);
  const [comments, setComments] = useState();
  const [account, setAccount] = useState({});
  const [price, setPrice] = useState(total.price);
  const [tip, setTip] = useState();

  const totalPrice = applyTip(price, tip);
  const handleCardToken = ({ token }) => {
    if (_.isEmpty(account.email)) {
      return alert("Enter email!");
    }
    if (!/\S+@\S+\.\S+/.test(account.email)) {
      return alert("Invalid email");
    }

    console.log("handleCardToken", { token, price: totalPrice });
    setSubmitting(true);

    // send stripe token to rails to complete purchase
    onCreateOrder({
      ...account,
      comments,
      cart,
      price: totalPrice,
      token: token.id,
    }).then(() => setSubmitting(false));
  };

  const handleAddToCart = (item) => {
    const newCartPrice = addToCart(item);
    setPrice(newCartPrice);
  };

  const handleRemoveFromCart = (item) => {
    const newCartPrice = rmCartItem(item);
    setPrice(newCartPrice);
  };

  if (!marketplaceItems.length) {
    console.warn("marketplace has no items", marketplaceItems);
    return null;
  }

  const { menuNote, enablePayWhatYouCan } = menu;
  const menuClosed = getDeadlineContext().allClosed(menu);
  const disabled = menuClosed || !onCreateOrder;
  const stripeApiKey = window.gon?.stripeApiKey;
  return (
    <>
      <Title menu={menu} />

      <BakersNote note={menuNote} />

      <h5>Menu</h5>
      <Items
        items={marketplaceItems}
        onAddToCart={handleAddToCart}
        disabled={disabled}
        showDay2={menu.showDay2}
      />
      {payItForward && (
        <PayItForward
          {...payItForward}
          onAddToCart={handleAddToCart}
          disabled={disabled}
        />
      )}

      <h5>Comments & Special Requests</h5>
      <div className="row mt-2 mb-3">
        <div className="col">
          <textarea
            placeholder="Comments & special requests"
            defaultValue={comments}
            onChange={(e) => setComments(e.target.value)}
            className="form-control"
            disabled={disabled}
          />
        </div>
      </div>

      <Cart {...{ cart, menu, rmCartItem: handleRemoveFromCart }} />

      <div className="mt-3">
        <Account onChange={setAccount} disabled={disabled} />
      </div>
      {enablePayWhatYouCan ? (
        <PayWhatYouCan
          price={price}
          onPricedChanged={setPrice}
          disabled={disabled}
          tip={tip}
          onTip={setTip}
        />
      ) : (
        <br />
      )}
      <Payment
        price={_.isEmpty(cart) ? null : totalPrice}
        stripeApiKey={stripeApiKey}
        onCardToken={handleCardToken}
        submitting={submitting}
        disabled={disabled}
      />
    </>
  );
}
