import React, { useState } from "react";

import Item from "./Item";
import BakersNote from "./BakersNote";
import User from "./User";
import Cart from "./Cart";
import BuyCredits from "../buy/App";
import _ from "lodash";

export default function Menu({ menu, user, onRefreshUser, onCreateOrder }) {
  const [cart, setCart] = useState([]);
  const [feedback, setFeedback] = useState();
  const [specialRequests, setSpecialRequests] = useState([]);

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

  const handleCreateOrder = () => {
    // TODO: migrate read from state
    const { selectedItem, addOns, day } = this.state;

    if (_.isNil(selectedItem)) {
      alert("Select a bread!");
      return;
    }

    let order = {
      feedback,
      comments: specialRequests,
      items: [],
      uid: user.hashid,
      day,
    };

    order.items.push(selectedItem);

    Object.entries(addOns).forEach(([addOn, quantity]) => {
      _.times(quantity).forEach(() => order.items.push(addOn));
    });

    onCreateOrder(order);
  };

  const { name, bakersNote, items, isCurrent } = menu;

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
      <User user={user} onRefreshUser={onRefreshUser} />

      {/* if low, show nag to buy credits*/}
      {user && user.credits < 4 && <BuyCredits onComplete={onRefreshUser} />}

      <h2>{name}</h2>

      <BakersNote {...{ bakersNote }} />

      <h5>We'd love your feedback on last week's loaf.</h5>
      <div className="row mt-3 mb-5">
        <div className="col">
          <textarea
            className="form-control"
            placeholder="What did you think?"
            onChange={(e) => setFeedback(e.target.value)}
          />
        </div>
      </div>

      <h5>Items</h5>
      <div className="row mt-3">
        {items.map((i) => (
          <Item
            key={i.id}
            {...i}
            onChange={({ quantity, day }) => addToCart(i.id, quantity, day)}
          />
        ))}
      </div>

      <h5>Special Requests</h5>
      <div className="row mt-3 mb-5">
        <div className="col">
          <textarea
            placeholder="Special requests or concerns"
            onChange={(e) => setSpecialRequests(e.target.value)}
            className="form-control"
          />
        </div>
      </div>
      <Cart cart={cart} menu={menu} rmCartItem={rmCartItem} />
      <div className="row mt-3 mb-5">
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
            Submit Order
          </button>
        </div>
      </div>
      <User user={user} onRefreshUser={onRefreshUser} />
    </>
  );
}
