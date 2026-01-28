import React from "react";
import styled from "styled-components";

import MenuItemCard from "./MenuItemCard";
import type { AdminMenuItem, AdminPickupDay } from "../../../types/api";

type MenuItemGridProps = {
  menuItems: AdminMenuItem[];
  pickupDays: AdminPickupDay[];
};

export default function MenuItemGrid({
  menuItems,
  pickupDays,
}: MenuItemGridProps) {
  if (menuItems.length === 0) {
    return (
      <p>
        <em>no items</em>
      </p>
    );
  }
  return (
    <Grid>
      {menuItems.map((i) => (
        <MenuItemCard key={i.menuItemId} {...i} menuPickupDays={pickupDays} />
      ))}
    </Grid>
  );
}

const Grid = styled.div`
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
`;
