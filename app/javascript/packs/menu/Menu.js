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

export default function Menu({
  menu,
  order,
  user,
  onRefreshUser,
  onCreateOrder,
}) {
  const [cart, setCart] = useState(_.get(order, "items", []));
  const [skip, setSkip] = useState(_.get(order, "skip", false));
  const [feedback, setFeedback] = useState(_.get(order, "feedback", null));
  const [comments, setComments] = useState(_.get(order, "comments", null));

  const addToCart = (itemId, quantity, day) => {
    console.log("addToCart", itemId, quantity, day);
    setCart([...cart, { itemId, quantity, day }]);
  };

  const rmCartItem = (itemId, quantity, day) => {
    const index = _.findIndex(
      cart,
      (ci) => ci.itemId === itemId && ci.quantity === quantity && ci.day === day
    );
    const nextCart = [...cart];
    nextCart.splice(index, 1);
    setCart(nextCart);
  };

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
  const { skip: skipItem, payItForward } = createMenuItemLookup(menu);

  if (user && user.credits < 1) {
    // time to buy credits!
    return (
      <>
        <User user={user} />
        <p className="my-2">
          We love baking yummy things for you but you're out of credits.
        </p>
        <BuyCredits onComplete={onRefreshUser} />
      </>
    );
  }

  return (
    <>
      <User {...{ user, onRefreshUser, deadlineDay }} />

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
          <div className="row mt-2">
            {items
              .filter(({ id }) => id !== skipItem.id && id !== payItForward.id)
              .map((i) => (
                <Item
                  key={i.id}
                  {...i}
                  onChange={({ quantity, day }) =>
                    addToCart(i.id, quantity, day)
                  }
                />
              ))}
          </div>

          <h5>Skip this week?</h5>
          <div className="row">
            <div className="col-6 mb-3">
              <div className="mb-2">
                <button
                  type="button"
                  className="btn btn-sm btn-dark"
                  onClick={handleSkip}
                >
                  Skip
                </button>
              </div>
              <div style={{ lineHeight: "normal" }}>
                <small>
                  {skipItem.description}{" "}
                  <em>Removes any selected items from order.</em>
                </small>
              </div>
            </div>
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
      )}

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
      <User user={user} onRefreshUser={onRefreshUser} />
    </>
  );
}
