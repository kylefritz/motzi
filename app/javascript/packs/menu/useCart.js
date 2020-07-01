import React, { useState } from "react";
import _ from "lodash";

export default function useCart(order = null) {
  const [cart, setCart] = useState(_.get(order, "items", []));

  const addToCart = ({ id: itemId, price, quantity, day }) => {
    console.log("addToCart", itemId, quantity, day);
    const nextCart = [...cart, { itemId, price, quantity, day }];
    setCart(nextCart);
    return nextCart;
  };

  const rmCartItem = (itemId, quantity, day) => {
    const index = _.findIndex(
      cart,
      (ci) => ci.itemId === itemId && ci.quantity === quantity && ci.day === day
    );
    const nextCart = [...cart];
    nextCart.splice(index, 1);
    setCart(nextCart);
    return nextCart;
  };

  return { cart, addToCart, rmCartItem, setCart };
}
