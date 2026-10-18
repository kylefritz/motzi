import React, { useState, useMemo } from "react";

import {
  useDeadlineContext,
  SettingsContext,
  useSettingsContext,
} from "./Contexts";
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
  const orderingClosed = useDeadlineContext().allClosed(menu);
  const parentSettings = useSettingsContext();

  // Override showCredits to false for holiday menus — show USD pricing
  const holidaySettings = { ...parentSettings, showCredits: false };

  // Ensure all items are available as marketplace items for card payment
  const marketplaceMenu = useMemo(
    () => ({
      ...menu,
      items: menu.items.map((item) => ({ ...item, marketplace: true })),
    }),
    [menu]
  );

  if (order && !isEditingOrder) {
    const handleEditOrder =
      menu.isCurrent && !orderingClosed ? () => setIsEditingOrder(true) : null;
    return (
      <SettingsContext.Provider value={holidaySettings}>
        <Order
          {...{
            user,
            order,
            menu,
            bundles,
            onEditOrder: handleEditOrder,
          }}
        />
      </SettingsContext.Provider>
    );
  }

  // passes the response on so a card needing 3D Secure can finish paying
  const handleSave = (o: MenuOrderRequest | MarketplaceOrderRequest) =>
    handleCreateOrder(o).then((result) => {
      setIsEditingOrder(false);
      return result;
    });

  // Holiday orders always require card payment — use Marketplace for all users
  return (
    <SettingsContext.Provider value={holidaySettings}>
      <Marketplace menu={marketplaceMenu} onCreateOrder={handleSave} />
    </SettingsContext.Provider>
  );
}
