import React, { useState } from "react";

export default function Quantity({ onChange }) {
  const [quantity, setQuantity] = useState(1);

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
    <div className="mb-4">
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
          disabled={quantity >= 3}
          onClick={handlePlus}
        >
          +
        </button>
      </div>
    </div>
  );
}
