import React, { useState } from "react";
import { shortDay } from "./PickupDay";

export default function Adder({ items, not: rawNot, onAdd, pickupDays }) {
  const [subscriber, setSubscriber] = useState(true);
  const [marketplace, setMarketplace] = useState(true);
  const [pickupDayIds, setPickupDayIds] = useState(pickupDays.map((d) => d.id));

  const togglePickupDay = (pickupDayId, shouldAdd) => {
    console.log("pickupDay", pickupDayId, shouldAdd);
    const set = new Set(pickupDayIds);
    if (shouldAdd) {
      set.add(pickupDayId);
    } else {
      set.delete(pickupDayId);
    }
    setPickupDayIds(set.entries());
  };

  const selectRef = React.createRef();
  const handleAdd = (e) => {
    e.preventDefault();
    const itemId = parseInt(selectRef.current.value);
    if (!itemId) {
      alert("Select an item");
      return;
    }
    onAdd({ itemId, subscriber, marketplace, day1, day2 });

    // reset form
    setSubscriber(true);
    setMarketplace(true);
    setDay1(true);
    setDay2(true);
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
        {pickupDays.map(({ id, pickupAt }) => (
          <label key={id} style={{ marginLeft: 20 }}>
            {shortDay(pickupAt)}
            <Checkbox
              checked={new Set(pickupDayIds).has(id)}
              onChange={(e) => togglePickupDay(id, e.target.checked)}
            />
          </label>
        ))}
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
