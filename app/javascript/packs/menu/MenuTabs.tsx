import React, { useState } from "react";
import styled from "styled-components";

import Layout from "./Layout";
import HolidayMenuTab from "./HolidayMenuTab";
import type {
  CreditBundle,
  Menu as MenuType,
  MenuOrder,
  MenuUser,
  MenuOrderRequest,
  MarketplaceOrderRequest,
} from "../../types/api";

type MenuTabsProps = {
  bundles: CreditBundle[];
  handleCreateHolidayOrder: (
    order: MenuOrderRequest | MarketplaceOrderRequest
  ) => Promise<unknown>;
  handleCreateRegularOrder: (
    order: MenuOrderRequest | MarketplaceOrderRequest
  ) => Promise<unknown>;
  holidayMenu: MenuType;
  holidayOrder: MenuOrder | null;
  isEditingOrder: boolean;
  regularMenu: MenuType | null;
  regularOrder: MenuOrder | null;
  setIsEditingOrder: React.Dispatch<React.SetStateAction<boolean>>;
  user: MenuUser | null;
};

export default function MenuTabs({
  bundles,
  handleCreateHolidayOrder,
  handleCreateRegularOrder,
  holidayMenu,
  holidayOrder,
  isEditingOrder,
  regularMenu,
  regularOrder,
  setIsEditingOrder,
  user,
}: MenuTabsProps) {
  const [showHoliday, setShowHoliday] = useState(!regularMenu);

  return (
    <>
      <TabBar role="tablist" aria-label="menu selection">
        {regularMenu && (
          <TabButton
            role="tab"
            aria-selected={!showHoliday}
            active={!showHoliday}
            onClick={() => setShowHoliday(false)}
          >
            {regularMenu.name}
          </TabButton>
        )}
        <TabButton
          role="tab"
          aria-selected={showHoliday}
          active={showHoliday}
          onClick={() => setShowHoliday(true)}
        >
          {!holidayOrder && <HolidayBadge>Holiday</HolidayBadge>}
          {holidayMenu.name}
        </TabButton>
      </TabBar>

      {!showHoliday && regularMenu && (
        <Layout
          bundles={bundles}
          handleCreateOrder={handleCreateRegularOrder}
          isEditingOrder={isEditingOrder}
          menu={regularMenu}
          order={regularOrder}
          setIsEditingOrder={setIsEditingOrder}
          user={user}
        />
      )}

      {showHoliday && (
        <HolidayMenuTab
          bundles={bundles}
          handleCreateOrder={handleCreateHolidayOrder}
          menu={holidayMenu}
          order={holidayOrder}
          user={user}
        />
      )}
    </>
  );
}

const TabBar = styled.div`
  display: flex;
  gap: 4px;
  margin-bottom: 4px;
`;

const TabButton = styled.button<{ active: boolean }>`
  flex: 1;
  padding: 10px 16px;
  background: ${({ active }) => (active ? "#352c63" : "transparent")};
  color: ${({ active }) => (active ? "white" : "#352c63")};
  border: 1.5px solid #352c63;
  border-radius: 3px;
  font-family: 'Raleway', sans-serif;
  font-size: 0.85rem;
  font-weight: 500;
  letter-spacing: 0.03em;
  cursor: pointer;
  transition: background 0.15s, color 0.15s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;

  &:hover {
    background: ${({ active }) =>
      active ? "#352c63" : "rgba(53, 44, 99, 0.08)"};
  }
`;

const HolidayBadge = styled.span`
  font-family: 'Oswald', sans-serif;
  font-size: 0.6rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  background: #d54a2c;
  color: white;
  padding: 2px 5px;
  border-radius: 2px;
`;
