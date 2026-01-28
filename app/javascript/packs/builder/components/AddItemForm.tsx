import React, { useState } from "react";
import _ from "lodash";
import { shortDay } from "./PickupDaysPanel";
import { useApi } from "../Context";
import type { AdminItem, AdminPickupDay } from "../../../types/api";

type AddItemFormProps = {
  items: AdminItem[];
  not: string[];
  pickupDays: AdminPickupDay[];
};

export default function AddItemForm({
  items,
  not: rawNot,
  pickupDays,
}: AddItemFormProps) {
  const api = useApi();
  const [subscriber, setSubscriber] = useState(true);
  const [marketplace, setMarketplace] = useState(true);
  const [pickupDayIds, setPickupDayIds] = useState(pickupDays.map((d) => d.id));

  if (pickupDays.length === 0) {
    return <h3>Add a pickup day before adding items</h3>;
  }

  const togglePickupDay = (pickupDayId: number, shouldAdd: boolean) => {
    console.log("pickupDay", pickupDayId, "add", shouldAdd);
    const set = new Set(pickupDayIds);
    if (shouldAdd) {
      set.add(pickupDayId);
    } else {
      set.delete(pickupDayId);
    }
    setPickupDayIds([...set.keys()]);
  };

  const selectRef = React.createRef<HTMLSelectElement>();
  const handleAdd = (e: React.FormEvent) => {
    e.preventDefault();
    const itemId = parseInt(selectRef.current?.value || "", 10);
    if (!itemId) {
      alert("Select an item");
      return;
    }
    api.item.add({ itemId, subscriber, marketplace, pickupDayIds });
  };

  const not = new Set(rawNot);
  const choices = _.sortBy(items, ({ name }) => name)
    .filter((i) => !not.has(i.name))
    .filter((i) => i.name.length > 0);

  return (
    <form onSubmit={handleAdd} style={{ marginTop: 30, marginBottom: 20 }}>
      <div>
        <select ref={selectRef}>
          {choices.map(({ id, name }) => (
            <option key={id} value={id}>
              {name}
            </option>
          ))}
        </select>
      </div>
      <div style={{ marginTop: 5 }}>
        <label>
          Marketplace
          <Checkbox
            checked={marketplace}
            onChange={(e) => setMarketplace(e.target.checked)}
          />
        </label>
        <label style={{ marginLeft: 20 }}>
          Subscriber
          <Checkbox
            checked={subscriber}
            onChange={(e) => setSubscriber(e.target.checked)}
          />
        </label>
        {pickupDays.map(({ id, pickupAt }) => {
          return (
            <label key={id} style={{ marginLeft: 20 }}>
              {shortDay(pickupAt)}
              <Checkbox
                checked={new Set(pickupDayIds).has(id)}
                onChange={(e) => togglePickupDay(id, e.target.checked)}
              />
            </label>
          );
        })}
        <br />
        <br />
        <button type="submit">Add Item</button>
      </div>
    </form>
  );
}

function Checkbox({ onChange, checked }) {
  return (
    <input
      style={{ marginLeft: 3 }}
      type="checkbox"
      checked={checked}
      onChange={onChange}
    />
  );
}
