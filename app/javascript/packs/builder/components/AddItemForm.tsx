import React, { useState } from "react";
import _ from "lodash";
import styled from "styled-components";
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
    <Form onSubmit={handleAdd}>
      <SelectRow>
        <select ref={selectRef}>
          {choices.map(({ id, name }) => (
            <option key={id} value={id}>
              {name}
            </option>
          ))}
        </select>
      </SelectRow>
      <OptionsRow>
        <label>
          Marketplace
          <CheckboxInput
            checked={marketplace}
            onChange={(e) => setMarketplace(e.target.checked)}
          />
        </label>
        <label>
          Subscriber
          <CheckboxInput
            checked={subscriber}
            onChange={(e) => setSubscriber(e.target.checked)}
          />
        </label>
        {pickupDays.map(({ id, pickupAt }) => {
          return (
            <label key={id}>
              {shortDay(pickupAt)}
              <CheckboxInput
                checked={new Set(pickupDayIds).has(id)}
                onChange={(e) => togglePickupDay(id, e.target.checked)}
              />
            </label>
          );
        })}
        <ActionsRow>
          <button type="submit">Add Item</button>
        </ActionsRow>
      </OptionsRow>
    </Form>
  );
}

const Form = styled.form`
  margin-top: 30px;
  margin-bottom: 20px;
`;

const SelectRow = styled.div`
  select {
    min-width: 240px;
  }
`;

const OptionsRow = styled.div`
  margin-top: 8px;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px 18px;

  label {
    display: inline-flex;
    align-items: center;
    gap: 6px;
  }
`;

const ActionsRow = styled.div`
  flex-basis: 100%;
  margin-top: 10px;
`;

const CheckboxInput = styled.input.attrs({ type: "checkbox" })`
  margin-left: 3px;
`;
