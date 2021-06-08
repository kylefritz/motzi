import React, { useState } from "react";
import { sortBy, isNumber } from "lodash";
import moment from "moment";

import Price from "./Price";
import Quantity from "./Quantity";
import { getDeadlineContext } from "./Contexts";

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
  pickupAt,
  orderDeadlineAt,
  remaining,
  id: dayId,
  onSetDayId,
  orderingDeadlineText,
}) {
  const day = moment(pickupAt).format("dddd");
  const isPastDeadline = getDeadlineContext().isClosed(orderDeadlineAt);

  if (remaining < 1 || isPastDeadline) {
    const [short, long, title] = isPastDeadline
      ? [`Closed`, `Ordering closed for ${shortDay(day)}`, orderingDeadlineText]
      : ["Sold Out", `${shortDay(day)} Sold Out`, undefined];

    return (
      <button
        type="button"
        className="btn btn-outline-primary btn-sm mr-2 mb-2"
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
        className="btn btn-primary btn-sm mr-2 mb-2"
        onClick={() => onSetDayId(dayId)}
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

function DayButtons({ description, onSetDayId, pickupDays }) {
  return (
    <>
      {onSetDayId && (
        <div className="mt-2" style={{ display: "flex", flexWrap: "wrap" }}>
          {sortBy(pickupDays, (p) => p.pickupAt).map((props) => (
            <DayButton key={props.id} onSetDayId={onSetDayId} {...props} />
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
  const [pickupDayId, setPickupDayId] = useState(null);
  const [wasAdded, setWasAdded] = useState(false);
  const [quantity, setQuantity] = useState(1);

  const { onChange, pickupDays } = props;

  const handleAdd = () => {
    onChange({ pickupDayId, quantity });
    setWasAdded(true);
    const reset = () => {
      setWasAdded(false);
      setPickupDayId(null);
      setQuantity(1);
    };

    setTimeout(reset, 1.5 * 1000);
  };

  if (wasAdded) {
    return <p className="text-success my-3">Added to cart!</p>;
  }

  if (pickupDayId) {
    const { remaining, pickupAt } = pickupDays.find(
      ({ id }) => pickupDayId === id
    );
    const day = moment(pickupAt).format("dddd");

    return (
      <QuantityAdd
        quantity={quantity}
        onQuantity={setQuantity}
        onAdd={handleAdd}
        day={day}
        max={remaining}
        onCancel={() => setPickupDayId(null)}
      />
    );
  }

  return <DayButtons onSetDayId={onChange && setPickupDayId} {...props} />;
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

export default function Items({ items, onAddToCart: handleAddToCart }) {
  return (
    <div className="row mt-2">
      {items.map((i) => (
        <Item
          key={i.id}
          {...i}
          onChange={
            handleAddToCart &&
            (({ quantity, pickupDayId }) =>
              handleAddToCart({ ...i, quantity, pickupDayId }))
          }
        />
      ))}
    </div>
  );
}
