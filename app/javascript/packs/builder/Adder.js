import React, { useState } from "react";
import _ from "lodash";

export default function Adder({ items, not, onAdd }) {
  const [subscriberOnly, setSubscriberOnly] = useState(false);
  const [marketplaceOnly, setMarketplaceOnly] = useState(false);
  const [day1, setDay1] = useState(true);
  const [day2, setDay2] = useState(true);

  const selectRef = React.createRef();
  const handleAdd = () => {
    const itemId = selectRef.current.value;
    if (!itemId) {
      alert("Select an item");
      return;
    }
    onAdd({ itemId, subscriberOnly, marketplaceOnly, day1, day2 });

    // reset form
    setSubscriberOnly(false);
    setMarketplaceOnly(false);
    setDay1(true);
    setDay2(true);
  };

  const choices = _.sortBy(items, ({ name }) => name).filter(
    (i) => !not.has(i.name)
  );
  return (
    <div>
      <h6>Add Item</h6>
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
          Subscriber only?
          <input
            style={{ marginLeft: 3 }}
            type="checkbox"
            checked={subscriberOnly}
            onChange={(e) => setSubscriberOnly(e.target.checked)}
          />
        </label>
        <label>
          Marketplace only?
          <input
            style={{ marginLeft: 3 }}
            type="checkbox"
            checked={marketplaceOnly}
            onChange={(e) => setMarketplaceOnly(e.target.checked)}
          />
        </label>
        <label style={{ marginLeft: 10 }}>
          Day 1
          <input
            style={{ marginLeft: 3 }}
            type="checkbox"
            checked={day1}
            onChange={(e) => setDay1(e.target.checked)}
          />
        </label>
        <label style={{ marginLeft: 10 }}>
          Day 2
          <input
            style={{ marginLeft: 3 }}
            type="checkbox"
            checked={day2}
            onChange={(e) => setDay2(e.target.checked)}
          />
        </label>
        <br />
        <button type="button" onClick={handleAdd}>
          Add Item
        </button>
      </div>
    </div>
  );
}
