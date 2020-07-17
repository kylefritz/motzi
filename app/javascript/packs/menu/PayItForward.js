import React, { useState } from "react";

import Price from "./Price";

export default function PayItForward({
  id = -1,
  name = "Pay it forward loaf",
  description = "Wild times out there. Support some else in need.",
  price = 5,
  onAddToCart: addToCart,
}) {
  const [wasAdded, setWasAdded] = useState(false);

  const handleAdd = () => {
    addToCart({ id, price, quantity: 1 });
    setWasAdded(true);
    setTimeout(() => setWasAdded(false), 1.5 * 1000);
  };

  if (wasAdded) {
    return <p className="text-success my-3">You're amazing! Thanks!</p>;
  }

  return (
    <>
      <h5>{name}</h5>
      <div className="row">
        <div className="col-6 mb-3">
          <div className="mb-2">
            <button
              type="button"
              className={`btn btn-secondary btn-sm mr-2`}
              onClick={handleAdd}
            >
              Donate Now
            </button>
          </div>
          <Price {...{ price }} />
          <div style={{ lineHeight: "normal" }}>
            <small>{description}</small>
          </div>
        </div>
      </div>
    </>
  );
}
