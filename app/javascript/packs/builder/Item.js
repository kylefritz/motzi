import React from "react";
import { Card, CardActions, Link, IconButton } from "@material-ui/core";
import { makeStyles } from "@material-ui/core/styles";
import { Delete } from "@material-ui/icons";
import styled from "styled-components";
import { shortDay } from "./PickupDay";

export default function Item({
  onRemove: handleRemove,
  menuItemId,
  name,
  subscriber,
  marketplace,
  pickupDays,
}) {
  const classes = useStyles();

  return (
    <Card className={classes.root}>
      <Content>
        <Name>{name}</Name>

        <Smaller>
          {pickupDays.map(({ pickupAt }) => shortDay(pickupAt)).join(", ")}
        </Smaller>
      </Content>

      <CardActions>
        <IconButton aria-label="delete" color="primary" onClick={handleRemove}>
          <Delete />
        </IconButton>
        <Link
          href={`/admin/menu_items/${menuItemId}`}
          target="_blank"
          variant="body2"
        >
          edit
        </Link>

        {subscriber && <Subscriber title="Subscriber">S</Subscriber>}
        {marketplace && <Marketplace title="Marketplace">M</Marketplace>}
      </CardActions>
    </Card>
  );
}

const useStyles = makeStyles({
  root: {
    width: 225,
    marginBottom: 20,
    marginRight: 20,
  },
});

const Name = styled.div`
  font-size: 1rem;
  margin-bottom: 0.1rem;
`;

const Smaller = styled.div`
  font-size: 0.75rem;
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
