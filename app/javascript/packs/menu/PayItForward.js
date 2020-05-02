import React, { useState } from "react";
import Quantity from "./Quantity";

function QuantityAdd({ quantity, onAdd, onQuantity, onCancel }) {
  return (
    <>
      <div className="row my-2">
        <div className="col col-md-auto">
          <div>
            Qty: <strong className="pr-3">{quantity}</strong>
          </div>
          <Quantity defaultQuantity={quantity} onChange={onQuantity} />
        </div>
      </div>
      <div>
        <button onClick={onAdd} className="btn btn-primary btn-sm mr-2">
          Add to cart
        </button>
        <button onClick={onCancel} className="btn btn-secondary btn-sm">
          Cancel
        </button>
      </div>
    </>
  );
}

export default function PayItForward({ description, onChange }) {
  const [willPay, setWillPay] = useState(false);
  const [wasAdded, setWasAdded] = useState(false);
  const [quantity, setQuantity] = useState(1);

  const handleAdd = () => {
    onChange({ quantity });
    setWasAdded(true);
    const reset = () => {
      setWasAdded(false);
      setWillPay(false);
      setQuantity(1);
    };

    setTimeout(reset, 1.5 * 1000);
  };

  if (wasAdded) {
    return <p className="text-success my-3">Added to cart!</p>;
  }

  if (willPay) {
    return (
      <QuantityAdd
        quantity={quantity}
        onQuantity={setQuantity}
        onAdd={handleAdd}
        onCancel={() => setWillPay(false)}
      />
    );
  }

  return (
    <>
      <div className="mb-2">
        <button
          type="button"
          className={`btn btn-success btn-sm mr-2`}
          onClick={() => setWillPay(true)}
        >
          Yes
        </button>
      </div>
      <div style={{ lineHeight: "normal" }}>
        <small>{description}</small>
      </div>
    </>
  );
}
