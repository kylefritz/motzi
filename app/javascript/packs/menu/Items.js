import React, { useState } from "react";
import { get, isNumber } from "lodash";

import Price from "./Price";
import Quantity from "./Quantity";
import { getDayContext } from "./Contexts";

function shortDay(day) {
  switch (day) {
    case "Monday":
    case "Tuesday":
    case "Thursday":
    case "Friday":
    case "Sunday":
      return day.replace("day", "");
    case "Wednesday":
      return "Wed";
    case "Saturday":
      return "Sat";
  }
  return day;
}

export function DayButton({
  day,
  btn,
  isPastDeadline,
  remaining,
  onSetDay,
  orderingDeadlineText,
}) {
  if (remaining < 1 || isPastDeadline) {
    const [short, long, title] = isPastDeadline
      ? [`Closed`, `Ordering closed for ${shortDay(day)}`, orderingDeadlineText]
      : ["Sold Out", `${shortDay(day)} Sold Out`, undefined];

    return (
      <button
        type="button"
        className={`btn btn-outline-${btn} btn-sm mr-2`}
        disabled={true}
        title={title}
      >
        <span className="d-block d-md-none">{short}</span>
        <span className="d-none d-md-block">{long}</span>
      </button>
    );
  }

  return (
    <div key={day}>
      <button
        type="button"
        className={`btn btn-${btn} btn-sm mr-2`}
        onClick={() => onSetDay(day)}
      >
        <span className="d-block d-md-none">{shortDay(day)}</span>
        <span className="d-none d-md-block">{day}</span>
      </button>
      {isNumber(remaining) && remaining < 5 && (
        <div className="text-info text-center mt-1">
          <small>{remaining} left!</small>
        </div>
      )}
    </div>
  );
}

function DayButtons({
  description,
  onSetDay,
  day1: enableDay1,
  day2: enableDay2,
  remainingDay1,
  remainingDay2,
  showDay2 = true,
}) {
  const { day1, day1Closed, day2, day2Closed } = getDayContext();
  const days = [];
  if (enableDay1) {
    days.push({
      day: day1,
      btn: "secondary",
      isPastDeadline: day1Closed,
      remaining: remainingDay1,
    });
  }
  if (showDay2 && enableDay2) {
    days.push({
      day: day2,
      btn: "primary",
      isPastDeadline: day2Closed,
      remaining: remainingDay2,
    });
  }
  return (
    <>
      {onSetDay && (
        <div className="my-2" style={{ display: "flex" }}>
          {days.map((props) => (
            <DayButton key={props.day} onSetDay={onSetDay} {...props} />
          ))}
        </div>
      )}
      <div style={{ lineHeight: "normal" }}>
        <small>{description}</small>
      </div>
    </>
  );
}

function QuantityAdd({ quantity, onAdd, onQuantity, onCancel, day, max }) {
  return (
    <>
      <div>
        Pickup: <strong className="pr-3">{day}</strong>
      </div>
      <div>
        Qty: <strong className="pr-3">{quantity}</strong>
      </div>
      <Quantity defaultQuantity={quantity} onChange={onQuantity} max={max} />
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

function Ordering(props) {
  const [day, setDay] = useState(null);
  const [wasAdded, setWasAdded] = useState(false);
  const [quantity, setQuantity] = useState(1);
  const { day1 } = getDayContext();

  const { onChange } = props;

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
    const remainingAttr = day === day1 ? "remainingDay1" : "remainingDay2";
    const remainingQuantity = get(props, remainingAttr);

    return (
      <QuantityAdd
        quantity={quantity}
        onQuantity={setQuantity}
        onAdd={handleAdd}
        day={day}
        max={remainingQuantity}
        onCancel={() => setDay(null)}
      />
    );
  }

  return <DayButtons onSetDay={onChange && setDay} {...props} />;
}

export function Item(props) {
  const { price, credits, image, name } = props;
  return (
    <div className="col-6 mb-4">
      <img src={image} className="img-fluid" style={{ objectFit: "contain" }} />
      <div>{name}</div>
      <Price {...{ price, credits }} />
      <Ordering {...props} />
    </div>
  );
}

export default function Items({
  items,
  onAddToCart: handleAddToCart,
  showDay2 = true,
}) {
  return (
    <div className="row mt-2">
      {items.map((i) => (
        <Item
          key={i.id}
          {...i}
          showDay2={showDay2}
          onChange={
            handleAddToCart &&
            (({ quantity, day }) => handleAddToCart({ ...i, quantity, day }))
          }
        />
      ))}
    </div>
  );
}
