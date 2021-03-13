import React, { useState } from "react";
import {
  Card,
  CardActions,
  Link,
  IconButton,
  Checkbox,
} from "@material-ui/core";
import { makeStyles } from "@material-ui/core/styles";
import { Delete } from "@material-ui/icons";
import styled from "styled-components";
import { shortDay } from "./PickupDay";

export default function Item({
  onRemove: handleRemove,
  itemId,
  menuItemId,
  name,
  subscriber,
  marketplace,
  pickupDays,
  menuPickupDays,
  handleChangeMenuItemPickupDay,
  handleUpdateMenuItemPickupDay,
}) {
  const classes = useStyles();

  function handleCheck(pickupDayId, isAdd) {
    console.log("menuItemId", menuItemId, "pickupDayId", pickupDayId, "isAdd", isAdd); // prettier-ignore
    handleChangeMenuItemPickupDay({ menuItemId, pickupDayId }, isAdd);
  }

  return (
    <Card className={classes.root}>
      <Content>
        <Name>{name}</Name>

        <PickupDays
          {...{
            pickupDays,
            menuPickupDays,
            handleCheck,
            handleUpdateMenuItemPickupDay,
          }}
        />
      </Content>

      <CardActions>
        <IconButton
          aria-label="delete"
          color="primary"
          title="remove from menu"
          onClick={handleRemove}
        >
          <Delete />
        </IconButton>
        {subscriber && <Subscriber title="Subscriber">S</Subscriber>}
        {marketplace && <Marketplace title="Marketplace">M</Marketplace>}

        <Link href={`/admin/items/${itemId}`} target="_blank" variant="body2">
          edit item
        </Link>
      </CardActions>
    </Card>
  );
}

function PickupDays({
  pickupDays: itemPickupDays,
  menuPickupDays,
  handleCheck,
  handleUpdateMenuItemPickupDay,
}) {
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
            {itemPickupDay && (
              <Limit {...{ ...itemPickupDay, handleUpdateMenuItemPickupDay }} />
            )}
          </Row>
        );
      })}
    </Days>
  );
}

function Limit({ id, limit, handleUpdateMenuItemPickupDay }) {
  const [newLimit, setNewLimit] = useState(limit || ""); // TODO: set to "" instead of undefined to get rid of react uncontrolled component warning!
  const hasChanged = newLimit !== (limit || "");

  function handleChange(event) {
    const newValue = event.target.value;
    console.log("newValue", newValue);
    setNewLimit(newValue === "" ? "" : parseInt(newValue));
  }

  function handleSave(event) {
    event.preventDefault();
    handleUpdateMenuItemPickupDay({ id, limit: newLimit });
  }

  return (
    <label>
      limit:
      <SmallInput value={newLimit} onChange={handleChange} placeholder="none" />
      {hasChanged && <MiniBtn onClick={handleSave}>Save</MiniBtn>}
    </label>
  );
}

const useStyles = makeStyles({
  root: {
    width: 225,
    marginBottom: 20,
    marginRight: 20,
  },
});

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

const SmallInput = styled.input`
  margin-left: 3px;
  width: 40px;
  border: 1px dashed rgba(1, 1, 1, 0.2);
`;

const LabelText = styled.span`
  padding-left: 0.5rem;
  padding-right: 0.5rem;
`;

const Days = styled.div`
  margin-top: 0.5rem;
`;

const Name = styled.div`
  font-size: 1rem;
  margin-bottom: 0.1rem;
`;

const Content = styled.div`
  margin: 0.8rem;
  margin-bottom: 0;
`;

const SmallChip = styled.span`
  background: tomato;
  margin-right: 4px;
  padding: 3px;
  font-size: 11px;
  border-radius: 0.3rem;
`;

const Subscriber = styled(SmallChip)`
  background: greenyellow;
`;

const Marketplace = styled(SmallChip)`
  background: tomato;
`;
