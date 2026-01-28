import React, { useRef, useState } from "react";
import { sortBy, isNumber } from "lodash";
import moment from "moment";

import Price from "./Price";
import Quantity from "./Quantity";
import { getDeadlineContext } from "./Contexts";
import type { MenuItem, MenuItemPickupDay } from "../../types/api";

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

type DayButtonProps = MenuItemPickupDay & {
  itemId: number;
  onSetDayId: (dayId: number) => void;
  orderingDeadlineText?: string;
};

export function DayButton({
  itemId,
  pickupAt,
  orderDeadlineAt,
  remaining,
  id: dayId,
  onSetDayId,
  orderingDeadlineText,
}: DayButtonProps) {
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
        data-testid={`pickup-day-${itemId}-${dayId}`}
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

type DayButtonsProps = Pick<MenuItem, "description" | "pickupDays"> & {
  itemId: number;
  onSetDayId?: (dayId: number) => void;
};

function DayButtons({
  description,
  onSetDayId,
  pickupDays,
  itemId,
}: DayButtonsProps) {
  return (
    <>
      {onSetDayId && (
        <div className="mt-2" style={{ display: "flex", flexWrap: "wrap" }}>
          {sortBy(pickupDays, (p) => p.pickupAt).map((props) => (
            <DayButton
              key={props.id}
              onSetDayId={onSetDayId}
              itemId={itemId}
              {...props}
            />
          ))}
        </div>
      )}
      <div style={{ lineHeight: "normal" }}>
        <small>{description}</small>
      </div>
    </>
  );
}

function QuantityAdd({
  quantity,
  onAdd,
  onQuantity,
  onCancel,
  day,
  max,
  itemId,
}: {
  quantity: number;
  onAdd: () => void;
  onQuantity: (next: number) => void;
  onCancel: () => void;
  day: string;
  max: number;
  itemId: number;
}) {
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
        <button
          onClick={onAdd}
          className="btn btn-primary btn-sm mr-2"
          data-testid={`add-to-cart-${itemId}`}
        >
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

type OrderingProps = MenuItem & {
  itemId: number;
  onChange?: (payload: { pickupDayId: number; quantity: number }) => void;
};

function Ordering(props: OrderingProps) {
  const [pickupDayId, setPickupDayId] = useState<number | null>(null);
  const [wasAdded, setWasAdded] = useState(false);
  const [quantity, setQuantity] = useState(1);
  const resetTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const { onChange, pickupDays, itemId } = props;

  const handleAdd = () => {
    if (!onChange || pickupDayId === null) {
      return;
    }
    onChange({ pickupDayId, quantity });
    setWasAdded(true);
    const reset = () => {
      setWasAdded(false);
      setPickupDayId(null);
      setQuantity(1);
    };

    const isTestEnv =
      typeof process !== "undefined" && process.env?.NODE_ENV === "test";
    if (!isTestEnv) {
      resetTimerRef.current = setTimeout(reset, 1.5 * 1000);
    }
  };

  React.useEffect(() => {
    return () => {
      if (resetTimerRef.current) {
        clearTimeout(resetTimerRef.current);
      }
    };
  }, []);

  if (wasAdded) {
    return <p className="text-success my-3">Added to cart!</p>;
  }

  if (pickupDayId) {
    const { remaining, pickupAt } = pickupDays.find(
      ({ id }) => pickupDayId === id
    ) as MenuItemPickupDay;
    const day = moment(pickupAt).format("dddd");

    return (
      <QuantityAdd
        quantity={quantity}
        onQuantity={setQuantity}
        onAdd={handleAdd}
        day={day}
        max={remaining}
        itemId={itemId}
        onCancel={() => setPickupDayId(null)}
      />
    );
  }

  return (
    <DayButtons
      onSetDayId={onChange ? setPickupDayId : undefined}
      itemId={itemId}
      {...props}
    />
  );
}

type ItemProps = MenuItem & {
  onChange?: (payload: { pickupDayId: number; quantity: number }) => void;
};

export function Item(props: ItemProps) {
  const { id, price, credits, image, name } = props;
  return (
    <div className="col-6 mb-4" data-testid={`item-${id}`}>
      <img src={image} className="img-fluid" style={{ objectFit: "contain" }} />
      <div>{name}</div>
      <Price {...{ price, credits }} />
      <Ordering {...props} itemId={id} />
    </div>
  );
}

type ItemsProps = {
  items: MenuItem[];
  onAddToCart?: (item: MenuItem & { quantity: number; pickupDayId: number }) => void;
  disabled?: boolean;
};

export default function Items({ items, onAddToCart: handleAddToCart }: ItemsProps) {
  return (
    <div className="row mt-2">
      {items.map((i) => (
        <Item
          key={i.id}
          {...i}
          onChange={
            handleAddToCart
              ? ({ quantity, pickupDayId }) =>
                  handleAddToCart({ ...i, quantity, pickupDayId })
              : undefined
          }
        />
      ))}
    </div>
  );
}
