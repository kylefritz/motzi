import React, { useState, useContext } from "react";

import Price from "./Price";
import Quantity from "./Quantity";
import { getDayContext } from "./Contexts";

function shortDay(day) {
  if (day == "Thursday") {
    return "Thurs";
  }
  return "Sat";
}

function DayButtons({
  description,
  onSetDay,
  showButtons,
  day1: availableDay1,
  day2: availableDay2,
}) {
  const {
    day1,
    day1Closed,
    day1DeadlineDay,
    day2,
    day2Closed,
    day2DeadlineDay,
  } = getDayContext();
  const days = [];
  if (availableDay1) {
    days.push([day1, "secondary", day1Closed, day1DeadlineDay]);
  }
  if (availableDay2) {
    days.push([day2, "primary", day2Closed, day2DeadlineDay]);
  }
  return (
    <>
      {showButtons && (
        <div className="my-2">
          {days.map(([day, btn, isPastDeadline, deadlineDay]) => (
            <button
              key={day}
              type="button"
              className={`btn btn-${btn} btn-sm mr-2`}
              onClick={() => onSetDay(day)}
              disabled={isPastDeadline}
              title={
                isPastDeadline
                  ? `Order by midnight ${deadlineDay} for ${day}.`
                  : undefined
              }
            >
              <span className="d-block d-md-none">{shortDay(day)}</span>
              <span className="d-none d-md-block">{day}</span>
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
      <div>
        Pickup: <strong className="pr-3">{day}</strong>
      </div>
      <div>
        Qty: <strong className="pr-3">{quantity}</strong>
      </div>
      <Quantity defaultQuantity={quantity} onChange={onQuantity} />
      <div className="mt-2">
        <button onClick={onAdd} className="btn btn-primary btn-sm mr-2">
          <span className="d-block d-md-none">Add</span>
          <span className="d-none d-md-block">Add to cart</span>
        </button>
        <button onClick={onCancel} className="btn btn-secondary btn-sm">
          Cancel
        </button>
      </div>
    </>
  );
}

function Ordering({ description, onChange, day1, day2 }) {
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
      onSetDay={setDay}
      showButtons={!!onChange}
      {...{ description, day1, day2 }}
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

export default function Items({
  items,
  onAddToCart: handleAddToCart,
  marketplace = false,
}) {
  if (marketplace) {
    items = items.filter(({ marketplace }) => marketplace);
  } else {
    // subscriber view
    items = items.filter(({ subscriber }) => subscriber);
  }
  return (
    <div className="row mt-2">
      {items.map((i) => (
        <Item
          key={i.id}
          {...i}
          onChange={
            handleAddToCart &&
            (({ quantity, day }) => handleAddToCart({ ...i, quantity, day }))
          }
        />
      ))}
    </div>
  );
}
