import React, { useState } from "react";

import Quantity from "./Quantity";

function shortDay(day) {
  if (day == "Thursday") {
    return "Thurs";
  }
  return "Sat";
}

function DayButtons({ description, onSetDay }) {
  const days = [
    ["Thursday", "info"],
    ["Saturday", "warning"],
  ];
  return (
    <>
      <div className="my-2">
        {days.map(([day, btn]) => (
          <button
            key={day}
            type="button"
            className={`btn btn-${btn} btn-sm mr-2`}
            onClick={() => onSetDay(day)}
          >
            {shortDay(day)}
          </button>
        ))}
      </div>
      <div style={{ lineHeight: "normal" }}>
        <small>{description}</small>
      </div>
    </>
  );
}

function QuantityAdd({ quantity, onAdd, onQuantity, onCancel, day }) {
  return (
    <>
      <div className="row my-2">
        <div className="col col-md-auto">
          <div>
            Qty: <strong className="pr-3">{quantity}</strong>
          </div>
          <Quantity defaultQuantity={quantity} onChange={onQuantity} />
        </div>
        <div className="col col-md-auto">
          Day: <strong className="pr-3">{shortDay(day)}</strong>
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

export default function Item({
  name,
  description,
  image,
  onChange,
  defaultQuantity = 1,
}) {
  // TODO: make image square
  const [day, setDay] = useState(null);
  const [quantity, setQuantity] = useState(defaultQuantity);

  const handleAdd = () => onChange({ day, quantity });

  return (
    <div className="col-6 mb-5">
      <img src={image} className="img-fluid" style={{ objectFit: "contain" }} />
      <div>{name}</div>
      {day ? (
        <QuantityAdd
          quantity={quantity}
          onQuantity={setQuantity}
          onAdd={handleAdd}
          day={day}
          onCancel={() => setDay(null)}
        />
      ) : (
        <DayButtons description={description} onSetDay={setDay} />
      )}
    </div>
  );
}
