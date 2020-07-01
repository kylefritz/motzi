import React, { useState } from "react";
import _ from "lodash";

import BakersNote from "./BakersNote";
import BuyCredits from "../buy/App";
import Cart from "./Cart";
import Deadline from "./Deadline";
import Items from "./Items";
import PayItForward from "./PayItForward";
import SkipThisWeek from "./SkipThisWeek";
import Subscription from "./Subscription";
import useCart from "./useCart";

export default function Menu({
  menu,
  order,
  user,
  onRefreshUser,
  onCreateOrder,
}) {
  const { cart, addToCart, rmCartItem, setCart } = useCart(order);

  const [skip, setSkip] = useState(_.get(order, "skip", false));
  const [feedback, setFeedback] = useState(_.get(order, "feedback", null));
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
      feedback,
      comments,
      cart,
      uid: user.hashid,
      skip,
    });
  };

  const { name, bakersNote, items, isCurrent, deadlineDay } = menu;

  if (user && user.credits < 1) {
    // time to buy credits!
    return (
      <>
        <Subscription {...{ user, deadlineDay }} />
        <p className="my-2">
          We love baking yummy things for you but you're out of credits.
        </p>
        <BuyCredits onComplete={onRefreshUser} />
      </>
    );
  }

  return (
    <>
      <Subscription {...{ user, onRefreshUser, deadlineDay }} />

      {/* if low, show nag to buy credits*/}
      {user && user.credits < 4 && <BuyCredits onComplete={onRefreshUser} />}

      <h2>{name}</h2>
      <Deadline menu={menu} />
      <BakersNote {...{ bakersNote }} />

      <h5>We'd love your feedback on last week's loaf.</h5>
      <div className="row mt-2 mb-3">
        <div className="col">
          <textarea
            className="form-control"
            placeholder="What did you think?"
            defaultValue={feedback}
            onChange={(e) => setFeedback(e.target.value)}
          />
        </div>
      </div>
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

          <SkipThisWeek {...menu.skip} onSkip={handleSkip} />
          <PayItForward {...menu.payItForward} onAddToCart={addToCart} />
        </>
      )}

      <h5>Comments & Special Requests</h5>
      <div className="row mt-2 mb-3">
        <div className="col">
          <textarea
            placeholder="Comments & special requests"
            defaultValue={comments}
            onChange={(e) => setComments(e.target.value)}
            className="form-control"
          />
        </div>
      </div>
      <Cart {...{ cart, menu, rmCartItem, skip }} />
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
            {order ? "Update Order" : "Submit Order"}
          </button>
        </div>
      </div>
      <Subscription {...{ user, onRefreshUser, deadlineDay }} />
    </>
  );
}
