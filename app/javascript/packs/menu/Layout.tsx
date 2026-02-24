import React from "react";

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

export type LayoutProps = {
  bundles: CreditBundle[];
  error?: string;
  handleCreateOrder: (
    order: MenuOrderRequest | MarketplaceOrderRequest
  ) => Promise<unknown>;
  isEditingOrder: boolean;
  menu: MenuType | null;
  order: MenuOrder | null;
  setIsEditingOrder: React.Dispatch<React.SetStateAction<boolean>>;
  user: MenuUser | null;
};

export default function Layout({
  bundles,
  error,
  handleCreateOrder,
  isEditingOrder,
  menu,
  order,
  setIsEditingOrder,
  user,
}: LayoutProps) {
  if (error) {
    return (
      <>
        <h2 className="mt-5">{error}</h2>
        <p className="text-center">Sorry. Maybe try again or try back later?</p>
      </>
    );
  }

  if (!menu) {
    return <h2 className="mt-5">loading...</h2>;
  }

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

  if (!user) {
    return <Marketplace {...{ menu, onCreateOrder: handleCreateOrder }} />;
  }

  return (
    <Menu
      {...{
        user,
        order,
        menu,
        bundles,
        onCreateOrder: handleCreateOrder,
      }}
    />
  );
}
