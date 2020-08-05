import React, { useState } from "react";
import _ from "lodash";

import BakersNote from "./BakersNote";
import BuyCredits from "../buy/App";
import Cart, { useCart } from "./Cart";
import Title from "./Title";
import Items from "./Items";
import PayItForward from "./PayItForward";
import SkipThisWeek from "./SkipThisWeek";
import Subscription from "./Subscription";
import { getDayContext } from "./Contexts";

export default function Menu({ menu, order, user, onCreateOrder }) {
  const { cart, addToCart, rmCartItem, setCart, total, items } = useCart({
    order,
    items: menu.items,
  });
  const [skip, setSkip] = useState(_.get(order, "skip", false));
  const [comments, setComments] = useState(_.get(order, "comments", null));

  const handleSkip = () => {
    setSkip(true);
    setCart([]);
  };

  const handleCreateOrder = () => {
    if (_.isEmpty(cart) && !skip) {
      alert("Make a selection!");
      return;
    }

    onCreateOrder({
      comments,
      cart,
      uid: user.hashid,
      skip,
    });
  };

  const { subscriberNote, isCurrent, payItForward } = menu;
  const { day2Closed: menuClosed } = getDayContext();
  if (user.credits < 1) {
    // Must buy credits!
    return (
      <>
        <Subscription user={user} showBuyMoreButton={false} />
        <p className="my-2 text-center">
          Buy credits then trade them for yummy things!
        </p>
        <BuyCredits user={user} />

        <h5 className="mt-5">Preview of current menu</h5>
        <Items marketplace items={menu.items} disabled={true} />
      </>
    );
  }

  const insufficientCredits = total.credits > user.credits;
  return (
    <>
      <Subscription user={user} />

      {/* if low, show nag to buy credits*/}
      {(user.credits < 4 || insufficientCredits) && <BuyCredits user={user} />}

      <Title menu={menu} />

      <BakersNote note={subscriberNote} />

      <h5>Menu</h5>
      {skip ? (
        <>
          <p>
            <strong>You'll skip this week.</strong>&nbsp;
            <a
              href="#"
              onClick={(e) => {
                e.preventDefault();
                setSkip(false);
              }}
              className="ml-1"
            >
              <small>I want to order</small>
            </a>
          </p>
        </>
      ) : (
        <>
          <Items items={items} onAddToCart={addToCart} />

          <SkipThisWeek onSkip={handleSkip} disabled={menuClosed} />
          {payItForward && (
            <PayItForward
              {...payItForward}
              onAddToCart={addToCart}
              disabled={menuClosed}
            />
          )}
        </>
      )}

      <h5>Feedback, Comments & Special Requests</h5>
      <div className="row mt-2 mb-3">
        <div className="col">
          <textarea
            style={{ minHeight: 120 }}
            placeholder="We'd love to hear your feedback on previous loaves or any comments/special requests you may have"
            defaultValue={comments}
            onChange={(e) => setComments(e.target.value)}
            className="form-control"
            disabled={menuClosed}
          />
        </div>
      </div>
      <Cart {...{ cart, menu, rmCartItem, skip }} />
      <div className="row mt-2 mb-3">
        <div className="col">
          <SubmitButton
            onClick={handleCreateOrder}
            status={{
              isCurrent,
              menuClosed,
              insufficientCredits,
              isEditing: !!order,
            }}
          />
        </div>
      </div>
    </>
  );
}

function buttonText({ isCurrent, menuClosed, insufficientCredits, isEditing }) {
  const no = (text, title) => ({ disabled: true, title, text });
  if (!isCurrent) {
    return no(
      "Old menu",
      "This is not the current menu; you cannot submit an order."
    );
  }
  if (menuClosed) {
    return no("Ordering closed", "Ordering for this menu is closed");
  }
  if (insufficientCredits) {
    return no(
      "Buy more credits :)",
      "You don't have enough credits to cover your cart."
    );
  }
  const text = isEditing ? "Update Order" : "Submit Order";
  return { disabled: false, title: null, text };
}

function SubmitButton({ onClick, status }) {
  const { disabled, title, text } = buttonText(status);
  return (
    <button
      {...{ onClick, disabled, title }}
      className="btn btn-primary btn-lg btn-block"
      type="submit"
    >
      {text}
    </button>
  );
}
