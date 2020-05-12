import React, { useState } from "react";

import Price from "./Price";
import Quantity from "./Quantity";

function shortDay(day) {
  if (day == "Thursday") {
    return "Thurs";
  }
  return "Sat";
}

function DayButtons({ description, onSetDay, showButtons }) {
  const days = [
    ["Thursday", "info"],
    ["Saturday", "warning"],
  ];
  return (
    <>
      {showButtons && (
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
      )}
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

function Ordering({ description, onChange }) {
  const [day, setDay] = useState(null);
  const [wasAdded, setWasAdded] = useState(false);
  const [quantity, setQuantity] = useState(1);

  const handleAdd = () => {
    onChange({ day, quantity });
    setWasAdded(true);
    const reset = () => {
      setWasAdded(false);
      setDay(null);
      setQuantity(1);
    };

    setTimeout(reset, 1.5 * 1000);
  };

  if (wasAdded) {
    return <p className="text-success my-3">Added to cart!</p>;
  }

  if (day) {
    return (
      <QuantityAdd
        quantity={quantity}
        onQuantity={setQuantity}
        onAdd={handleAdd}
        day={day}
        onCancel={() => setDay(null)}
      />
    );
  }

  return (
    <DayButtons
      description={description}
      onSetDay={setDay}
      showButtons={!!onChange}
    />
  );
}

function Item(props) {
  const { price, image, name } = props;
  return (
    <div className="col-6 mb-4">
      {/* TODO: make image square */}
      <img src={image} className="img-fluid" style={{ objectFit: "contain" }} />
      <div>{name}</div>
      <Price {...{ price }} />
      <Ordering {...props} />
    </div>
  );
}

export default function Items({ items, onAddToCart: handleAddToCart }) {
  return (
    <div className="row mt-2">
      {items.map((i) => (
        <Item
          key={i.id}
          {...i}
          onChange={({ quantity, day }) =>
            handleAddToCart({ ...i, quantity, day })
          }
        />
      ))}
    </div>
  );
}
