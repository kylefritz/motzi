import React, { useState, useRef } from "react";
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
  const regularTabRef = useRef<HTMLButtonElement>(null);
  const holidayTabRef = useRef<HTMLButtonElement>(null);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "ArrowRight" || e.key === "ArrowLeft") {
      e.preventDefault();
      setShowHoliday((prev) => {
        const next = !prev;
        if (next) {
          holidayTabRef.current?.focus();
        } else {
          regularTabRef.current?.focus();
        }
        return next;
      });
    }
  };

  return (
    <>
      <TabBar role="tablist" aria-label="menu selection" onKeyDown={handleKeyDown}>
        {regularMenu && (
          <TabButton
            ref={regularTabRef}
            role="tab"
            id="tab-regular"
            aria-selected={!showHoliday}
            aria-controls="panel-regular"
            tabIndex={!showHoliday ? 0 : -1}
            active={!showHoliday}
            onClick={() => setShowHoliday(false)}
          >
            {regularMenu.name}
          </TabButton>
        )}
        <TabButton
          ref={holidayTabRef}
          role="tab"
          id="tab-holiday"
          aria-selected={showHoliday}
          aria-controls="panel-holiday"
          tabIndex={showHoliday ? 0 : -1}
          active={showHoliday}
          onClick={() => setShowHoliday(true)}
        >
          <HolidayBadge aria-hidden="true">Holiday</HolidayBadge>
          {holidayMenu.name}
        </TabButton>
      </TabBar>

      {!showHoliday && regularMenu && (
        <div role="tabpanel" id="panel-regular" aria-labelledby="tab-regular">
          <Layout
            bundles={bundles}
            handleCreateOrder={handleCreateRegularOrder}
            isEditingOrder={isEditingOrder}
            menu={regularMenu}
            order={regularOrder}
            setIsEditingOrder={setIsEditingOrder}
            user={user}
          />
        </div>
      )}

      {showHoliday && (
        <div role="tabpanel" id="panel-holiday" aria-labelledby="tab-holiday">
          <HolidayMenuTab
            bundles={bundles}
            handleCreateOrder={handleCreateHolidayOrder}
            menu={holidayMenu}
            order={holidayOrder}
            user={user}
          />
        </div>
      )}
    </>
  );
}

const TabBar = styled.div`
  display: flex;
  gap: 8px;
  margin-bottom: 16px;
`;

const TabButton = styled.button<{ active: boolean }>`
  flex: 1;
  min-width: 0;
  padding: 10px 16px;
  background: ${({ active }) => (active ? "#352c63" : "transparent")};
  color: ${({ active }) => (active ? "white" : "#352c63")};
  border: 1.5px solid #352c63;
  border-radius: 4px;
  font-family: 'Raleway', sans-serif;
  font-size: 0.95rem;
  font-weight: 500;
  letter-spacing: 0.03em;
  cursor: pointer;
  transition: background 0.15s, color 0.15s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;

  &:hover {
    background: ${({ active }) =>
      active ? "#352c63" : "rgba(53, 44, 99, 0.08)"};
  }

  &:focus-visible {
    outline: 2px solid #352c63;
    outline-offset: 2px;
  }
`;

const HolidayBadge = styled.span`
  flex-shrink: 0;
  font-family: 'Oswald', sans-serif;
  font-size: 0.7rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  background: #d5482c;
  color: white;
  padding: 2px 6px;
  border-radius: 2px;
`;
