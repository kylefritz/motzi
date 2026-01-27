import React, { useState } from "react";
import { Card, Icon, IconButton } from "@material-ui/core";
import { Delete } from "@material-ui/icons";
import styled from "styled-components";
import { shortDay } from "./PickupDay";
import { useApi } from "./Context";
import { isNil } from "lodash";

export default function Item({
  itemId,
  menuItemId,
  name,
  subscriber,
  marketplace,
  sortOrder,
  pickupDays,
  menuPickupDays,
}) {
  const api = useApi();
  function handleChangeMenuType(menuType, enabled) {
    api.menuItem.update(menuItemId, { [menuType]: enabled });
  }
  function handleSortOrderChanged(sortOrder) {
    api.menuItem.update(menuItemId, { sortOrder });
  }

  return (
    <CardContent>
      <Header>
        <Name>
          <a href={`/admin/items/${itemId}`} target="_blank">
            {name}
          </a>
        </Name>
        <RightButton
          aria-label="delete"
          color="primary"
          title="remove from menu"
          onClick={() => api.item.remove(itemId)}
        >
          <Delete />
        </RightButton>
      </Header>

      <SortOrder sortOrder={sortOrder} onChange={handleSortOrderChanged} />

      <Sub>Pickup Days</Sub>
      <PickupDays
        {...{
          menuItemId,
          pickupDays,
          menuPickupDays,
        }}
      />

      <Sub>Menu Type</Sub>
      <MenuType
        name="Subscriber"
        enabled={subscriber}
        onChange={(enable) => handleChangeMenuType("subscriber", enable)}
      />
      <MenuType
        name="Marketplace"
        enabled={marketplace}
        onChange={(enable) => handleChangeMenuType("marketplace", enable)}
      />
    </CardContent>
  );
}

function MenuType({ name, enabled, onChange: handleChange }) {
  return (
    <Row>
      <label>
        <input
          type="checkbox"
          onChange={() => handleChange(!enabled)}
          checked={enabled}
        />
        <LabelText>{name}</LabelText>
      </label>
    </Row>
  );
}

function SortOrder({ sortOrder, onChange: handleChange }) {
  function handleClear(event) {
    event.preventDefault();
    handleChange(null);
  }
  return (
    <Row>
      <label>
        <LeftLabelText>Sort Order</LeftLabelText>
        <SmallInput
          type="number"
          value={sortOrder}
          onChange={(event) => handleChange(event.target.valueAsNumber)}
          placeholder="none"
        />
        {!isNil(sortOrder) && (
          <XBtn href="#" onClick={handleClear}>
            x
          </XBtn>
        )}
      </label>
    </Row>
  );
}

function PickupDays({
  menuItemId,
  pickupDays: itemPickupDays,
  menuPickupDays,
}) {
  const api = useApi();

  function handleCheck(pickupDayId, isAdd) {
    console.log("menuItemId", menuItemId, "pickupDayId", pickupDayId, "isAdd", isAdd); // prettier-ignore
    const action = isAdd
      ? api.menuItemPickupDay.add
      : api.menuItemPickupDay.remove;
    action({ menuItemId, pickupDayId });
  }

  return (
    <Days>
      {menuPickupDays.map((menuPickupDay) => {
        const itemPickupDay = itemPickupDays.find(
          ({ pickupAt }) => pickupAt === menuPickupDay.pickupAt
        );
        const pickupEnabled = !!itemPickupDay;

        return (
          <Row key={menuPickupDay.id}>
            <CheckboxLabel>
              <input
                type="checkbox"
                onChange={() => handleCheck(menuPickupDay.id, !pickupEnabled)}
                checked={pickupEnabled}
              />
              <LabelText>{shortDay(menuPickupDay.pickupAt)}</LabelText>
            </CheckboxLabel>
            {itemPickupDay && <Limit {...{ ...itemPickupDay }} />}
          </Row>
        );
      })}
    </Days>
  );
}

function Limit({ id, limit }) {
  const api = useApi();

  const [newLimit, setNewLimit] = useState(limit || "");
  const hasChanged = newLimit !== (limit || "");

  function handleChange(event) {
    const newValue = event.target.value;
    console.log("newValue", newValue);
    setNewLimit(newValue === "" ? "" : parseInt(newValue));
  }

  function handleSave(event) {
    event.preventDefault();
    api.menuItemPickupDay.updateLimit({ id, limit: newLimit });
  }

  return (
    <label>
      limit:
      <SmallInput value={newLimit} onChange={handleChange} placeholder="none" />
      {hasChanged && <MiniBtn onClick={handleSave}>Save</MiniBtn>}
    </label>
  );
}

const RightButton = styled(IconButton)`
  margin-top: -10px;
  margin-right: -10px;
`;

const Sub = styled.h6`
  margin-top: 0;
  margin-bottom: 0.5rem;
`;

const MiniBtn = styled.button`
  margin-left: 3px;
  padding: 2px;
  font-size: 8px;
  background: deepskyblue;
`;

const CheckboxLabel = styled.label`
  width: 75px;
`;

const Row = styled.div`
  display: flex;
  margin-bottom: 12px;
`;

const Header = styled.div`
  display: flex;
  justify-content: space-between;
`;

const SmallInput = styled.input`
  margin-left: 3px;
  width: 40px;
  border: 1px dashed rgba(1, 1, 1, 0.2);
`;

const LeftLabelText = styled.span`
  padding-right: 0.5rem;
`;

const LabelText = styled.span`
  padding-left: 0.5rem;
  padding-right: 0.5rem;
`;

const XBtn = styled.a`
  padding-left: 0.5rem;
  font-weight: bold;
`;

const Days = styled.div`
  margin-top: 0.5rem;
`;

const Name = styled.div`
  font-size: 1rem;
  margin-bottom: 0.1rem;
`;

const CardContent = styled(Card)`
  padding: 0.8rem;
  width: 225px;
  margin-bottom: 20px;
  margin-right: 20px;
`;
