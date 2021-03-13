import React from "react";
import { Card, CardActions, Link, IconButton } from "@material-ui/core";
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
          }}
        />
      </Content>

      <CardActions>
        <IconButton aria-label="delete" color="primary" onClick={handleRemove}>
          <Delete />
        </IconButton>
        <Link href={`/admin/items/${itemId}`} target="_blank" variant="body2">
          edit
        </Link>

        {subscriber && <Subscriber title="Subscriber">S</Subscriber>}
        {marketplace && <Marketplace title="Marketplace">M</Marketplace>}
      </CardActions>
    </Card>
  );
}

function PickupDays({
  pickupDays: itemPickupDays,
  menuPickupDays,
  handleCheck,
}) {
  return (
    <Days>
      {menuPickupDays.map((menuPickupDay) => {
        const itemPickupDay = itemPickupDays.find(
          ({ pickupAt }) => pickupAt === menuPickupDay.pickupAt
        );
        const pickupEnabled = !!itemPickupDay;

        return (
          <div key={menuPickupDay.id}>
            <label>
              <input
                type="checkbox"
                onChange={() => handleCheck(menuPickupDay.id, !pickupEnabled)}
                checked={pickupEnabled}
              />
              <LabelText>{shortDay(menuPickupDay.pickupAt)}</LabelText>
            </label>

            {pickupEnabled && (
              <a href={`/admin/menu_item_pickup_days/${itemPickupDay.id}/edit`}>
                {itemPickupDay.limit === undefined
                  ? "no limit"
                  : `limit: ${itemPickupDay.limit}`}
              </a>
            )}
          </div>
        );
      })}
    </Days>
  );
}

const useStyles = makeStyles({
  root: {
    width: 225,
    marginBottom: 20,
    marginRight: 20,
  },
});

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
