import React, { useState } from "react";
import _ from "lodash";

export default function Adder({ items, not, onAdd }) {
  const [subscriber, setSubscriber] = useState(true);
  const [marketplace, setMarketplace] = useState(true);
  const [day1, setDay1] = useState(true);
  const [day2, setDay2] = useState(true);

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

  not = new Set(not);
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
          <input
            style={{ marginLeft: 3 }}
            type="checkbox"
            checked={marketplace}
            onChange={(e) => setMarketplace(e.target.checked)}
          />
        </label>
        <label style={{ marginLeft: 20 }}>
          Subscriber
          <input
            style={{ marginLeft: 3 }}
            type="checkbox"
            checked={subscriber}
            onChange={(e) => setSubscriber(e.target.checked)}
          />
        </label>
        <label style={{ marginLeft: 20 }}>
          Day 1
          <input
            style={{ marginLeft: 3 }}
            type="checkbox"
            checked={day1}
            onChange={(e) => setDay1(e.target.checked)}
          />
        </label>
        <label style={{ marginLeft: 20 }}>
          Day 2
          <input
            style={{ marginLeft: 3 }}
            type="checkbox"
            checked={day2}
            onChange={(e) => setDay2(e.target.checked)}
          />
        </label>
        <br />
        <br />
        <button type="submit">Add Item</button>
      </div>
    </form>
  );
}
