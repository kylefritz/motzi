import React, { useState } from "react";

import { getDeadlineContext } from "./Contexts";
import Menu from "./Menu";
import Marketplace from "./Marketplace";
import Order from "./Order";
import type {
  CreditBundle,
  Menu as MenuType,
  MenuOrder,
  MenuOrderRequest,
  MenuUser,
  MarketplaceOrderRequest,
} from "../../types/api";

type HolidayMenuTabProps = {
  bundles: CreditBundle[];
  handleCreateOrder: (
    order: MenuOrderRequest | MarketplaceOrderRequest
  ) => Promise<unknown>;
  menu: MenuType;
  order: MenuOrder | null;
  user: MenuUser | null;
};

export default function HolidayMenuTab({
  bundles,
  handleCreateOrder,
  menu,
  order,
  user,
}: HolidayMenuTabProps) {
  const [isEditingOrder, setIsEditingOrder] = useState(false);
  const orderingClosed = getDeadlineContext().allClosed(menu);

  if (order && !isEditingOrder) {
    const handleEditOrder =
      menu.isCurrent && !orderingClosed ? () => setIsEditingOrder(true) : null;
    return (
      <Order
        {...{
          user,
          order,
          menu,
          bundles,
          onEditOrder: handleEditOrder,
        }}
      />
    );
  }

  const handleSave = (o: MenuOrderRequest | MarketplaceOrderRequest) =>
    handleCreateOrder(o).then(() => setIsEditingOrder(false));

  if (!user) {
    return <Marketplace {...{ menu, onCreateOrder: handleSave }} />;
  }

  return (
    <Menu
      {...{
        user,
        order,
        menu,
        bundles,
        onCreateOrder: handleSave,
        isHoliday: true,
      }}
    />
  );
}
