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
  const handleCheckout = ({ token }) => {
    if (_.isEmpty(account.email)) {
      return alert("Enter email!");
    }
    if (!/\S+@\S+\.\S+/.test(account.email)) {
      return alert("Invalid email");
    }

    console.log("handleCardToken", { token, price: totalPrice });
    setSubmitting(true);

    axios
      .post("/payment_intents", {
        ...account,
        price: totalPrice,
        comments,
        cart,
      })
      .then(({ data }) => {
        console.log("got from server data.checkoutUrl=", data.checkoutUrl);
        // setClientSecret(data.clientSecret);

        // TODO: redirect to checkoutUrl
      })
      .catch((error) => {
        console.error("Couldn't create payment intent", error.response);
        window.alert(`Couldn't create payment: ${error.message}`);
        Sentry.captureException(err);
      })
      .always(() => setSubmitting(false));
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

      {cart.length > 0 && (
        <>
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

          <CheckoutButton
            disabled={disabled}
            submitting={submitting}
            onClick={handleCheckout}
          />
        </>
      )}
    </>
  );
}

function CheckoutButton({ disabled, submitting, onClick }) {
  const text = "Proceed to Checkout";
  return (
    <button
      disabled={disabled || submitting}
      className="btn btn-primary btn-lg btn-block"
      style={buttonStyle}
      onClick={onClick}
      type="submit"
    >
      {submitting ? <Spinner /> : text}
    </button>
  );
}
const buttonStyle = {
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
};

function Spinner() {
  return (
    <>
      <span
        className="spinner-border spinner-border-sm mr-2"
        role="status"
        aria-hidden="true"
      />
      Loading...
    </>
  );
}
