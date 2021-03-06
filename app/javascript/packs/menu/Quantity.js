import React, { useState } from "react";
import { isInteger } from "lodash";

export default function Quantity({ defaultQuantity = 1, onChange, max }) {
  const [quantity, setQuantity] = useState(defaultQuantity);

  const handlePlus = () => {
    const newQuantity = quantity + 1;
    setQuantity(newQuantity);
    onChange(newQuantity);
  };
  const handleMinus = () => {
    const newQuantity = quantity - 1;
    setQuantity(newQuantity);
    onChange(newQuantity);
  };

  return (
    <>
      <div
        className="btn-group btn-group-sm"
        role="group"
        aria-label="Basic example"
      >
        <button
          type="button"
          className="btn btn-secondary"
          disabled={quantity <= 1}
          onClick={handleMinus}
        >
          -
        </button>
        <button
          type="button"
          className="btn btn-primary"
          disabled={isInteger(max) && quantity >= max}
          onClick={handlePlus}
        >
          +
        </button>
      </div>
    </>
  );
}
